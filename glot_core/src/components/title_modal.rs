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

const MODAL_CONFIG: modal::Config<Id> = modal::Config {
    backdrop_id: Id::TitleModalBackdrop,
    close_button_id: Id::TitleModalClose,
};

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub enum State {
    #[default]
    Closed,
    Open(Model),
}

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    title: String,
    error: Option<String>,
}

#[derive(strum_macros::Display, poly_macro::DomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
    TitleForm,
    TitleInput,
    UpdateTitleButton,
    TitleModalBackdrop,
    TitleModalClose,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub enum Msg {
    TitleChanged(Capture<String>),
    UpdateTitleClicked,
    Close,
}

pub fn subscriptions<ToParentMsg, ParentMsg, AppEffect>(
    state: &State,
    to_parent_msg: ToParentMsg,
) -> Subscription<ParentMsg, AppEffect>
where
    ParentMsg: Clone,
    ToParentMsg: Fn(Msg) -> ParentMsg,
{
    match state {
        State::Open(_) => {
            // fmt
            subscription::batch(vec![
                event_listener::on_input(Id::TitleInput, |captured| {
                    to_parent_msg(Msg::TitleChanged(captured))
                }),
                event_listener::on_click(
                    Id::UpdateTitleButton,
                    to_parent_msg(Msg::UpdateTitleClicked),
                ),
                event_listener::on_submit(Id::TitleForm, to_parent_msg(Msg::UpdateTitleClicked)),
                modal::subscriptions(&MODAL_CONFIG, to_parent_msg(Msg::Close)),
            ])
        }

        State::Closed => subscription::none(),
    }
}

pub enum Event {
    None,
    TitleChanged(String),
}

pub fn update(msg: &Msg, state: &mut State) -> Result<Event, String> {
    match msg {
        Msg::TitleChanged(captured) => {
            if let State::Open(model) = state {
                model.title = captured.value();
                model.error = None;
            }
            Ok(Event::None)
        }

        Msg::UpdateTitleClicked => {
            if let State::Open(model) = state {
                match validate_title(&model.title) {
                    Ok(_) => {
                        let title = model.title.clone();
                        *state = State::default();
                        Ok(Event::TitleChanged(title))
                    }

                    Err(err) => {
                        model.error = Some(err);
                        Ok(Event::None)
                    }
                }
            } else {
                Ok(Event::None)
            }
        }

        Msg::Close => {
            *state = State::default();
            Ok(Event::None)
        }
    }
}

pub fn open<ParentMsg, AppEffect>(state: &mut State, title: &str) -> Effect<ParentMsg, AppEffect> {
    *state = State::Open(Model {
        title: title.to_string(),
        ..Model::default()
    });

    dom::select_input_text(Id::TitleInput)
}

pub fn view(state: &State) -> maud::Markup {
    if let State::Open(model) = state {
        modal::view(view_modal(model), &MODAL_CONFIG)
    } else {
        html! {}
    }
}

fn view_modal(model: &Model) -> maud::Markup {
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
            @match &model.error {
                Some(err) => {
                    div class="relative mt-1 rounded-md shadow-sm" {
                        input id=(Id::TitleInput) value=(model.title) class="block w-full rounded-md border-red-300 pr-10 text-red-900 placeholder-red-300 focus:border-red-500 focus:outline-none focus:ring-red-500 sm:text-sm" type="text" placeholder="Hello World" aria-invalid="true";
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
                        input id=(Id::TitleInput) value=(model.title) class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" type="text" placeholder="Hello World";
                    }
                }
            }
        }

        div class="flex mt-4" {
            button id=(Id::UpdateTitleButton) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
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
