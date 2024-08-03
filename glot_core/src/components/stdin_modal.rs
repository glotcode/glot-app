use crate::view::modal;
use maud::html;
use poly::browser::dom_id::DomId;
use poly::browser::effect::dom;
use poly::browser::effect::Effect;
use poly::browser::subscription;
use poly::browser::subscription::event_listener;
use poly::browser::subscription::Subscription;
use poly::browser::value::Capture;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct State {
    is_open: bool,
    value: String,
}

#[derive(strum_macros::Display, poly_macro::DomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
    StdinInput,
    ClearStdinButton,
    SaveStdinButton,
    StdinModalBackdrop,
    StdinModalClose,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub enum Msg {
    StdinChanged(Capture<String>),
    UpdateStdinClicked,
    ClearStdinClicked,
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
        backdrop_id: Id::StdinModalBackdrop,
        close_button_id: Id::StdinModalClose,
    };

    subscription::batch(vec![
        event_listener::on_input(Id::StdinInput, |captured| {
            to_parent_msg(Msg::StdinChanged(captured))
        }),
        event_listener::on_click(Id::ClearStdinButton, to_parent_msg(Msg::ClearStdinClicked)),
        event_listener::on_click(Id::SaveStdinButton, to_parent_msg(Msg::UpdateStdinClicked)),
        modal::subscriptions(&modal_config, to_parent_msg(Msg::Close)),
    ])
}

pub enum Event {
    None,
    StdinChanged(String),
}

pub fn update(msg: &Msg, state: &mut State) -> Result<Event, String> {
    match msg {
        Msg::StdinChanged(captured) => {
            state.value = captured.value();

            Ok(Event::None)
        }

        Msg::UpdateStdinClicked => {
            let event = Event::StdinChanged(state.value.clone());
            *state = State::default();

            Ok(event)
        }

        Msg::ClearStdinClicked => {
            let event = Event::StdinChanged("".to_string());
            *state = State::default();

            Ok(event)
        }

        Msg::Close => {
            *state = State::default();
            Ok(Event::None)
        }
    }
}

pub fn open<ParentMsg, AppEffect>(state: &mut State, value: &str) -> Effect<ParentMsg, AppEffect> {
    *state = State {
        is_open: true,
        value: value.to_string(),
        ..State::default()
    };

    dom::focus_element(Id::StdinInput)
}

pub fn view(state: &State) -> maud::Markup {
    if state.is_open {
        modal::view(
            view_modal(state),
            &modal::Config {
                backdrop_id: Id::StdinModalBackdrop,
                close_button_id: Id::StdinModalClose,
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
                "Stdin Data"
            }
        }

        form class="mt-8" {
            label class="block text-sm font-medium text-gray-700" for=(Id::StdinInput) {
                "Data will be sent to stdin of the program"
            }
            div class="mt-1" {
                textarea id=(Id::StdinInput) class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 font-mono" rows="8" {
                    (state.value)
                }
            }
        }

        div class="flex mt-4" {
            button id=(Id::ClearStdinButton) class="flex-1 w-full inline-flex items-center justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                "Clear"
            }
            button id=(Id::SaveStdinButton) class="ml-4 flex-1 w-full w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                "Update"
            }
        }
    }
}
