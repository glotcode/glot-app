use crate::common::keyboard_shortcut::KeyboardShortcut;
use crate::util::user_agent::UserAgent;
use crate::view::modal;
use itertools::Itertools;
use maud::html;
use poly::browser::dom_id::DomId;
use poly::browser::effect;
use poly::browser::effect::dom;
use poly::browser::effect::Effect;
use poly::browser::keyboard::Key;
use poly::browser::selector::Selector;
use poly::browser::subscription;
use poly::browser::subscription::event_listener;
use poly::browser::subscription::event_listener::ModifierKey;
use poly::browser::subscription::Subscription;
use poly::browser::value::Capture;
use serde::{Deserialize, Serialize};
use std::{fmt::Display, hash::Hash};

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub enum State<EntryId> {
    #[default]
    Closed,
    Open(Model<EntryId>),
}

impl<EntryId> State<EntryId> {
    pub fn open<ParentMsg, AppEffect>(&mut self) -> Effect<ParentMsg, AppEffect> {
        *self = State::Open(Model::default());
        dom::focus_element(Id::QueryInput)
    }
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model<EntryId> {
    query: String,
    matching_entries: Vec<Entry<EntryId>>,
    selected_index: Option<usize>,
}

impl<EntryId> Default for Model<EntryId> {
    fn default() -> Self {
        Self {
            query: String::new(),
            matching_entries: vec![],
            selected_index: None,
        }
    }
}

#[derive(Clone, Serialize, Deserialize)]
pub enum Msg {
    QueryChanged(Capture<String>),
    OpenModal,
    CloseModal,
    QuickActionSelected(Capture<String>),
    FormSubmitted,
    SelectNext,
    SelectPrevious,
}

#[derive(strum_macros::Display, poly_macro::DomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
    QueryForm,
    QueryInput,
    SearchModalClose,
    SearchModalBackdrop,
}

pub fn subscriptions<ToParentMsg, ParentMsg, AppEffect, EntryId>(
    user_agent: &UserAgent,
    state: &State<EntryId>,
    to_parent_msg: ToParentMsg,
) -> Subscription<ParentMsg, AppEffect>
where
    ParentMsg: Clone,
    ToParentMsg: Fn(Msg) -> ParentMsg,
{
    match state {
        State::Open(_) => {
            let modal_config = modal::Config {
                backdrop_id: Id::SearchModalBackdrop,
                close_button_id: Id::SearchModalClose,
            };

            subscription::batch(vec![
                event_listener::on_input(Id::QueryInput, |captured| {
                    to_parent_msg(Msg::QueryChanged(captured))
                }),
                event_listener::on_keyup(Key::Escape, to_parent_msg(Msg::CloseModal)),
                event_listener::on_click_selector_closest(
                    Selector::data("quick-action"),
                    dom::get_target_data_string_value("quick-action"),
                    |captured| to_parent_msg(Msg::QuickActionSelected(captured)),
                ),
                event_listener::on_submit(Id::QueryForm, to_parent_msg(Msg::FormSubmitted)),
                event_listener::on_keydown(
                    Key::Key("ArrowUp".to_string()),
                    ModifierKey::None,
                    to_parent_msg(Msg::SelectPrevious),
                ),
                event_listener::on_keydown(
                    Key::Key("ArrowDown".to_string()),
                    ModifierKey::None,
                    to_parent_msg(Msg::SelectNext),
                ),
                modal::subscriptions(&modal_config, to_parent_msg(Msg::CloseModal)),
            ])
        }

        State::Closed => {
            let key_combo = KeyboardShortcut::OpenQuickSearch.key_combo(user_agent);

            event_listener::on_keydown(
                key_combo.key,
                key_combo.modifier,
                to_parent_msg(Msg::OpenModal),
            )
        }
    }
}

pub struct UpdateData<ParentMsg, AppEffect, EntryId> {
    pub effect: Effect<ParentMsg, AppEffect>,
    pub selected_entry: Option<EntryId>,
}

impl<ParentMsg, AppEffect, EntryId> UpdateData<ParentMsg, AppEffect, EntryId> {
    fn none() -> Self {
        Self {
            effect: effect::none(),
            selected_entry: None,
        }
    }
}

pub fn update<ToParentMsg, ParentMsg, AppEffect, EntryId>(
    msg: &Msg,
    state: &mut State<EntryId>,
    entries: Vec<Entry<EntryId>>,
    _to_parent_msg: ToParentMsg,
) -> Result<UpdateData<ParentMsg, AppEffect, EntryId>, String>
where
    ToParentMsg: Fn(Msg) -> ParentMsg,
    EntryId: Clone + Eq + PartialEq + Hash + Display + EntryExtra,
{
    match msg {
        Msg::QueryChanged(captured) => {
            if let State::Open(model) = state {
                model.query = captured.value();
                model.matching_entries = find_entries(&model.query, entries);

                Ok(UpdateData {
                    effect: effect::none(),
                    selected_entry: None,
                })
            } else {
                Ok(UpdateData::none())
            }
        }

        Msg::OpenModal => {
            *state = State::Open(Model::default());

            Ok(UpdateData {
                effect: dom::focus_element(Id::QueryInput),
                selected_entry: None,
            })
        }

        Msg::CloseModal => {
            *state = State::default();
            Ok(UpdateData::none())
        }

        Msg::QuickActionSelected(captured) => {
            let action_id = captured.value();
            let entry = entries
                .iter()
                .find(|entry| entry.0.to_string() == action_id);

            if let Some(entry) = entry {
                *state = State::default();

                Ok(UpdateData {
                    effect: effect::none(),
                    selected_entry: Some(entry.0.clone()),
                })
            } else {
                Ok(UpdateData::none())
            }
        }

        Msg::FormSubmitted => {
            if let State::Open(model) = state {
                let entries = model.matching_entries.clone();

                let selected_entry = if let Some(index) = model.selected_index {
                    entries.get(index)
                } else {
                    entries.first()
                };

                if let Some(entry) = selected_entry {
                    *state = State::default();

                    Ok(UpdateData {
                        effect: effect::none(),
                        selected_entry: Some(entry.0.clone()),
                    })
                } else {
                    Ok(UpdateData::none())
                }
            } else {
                Ok(UpdateData::none())
            }
        }

        Msg::SelectNext => {
            if let State::Open(model) = state {
                let new_index = if let Some(current_index) = model.selected_index {
                    let entry_count = model.matching_entries.len();
                    (current_index + 1) % entry_count
                } else {
                    0
                };

                model.selected_index = Some(new_index);
            }

            Ok(UpdateData::none())
        }

        Msg::SelectPrevious => {
            if let State::Open(model) = state {
                let current_index = model.selected_index.unwrap_or_default();
                let entry_count = model.matching_entries.len();
                let new_index = if current_index == 0 {
                    entry_count - 1
                } else {
                    current_index - 1
                };

                model.selected_index = Some(new_index);
            }

            Ok(UpdateData::none())
        }
    }
}

pub fn view<EntryId>(user_agent: &UserAgent, state: &State<EntryId>) -> maud::Markup
where
    EntryId: Display + EntryExtra,
{
    if let State::Open(model) = state {
        modal::view_barebones(
            view_search_modal(user_agent, model),
            &modal::Config {
                backdrop_id: Id::SearchModalBackdrop,
                close_button_id: Id::SearchModalClose,
            },
        )
    } else {
        html! {}
    }
}

fn view_search_modal<EntryId>(user_agent: &UserAgent, model: &Model<EntryId>) -> maud::Markup
where
    EntryId: Display + EntryExtra,
{
    html! {
        form id=(Id::QueryForm) class="h-[225px]" {
            div class="flex border-b border-gray-300" {
                label class="flex items-center w-12 justify-center font-bold text-slate-300" for=(Id::QueryInput) {
                    div class="w-5 h-5" {
                        (heroicons_maud::magnifying_glass_outline())
                    }
                }
                input id=(Id::QueryInput) value=(model.query) class="w-full border-none pl-0 ring-0 focus:ring-0 outline-none focus:outline-none" autocomplete="off" autocorrect="off" autocapitalize="off" enterkeyhint="go" spellcheck="false" placeholder="Quick action..." maxlength="64" type="text";
            }

            div {
                ul class="divide-y divide-gray-200" {
                    @for (index, entry) in model.matching_entries.iter().enumerate() {
                        li data-quick-action=(entry.0) ."bg-gray-100"[model.selected_index == Some(index)] {
                            button class="w-full py-2 px-4 flex justify-between hover:bg-gray-100" type="button" {
                                div class="flex items-center" {
                                    div class="w-4 h-4 flex items-center justify-center" {
                                        (entry.0.icon())
                                    }
                                    div class="ml-2 text-sm font-medium text-gray-900" {
                                        (entry.0.title())
                                    }
                                }
                                @if let Some(extra_text) = entry.0.extra_text(user_agent) {
                                    div class="text-sm text-gray-500" {
                                        (extra_text)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#[derive(Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Entry<EntryId>(EntryId);

impl<EntryId> Entry<EntryId> {
    pub fn new(id: EntryId) -> Self {
        Self(id)
    }
}

// TODO: rename
pub trait EntryExtra {
    fn title(&self) -> String;
    fn keywords(&self) -> Vec<String>;
    fn icon(&self) -> maud::Markup;

    fn extra_text(&self, _user_agent: &UserAgent) -> Option<String> {
        None
    }
}

fn find_entries<EntryId>(query: &str, entries: Vec<Entry<EntryId>>) -> Vec<Entry<EntryId>>
where
    EntryId: Clone + Eq + PartialEq + Hash + EntryExtra,
{
    if query.is_empty() {
        return vec![];
    }

    let lowercase_query = query.to_lowercase();

    let entries_starting_with: Vec<&Entry<_>> = entries
        .iter()
        .filter(|entry| {
            entry
                .0
                .keywords()
                .iter()
                .any(|keyword| keyword.to_lowercase().starts_with(&lowercase_query))
        })
        .collect();

    let entries_containing: Vec<&Entry<_>> = entries
        .iter()
        .filter(|entry| {
            entry
                .0
                .keywords()
                .iter()
                .any(|keyword| keyword.to_lowercase().contains(&lowercase_query))
        })
        .collect();

    [entries_starting_with, entries_containing]
        .concat()
        .into_iter()
        .unique()
        .take(5)
        .cloned()
        .collect()
}
