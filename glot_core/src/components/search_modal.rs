use crate::{
    common::keyboard_shortcut::KeyboardShortcut, util::user_agent::UserAgent, view::modal,
};
use itertools::Itertools;
use maud::html;
use poly::browser::{self, dom, Capture, DomId, Effects, Key, ModifierKey};
use serde::{Deserialize, Serialize};
use std::{fmt::Display, hash::Hash};

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct State<EntryId> {
    is_open: bool,
    query: String,
    matching_entries: Vec<Entry<EntryId>>,
    selected_index: Option<usize>,
}

impl<EntryId> Default for State<EntryId> {
    fn default() -> Self {
        Self {
            is_open: false,
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
    CloseSearchModal,
    SearchModalBackdrop,
}

pub fn subscriptions<ToParentMsg, ParentMsg, AppEffect, EntryId>(
    user_agent: &UserAgent,
    _state: &State<EntryId>,
    to_parent_msg: ToParentMsg,
) -> browser::Subscriptions<ParentMsg, AppEffect>
where
    ToParentMsg: Fn(Msg) -> ParentMsg,
{
    let key_combo = KeyboardShortcut::OpenQuickSearch.key_combo(user_agent);

    vec![
        browser::on_input(Id::QueryInput, |captured| {
            to_parent_msg(Msg::QueryChanged(captured))
        }),
        browser::on_click_closest(Id::CloseSearchModal, to_parent_msg(Msg::CloseModal)),
        browser::on_mouse_down(Id::SearchModalBackdrop, to_parent_msg(Msg::CloseModal)),
        browser::on_keyup(Key::Escape, to_parent_msg(Msg::CloseModal)),
        browser::on_keydown(
            key_combo.key,
            key_combo.modifier,
            to_parent_msg(Msg::OpenModal),
        ),
        browser::on_click_selector_closest(
            browser::Selector::data("quick-action"),
            browser::dom::get_target_data_string_value("quick-action"),
            |captured| to_parent_msg(Msg::QuickActionSelected(captured)),
        ),
        browser::on_submit(Id::QueryForm, to_parent_msg(Msg::FormSubmitted)),
        browser::on_keydown(
            Key::Key("ArrowUp".to_string()),
            ModifierKey::None,
            to_parent_msg(Msg::SelectPrevious),
        ),
        browser::on_keydown(
            Key::Key("ArrowDown".to_string()),
            ModifierKey::None,
            to_parent_msg(Msg::SelectNext),
        ),
    ]
}

pub struct UpdateData<ParentMsg, AppEffect, EntryId> {
    pub effects: Effects<ParentMsg, AppEffect>,
    pub selected_entry: Option<EntryId>,
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
            state.query = captured.value();
            state.matching_entries = find_entries(&state.query, entries);

            Ok(UpdateData {
                effects: vec![],
                selected_entry: None,
            })
        }

        Msg::OpenModal => {
            state.is_open = true;
            Ok(UpdateData {
                effects: vec![dom::focus_element(Id::QueryInput)],
                selected_entry: None,
            })
        }

        Msg::CloseModal => {
            *state = State::default();
            Ok(UpdateData {
                effects: vec![],
                selected_entry: None,
            })
        }

        Msg::QuickActionSelected(captured) => {
            let action_id = captured.value();
            let entry = entries
                .iter()
                .find(|entry| entry.0.to_string() == action_id);

            if let Some(entry) = entry {
                *state = State::default();

                Ok(UpdateData {
                    effects: vec![],
                    selected_entry: Some(entry.0.clone()),
                })
            } else {
                Ok(UpdateData {
                    effects: vec![],
                    selected_entry: None,
                })
            }
        }

        Msg::FormSubmitted => {
            let entries = state.matching_entries.clone();

            let selected_entry = if let Some(index) = state.selected_index {
                entries.get(index)
            } else {
                entries.first()
            };

            if let Some(entry) = selected_entry {
                *state = State::default();

                Ok(UpdateData {
                    effects: vec![],
                    selected_entry: Some(entry.0.clone()),
                })
            } else {
                Ok(UpdateData {
                    effects: vec![],
                    selected_entry: None,
                })
            }
        }

        Msg::SelectNext => {
            let new_index = if let Some(current_index) = state.selected_index {
                let entry_count = state.matching_entries.len();
                (current_index + 1) % entry_count
            } else {
                0
            };

            state.selected_index = Some(new_index);

            Ok(UpdateData {
                effects: vec![],
                selected_entry: None,
            })
        }

        Msg::SelectPrevious => {
            let current_index = state.selected_index.unwrap_or_default();
            let entry_count = state.matching_entries.len();
            let new_index = if current_index == 0 {
                entry_count - 1
            } else {
                current_index - 1
            };

            state.selected_index = Some(new_index);

            Ok(UpdateData {
                effects: vec![],
                selected_entry: None,
            })
        }
    }
}

pub fn view<EntryId>(state: &State<EntryId>) -> maud::Markup
where
    EntryId: Display + EntryExtra,
{
    if state.is_open {
        modal::view_barebones(
            view_search_modal(state),
            &modal::Config {
                backdrop_id: Id::SearchModalBackdrop,
                close_button_id: Id::CloseSearchModal,
            },
        )
    } else {
        html! {}
    }
}

fn view_search_modal<EntryId>(state: &State<EntryId>) -> maud::Markup
where
    EntryId: Display + EntryExtra,
{
    html! {
        form id=(Id::QueryForm) class="h-[225px]" {
            div class="flex border-b border-gray-300" {
                label class="flex items-center w-12 justify-center font-bold text-gray-700" for=(Id::QueryInput) {
                    div class="w-5 h-5" {
                        (heroicons_maud::magnifying_glass_outline())
                    }
                }
                input id=(Id::QueryInput) value=(state.query) class="w-full border-none pl-0 ring-0 focus:ring-0 outline-none focus:outline-none" autocomplete="off" autocorrect="off" autocapitalize="off" enterkeyhint="go" spellcheck="false" placeholder="Quick action" maxlength="64" type="text";
            }

            div {
                ul class="divide-y divide-gray-200" {
                    @for (index, entry) in state.matching_entries.iter().enumerate() {
                        li data-quick-action=(entry.0) ."bg-gray-100"[state.selected_index == Some(index)] {
                            button class="w-full py-2 px-4 flex items center justify-between hover:bg-gray-100" type="button" {
                                div class="flex items-center" {
                                    div class="w-4 h-4 flex items-center justify-center" {
                                        (entry.0.icon())
                                    }
                                    div class="ml-2 text-sm font-medium text-gray-900" {
                                        (entry.0.title())
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

    vec![entries_starting_with, entries_containing]
        .concat()
        .into_iter()
        .unique()
        .take(5)
        .cloned()
        .collect()
}
