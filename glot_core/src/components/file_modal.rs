use crate::language::Language;
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
    backdrop_id: Id::FileModalBackdrop,
    close_button_id: Id::FileModalClose,
};

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub enum State {
    #[default]
    Closed,
    Open(Box<Model>),
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    language: Language,
    existing_filenames: Vec<String>,
    filename: String,
    is_new: bool,
    error: Option<String>,
}

impl Model {
    fn is_only_file(&self) -> bool {
        self.existing_filenames.is_empty()
    }

    fn filename_already_exists(&self) -> bool {
        self.existing_filenames
            .iter()
            .any(|name| *name == self.filename)
    }
}

#[derive(strum_macros::Display, poly_macro::DomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
    NewFileForm,
    EditFileForm,
    AddFileButton,
    UpdateFileButton,
    DeleteFileButton,
    FilenameInput,
    FileModalBackdrop,
    FileModalClose,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub enum Msg {
    AddFileClicked,
    UpdateFileClicked,
    DeleteFileClicked,
    FilenameChanged(Capture<String>),
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
                event_listener::on_click(Id::AddFileButton, to_parent_msg(Msg::AddFileClicked)),
                event_listener::on_click(
                    Id::UpdateFileButton,
                    to_parent_msg(Msg::UpdateFileClicked),
                ),
                event_listener::on_click(
                    Id::DeleteFileButton,
                    to_parent_msg(Msg::DeleteFileClicked),
                ),
                event_listener::on_input(Id::FilenameInput, |captured| {
                    to_parent_msg(Msg::FilenameChanged(captured))
                }),
                event_listener::on_submit(Id::NewFileForm, to_parent_msg(Msg::AddFileClicked)),
                event_listener::on_submit(Id::EditFileForm, to_parent_msg(Msg::UpdateFileClicked)),
                modal::subscriptions(&MODAL_CONFIG, to_parent_msg(Msg::Close)),
            ])
        }

        State::Closed => {
            // fmt
            subscription::none()
        }
    }
}

pub enum Event {
    None,
    FilenameChanged(String),
    FileAdded(String),
    FileDeleted,
    ModalClosed,
}

pub fn update(msg: &Msg, state: &mut State) -> Result<Event, String> {
    match msg {
        Msg::FilenameChanged(captured) => {
            if let State::Open(model) = state {
                model.filename = captured.value();
                model.error = None;
            }

            Ok(Event::None)
        }

        Msg::AddFileClicked => {
            if let State::Open(model) = state {
                match validate_filename(model) {
                    Ok(_) => {
                        let event = Event::FileAdded(model.filename.clone());
                        *state = State::default();
                        Ok(event)
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

        Msg::UpdateFileClicked => {
            if let State::Open(model) = state {
                match validate_filename(model) {
                    Ok(_) => {
                        let event = Event::FilenameChanged(model.filename.clone());
                        *state = Default::default();
                        Ok(event)
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

        Msg::DeleteFileClicked => {
            *state = Default::default();
            Ok(Event::FileDeleted)
        }

        Msg::Close => {
            *state = State::default();
            Ok(Event::ModalClosed)
        }
    }
}

pub struct EditContext {
    pub language: Language,
    pub existing_filenames: Vec<String>,
    pub filename: String,
}

pub fn open_for_edit<ParentMsg, AppEffect>(
    state: &mut State,
    ctx: EditContext,
) -> Effect<ParentMsg, AppEffect> {
    *state = State::Open(Box::new(Model {
        language: ctx.language,
        existing_filenames: ctx.existing_filenames,
        filename: ctx.filename,
        is_new: false,
        error: None,
    }));

    dom::select_input_text(Id::FilenameInput)
}

pub struct AddContext {
    pub language: Language,
    pub existing_filenames: Vec<String>,
}

pub fn open_for_add<ParentMsg, AppEffect>(
    state: &mut State,
    ctx: AddContext,
) -> Effect<ParentMsg, AppEffect> {
    *state = State::Open(Box::new(Model {
        language: ctx.language,
        existing_filenames: ctx.existing_filenames,
        filename: "".to_string(),
        is_new: true,
        error: None,
    }));

    dom::focus_element(Id::FilenameInput)
}

pub fn view(state: &State) -> maud::Markup {
    match state {
        State::Open(model) => modal::view(view_modal(model), &MODAL_CONFIG),
        State::Closed => html! {},
    }
}

fn view_modal(model: &Model) -> maud::Markup {
    let form_id = if model.is_new {
        Id::NewFileForm
    } else {
        Id::EditFileForm
    };

    let editor_config = model.language.config().editor_config();
    let placeholder = editor_config.default_filename;

    html! {
        div class="text-center" {
            h3 class="text-lg leading-6 font-medium text-gray-900" {
                @if model.is_new {
                    "New File"
                } @else {
                    "Edit File"
                }
            }
        }

        form id=(form_id) class="mt-8" {
            label class="block text-sm font-medium text-gray-700" for=(Id::FilenameInput) {
                "Filename"
            }
            @match &model.error {
                Some(err) => {
                    div class="relative mt-1 rounded-md shadow-sm" {
                        input id=(Id::FilenameInput) value=(model.filename) placeholder=(placeholder) class="block w-full rounded-md border-red-300 pr-10 text-red-900 placeholder-red-300 focus:border-red-500 focus:outline-none focus:ring-red-500 sm:text-sm" type="text" aria-invalid="true";
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
                        input id=(Id::FilenameInput) value=(model.filename)  placeholder=(placeholder) class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" type="text";
                    }
                }
            }
        }

        div class="flex mt-4" {
            @if model.is_new {
                button id=(Id::AddFileButton) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                    "Add file"
                }
            } @else if !model.is_only_file() {
                button id=(Id::DeleteFileButton) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-red-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                    "Delete file"
                }

                button id=(Id::UpdateFileButton) class="flex-1 w-full ml-4 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                    "Update file"
                }
            } @else {
                button id=(Id::UpdateFileButton) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                    "Update file"
                }
            }
        }
    }
}

fn validate_filename(model: &Model) -> Result<(), String> {
    if model.filename.is_empty() {
        Err("Filename cannot be empty".to_string())
    } else if model.filename_already_exists() {
        Err("Filename is already used by another file".to_string())
    } else {
        Ok(())
    }
}
