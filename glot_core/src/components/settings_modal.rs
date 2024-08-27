use crate::ace_editor::EditorKeyboardBindings;
use crate::ace_editor::EditorTheme;
use crate::view::dropdown;
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
    backdrop_id: Id::SettingsModalBackdrop,
    close_button_id: Id::SettingsModalClose,
};

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub enum State {
    #[default]
    Closed,
    Open(Model),
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    keyboard_bindings: EditorKeyboardBindings,
    theme: EditorTheme,
    command: String,
}

#[derive(strum_macros::Display, poly_macro::DomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
    KeyboardBindings,
    Theme,
    SettingsForm,
    SettingsSaveButton,
    SettingsModalBackdrop,
    SettingsModalClose,
    SettingsCommandInput,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub enum Msg {
    KeyboardBindingsChanged(Capture<EditorKeyboardBindings>),
    EditorThemeChanged(Capture<EditorTheme>),
    CommandChanged(Capture<String>),
    Save,
    Close,
}

pub fn subscriptions<ToParentMsg, ParentMsg>(
    state: &State,
    to_parent_msg: ToParentMsg,
) -> Subscription<ParentMsg>
where
    ParentMsg: Clone,
    ToParentMsg: Fn(Msg) -> ParentMsg,
{
    match state {
        State::Open(_) => {
            // fmt

            subscription::batch(vec![
                event_listener::on_change(Id::KeyboardBindings, |captured| {
                    to_parent_msg(Msg::KeyboardBindingsChanged(captured))
                }),
                event_listener::on_change(Id::Theme, |captured| {
                    to_parent_msg(Msg::EditorThemeChanged(captured))
                }),
                event_listener::on_input(Id::SettingsCommandInput, |captured| {
                    to_parent_msg(Msg::CommandChanged(captured))
                }),
                event_listener::on_click(Id::SettingsSaveButton, to_parent_msg(Msg::Save)),
                event_listener::on_submit(Id::SettingsForm, to_parent_msg(Msg::Save)),
                modal::subscriptions(&MODAL_CONFIG, to_parent_msg(Msg::Close)),
            ])
        }

        State::Closed => subscription::none(),
    }
}

pub enum Event {
    None,
    SettingsChanged(Settings),
    ModalClosed,
}

pub struct Settings {
    pub keyboard_bindings: EditorKeyboardBindings,
    pub theme: EditorTheme,
    pub command: String,
}

pub fn update(msg: &Msg, state: &mut State) -> Result<Event, String> {
    match msg {
        Msg::KeyboardBindingsChanged(captured) => {
            if let State::Open(model) = state {
                model.keyboard_bindings = captured.value();
            }

            Ok(Event::None)
        }

        Msg::EditorThemeChanged(captured) => {
            if let State::Open(model) = state {
                model.theme = captured.value();
            }

            Ok(Event::None)
        }

        Msg::CommandChanged(captured) => {
            if let State::Open(model) = state {
                model.command = captured.value();
            }

            Ok(Event::None)
        }

        Msg::Save => {
            if let State::Open(model) = state {
                let settings = Settings {
                    keyboard_bindings: model.keyboard_bindings.clone(),
                    theme: model.theme.clone(),
                    command: model.command.clone(),
                };
                *state = State::default();
                Ok(Event::SettingsChanged(settings))
            } else {
                Ok(Event::None)
            }
        }

        Msg::Close => {
            *state = State::default();
            Ok(Event::ModalClosed)
        }
    }
}

pub fn open<ParentMsg>(state: &mut State, settings: Settings) -> Effect<ParentMsg> {
    *state = State::Open(Model {
        keyboard_bindings: settings.keyboard_bindings,
        theme: settings.theme,
        command: settings.command,
    });

    dom::focus_element(Id::KeyboardBindings)
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
                "Settings"
            }
        }

        form id=(Id::SettingsForm) class="mt-8" {
            div class="border-b border-gray-200 pb-5" {
                h3 class="text-lg font-medium leading-6 text-gray-900" {
                    "Editor Settings"
                }
            }

            (dropdown::view(&dropdown::Config{
                id: Id::KeyboardBindings,
                title: "Keyboard Bindings",
                selected_value: &model.keyboard_bindings,
                options: dropdown::Options::Ungrouped(vec![
                    (&EditorKeyboardBindings::Default, &EditorKeyboardBindings::Default.label()),
                    (&EditorKeyboardBindings::Vim, &EditorKeyboardBindings::Vim.label()),
                    (&EditorKeyboardBindings::Emacs, &EditorKeyboardBindings::Emacs.label()),
                ]),
            }))

            (dropdown::view(&dropdown::Config{
                id: Id::Theme,
                title: "Theme",
                selected_value: &model.theme,
                options: dropdown::Options::Grouped(vec![
                    dropdown::Group{
                        label: "Bright",
                        options: vec![
                            (&EditorTheme::Chrome, &EditorTheme::Chrome.label()),
                            (&EditorTheme::Clouds, &EditorTheme::Clouds.label()),
                            (&EditorTheme::CrimsonEditor, &EditorTheme::CrimsonEditor.label()),
                            (&EditorTheme::Dawn, &EditorTheme::Dawn.label()),
                            (&EditorTheme::Dreamweaver, &EditorTheme::Dreamweaver.label()),
                            (&EditorTheme::Eclipse, &EditorTheme::Eclipse.label()),
                            (&EditorTheme::GitHub, &EditorTheme::GitHub.label()),
                            (&EditorTheme::SolarizedLight, &EditorTheme::SolarizedLight.label()),
                            (&EditorTheme::TextMate, &EditorTheme::TextMate.label()),
                            (&EditorTheme::Tomorrow, &EditorTheme::Tomorrow.label()),
                            (&EditorTheme::XCode, &EditorTheme::XCode.label()),
                            (&EditorTheme::Kuroir, &EditorTheme::Kuroir.label()),
                            (&EditorTheme::KatzenMilch, &EditorTheme::KatzenMilch.label()),
                        ],
                    },
                    dropdown::Group{
                        label: "Dark",
                        options: vec![
                            (&EditorTheme::Ambiance, &EditorTheme::Ambiance.label()),
                            (&EditorTheme::Chaos, &EditorTheme::Chaos.label()),
                            (&EditorTheme::CloudsMidnight, &EditorTheme::CloudsMidnight.label()),
                            (&EditorTheme::Cobalt, &EditorTheme::Cobalt.label()),
                            (&EditorTheme::IdleFingers, &EditorTheme::IdleFingers.label()),
                            (&EditorTheme::KrTheme, &EditorTheme::KrTheme.label()),
                            (&EditorTheme::Merbivore, &EditorTheme::Merbivore.label()),
                            (&EditorTheme::MerbivoreSoft, &EditorTheme::MerbivoreSoft.label()),
                            (&EditorTheme::MonoIndustrial, &EditorTheme::MonoIndustrial.label()),
                            (&EditorTheme::Monokai, &EditorTheme::Monokai.label()),
                            (&EditorTheme::PastelOnDark, &EditorTheme::PastelOnDark.label()),
                            (&EditorTheme::SolarizedDark, &EditorTheme::SolarizedDark.label()),
                            (&EditorTheme::Terminal, &EditorTheme::Terminal.label()),
                            (&EditorTheme::TomorrowNight, &EditorTheme::TomorrowNight.label()),
                            (&EditorTheme::TomorrowNightBlue, &EditorTheme::TomorrowNightBlue.label()),
                            (&EditorTheme::TomorrowNightBright, &EditorTheme::TomorrowNightBright.label()),
                            (&EditorTheme::TomorrowNightEighties, &EditorTheme::TomorrowNightEighties.label()),
                            (&EditorTheme::Twilight, &EditorTheme::Twilight.label()),
                            (&EditorTheme::VibrantInk, &EditorTheme::VibrantInk.label()),
                        ],
                    }
                ]),
            }))

            div class="border-b border-gray-200 pb-5 mt-8" {
                h3 class="text-lg font-medium leading-6 text-gray-900" {
                    "Run Settings"
                }
            }

            label class="mt-4 block text-sm font-medium text-gray-700" for=(Id::SettingsCommandInput) {
                "Run command"
            }
            div class="mt-1" {
                input id=(Id::SettingsCommandInput) value=(model.command) class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" type="text";
            }

            div class="flex mt-8" {
                button id=(Id::SettingsSaveButton) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                    "Save"
                }
            }
        }
    }
}
