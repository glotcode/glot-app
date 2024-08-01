use maud::html;
use poly::browser::dom_id::DomId;
use poly::browser::effect::dom;
use poly::browser::effect::Effect;
use poly::browser::subscription;
use poly::browser::subscription::event_listener;
use poly::browser::subscription::Subscription;
use poly::browser::value::Capture;
use serde::{Deserialize, Serialize};

use crate::view::modal;

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct State {
    is_open: bool,
    title: String,
    error: Option<String>,
}

#[derive(strum_macros::Display, poly_macro::DomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
    TitleForm,
    TitleInput,
    UpdateTitleConfirm,
    TitleModalBackdrop,
    TitleModalClose,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub enum Msg {
    TitleChanged(Capture<String>),
    ConfirmUpdateTitle,
    Close,
}

pub fn subscriptions<ToParentMsg, ParentMsg, AppEffect>(
    _state: &State,
    to_parent_msg: ToParentMsg,
) -> Subscription<ParentMsg, AppEffect>
where
    ParentMsg: Clone,
    ToParentMsg: Fn(Msg) -> ParentMsg,
{
    let modal_config = modal::Config {
        backdrop_id: Id::TitleModalBackdrop,
        close_button_id: Id::TitleModalClose,
    };

    subscription::batch(vec![
        event_listener::on_input(Id::TitleInput, |captured| {
            to_parent_msg(Msg::TitleChanged(captured))
        }),
        event_listener::on_click(
            Id::UpdateTitleConfirm,
            to_parent_msg(Msg::ConfirmUpdateTitle),
        ),
        event_listener::on_submit(Id::TitleForm, to_parent_msg(Msg::ConfirmUpdateTitle)),
        modal::subscriptions(&modal_config, to_parent_msg(Msg::Close)),
    ])
}

pub enum Event {
    None,
    TitleChanged(String),
}

pub fn update(msg: &Msg, state: &mut State) -> Result<Event, String> {
    match msg {
        Msg::TitleChanged(captured) => {
            state.title = captured.value();
            state.error = None;
            Ok(Event::None)
        }

        Msg::ConfirmUpdateTitle => match validate_title(&state.title) {
            Ok(_) => {
                let title = state.title.clone();
                *state = State::default();
                Ok(Event::TitleChanged(title))
            }

            Err(err) => {
                state.error = Some(err);
                Ok(Event::None)
            }
        },

        Msg::Close => {
            *state = State::default();
            Ok(Event::None)
        }
    }
}

pub fn open<ParentMsg, AppEffect>(state: &mut State, title: &str) -> Effect<ParentMsg, AppEffect> {
    *state = State {
        is_open: true,
        title: title.to_string(),
        ..State::default()
    };

    dom::select_input_text(Id::TitleInput)
}

pub fn view(state: &State) -> maud::Markup {
    if state.is_open {
        modal::view(
            view_modal(state),
            &modal::Config {
                backdrop_id: Id::TitleModalBackdrop,
                close_button_id: Id::TitleModalClose,
            },
        )
    } else {
        html! {}
    }
}

fn view_modal(state: &State) -> maud::Markup {
    html! {
        div class="text-center" {
            h3 class="text-lg leading-6 font-medium text-gray-900" {
                "Edit Title"
            }
        }

        form id=(Id::TitleForm) class="mt-8" {
            label class="block text-sm font-medium text-gray-700" for=(Id::TitleInput) {
                "Title"
            }
            @match &state.error {
                Some(err) => {
                    div class="relative mt-1 rounded-md shadow-sm" {
                        input id=(Id::TitleInput) value=(state.title) class="block w-full rounded-md border-red-300 pr-10 text-red-900 placeholder-red-300 focus:border-red-500 focus:outline-none focus:ring-red-500 sm:text-sm" type="text" placeholder="Hello World" aria-invalid="true";
                        div class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3" {
                            span class="h-5 w-5 text-red-500" {
                                (heroicons_maud::exclamation_circle_solid())
                            }
                        }
                    }
                    p class="mt-2 text-sm text-red-600" {
                        (err)
                    }
                }

                None => {
                    div class="mt-1" {
                        input id=(Id::TitleInput) value=(state.title) class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" type="text" placeholder="Hello World";
                    }
                }
            }
        }

        div class="flex mt-4" {
            button id=(Id::UpdateTitleConfirm) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                "Update title"
            }
        }
    }
}

fn validate_title(title: &str) -> Result<(), String> {
    let max_length = 50;

    if title.is_empty() {
        Err("Title cannot be empty".to_string())
    } else if title.len() > max_length {
        Err(format!(
            "Title is {} character(s) too long",
            title.len() - max_length
        ))
    } else {
        Ok(())
    }
}
