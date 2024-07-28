use crate::{
    common::keyboard_shortcut::KeyboardShortcut, util::user_agent::UserAgent, view::modal,
};
use itertools::Itertools;
use maud::html;
use poly::browser::{self, dom, Capture, DomId, Effects, Key};
use serde::{Deserialize, Serialize};
use std::{fmt::Display, hash::Hash};

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct State<EntryId> {
    is_open: bool,
    query: String,
    matching_entries: Vec<Entry<EntryId>>,
}

impl<EntryId> Default for State<EntryId> {
    fn default() -> Self {
        Self {
            is_open: false,
            query: String::new(),
            matching_entries: vec![],
        }
    }
}

#[derive(Clone, Serialize, Deserialize)]
pub enum Msg {
    QueryChanged(Capture<String>),
    OpenModal,
    CloseModal,
    QuickActionSelected(Capture<String>),
}

#[derive(strum_macros::Display, poly_macro::DomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
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
    ]
}

pub struct UpdateData<ParentMsg, AppEffect, EntryId> {
    pub effects: Effects<ParentMsg, AppEffect>,
    pub selected_entry: Option<Entry<EntryId>>,
}

pub fn update<ToParentMsg, ParentMsg, AppEffect, EntryId>(
    msg: &Msg,
    state: &mut State<EntryId>,
    entries: Vec<Entry<EntryId>>,
    _to_parent_msg: ToParentMsg,
) -> Result<UpdateData<ParentMsg, AppEffect, EntryId>, String>
where
    ToParentMsg: Fn(Msg) -> ParentMsg,
    EntryId: Clone + Eq + PartialEq + Hash + Display,
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
                .find(|entry| entry.id.to_string() == action_id);

            if let Some(entry) = entry {
                *state = State::default();

                Ok(UpdateData {
                    effects: vec![],
                    selected_entry: Some(entry.clone()),
                })
            } else {
                Ok(UpdateData {
                    effects: vec![],
                    selected_entry: None,
                })
            }
        }
    }
}

pub fn view<EntryId: Display>(state: &State<EntryId>) -> maud::Markup {
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

fn view_search_modal<EntryId: Display>(state: &State<EntryId>) -> maud::Markup {
    html! {
        div class="h-[400px]" {
            div {
                input id=(Id::QueryInput) value=(state.query) autocomplete="off" autocorrect="off" autocapitalize="off" enterkeyhint="go" spellcheck="false" placeholder="Quick action" maxlength="64" type="search";
            }

            div {
                ul class="mt-2 divide-y divide-gray-200" {
                    @for entry in &state.matching_entries {
                        li data-quick-action=(entry.id) class="py py-2 px-4 cursor-pointer hover:bg-gray-100" {
                            div class="flex items center justify-between" {
                                div class="flex items center" {
                                    div class="text-sm font-medium text-gray-900" { (entry.title) }
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
pub struct Entry<EntryId> {
    pub id: EntryId,
    pub title: String,
    pub keywords: Vec<String>,
}

fn find_entries<EntryId>(query: &str, entries: Vec<Entry<EntryId>>) -> Vec<Entry<EntryId>>
where
    EntryId: Clone + Eq + PartialEq + Hash,
{
    if query.is_empty() {
        return vec![];
    }

    let lowercase_query = query.to_lowercase();

    let entries_starting_with: Vec<&Entry<_>> = entries
        .iter()
        .filter(|entry| {
            entry
                .keywords
                .iter()
                .any(|keyword| keyword.to_lowercase().starts_with(&lowercase_query))
        })
        .collect();

    let entries_containing: Vec<&Entry<_>> = entries
        .iter()
        .filter(|entry| {
            entry
                .keywords
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
