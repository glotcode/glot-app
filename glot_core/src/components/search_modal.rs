use crate::{
    common::keyboard_shortcut::KeyboardShortcut, util::user_agent::UserAgent, view::modal,
};
use itertools::Itertools;
use maud::html;
use poly::browser::{self, dom, Capture, DomId, Effect, Effects, Key};
use serde::{Deserialize, Serialize};
use std::hash::{Hash, Hasher};

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct State {
    is_open: bool,
    query: String,
    matching_entries: Vec<Entry>,
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

pub fn subscriptions<ToParentMsg, ParentMsg, AppEffect>(
    user_agent: &UserAgent,
    _state: &State,
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

pub struct UpdateData<ParentMsg, AppEffect> {
    pub effects: Effects<ParentMsg, AppEffect>,
    pub selected_entry: Option<Entry>,
}

pub fn update<ToParentMsg, ParentMsg, AppEffect>(
    msg: &Msg,
    state: &mut State,
    entries: Vec<Entry>,
    _to_parent_msg: ToParentMsg,
) -> Result<UpdateData<ParentMsg, AppEffect>, String>
where
    ToParentMsg: Fn(Msg) -> ParentMsg,
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
            let entry = entries.iter().find(|entry| entry.id == action_id);

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

pub fn view(state: &State) -> maud::Markup {
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

fn view_search_modal(state: &State) -> maud::Markup {
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
pub struct Entry {
    pub id: String,
    pub title: String,
    pub keywords: Vec<String>,
}

fn find_entries(query: &str, entries: Vec<Entry>) -> Vec<Entry> {
    if query.is_empty() {
        return vec![];
    }

    let entries_starting_with: Vec<&Entry> = entries
        .iter()
        .filter(|entry| {
            entry
                .keywords
                .iter()
                .any(|keyword| keyword.starts_with(query))
        })
        .collect();

    let entries_containing: Vec<&Entry> = entries
        .iter()
        .filter(|entry| entry.keywords.iter().any(|keyword| keyword.contains(query)))
        .collect();

    vec![entries_starting_with, entries_containing]
        .concat()
        .into_iter()
        .unique()
        .take(5)
        .cloned()
        .collect()
}
