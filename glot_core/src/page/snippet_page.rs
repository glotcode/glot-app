use crate::common::keyboard_shortcut::KeyboardShortcut;
use crate::common::route::Route;
use crate::components::search_modal;
use crate::language;
use crate::language::Language;
use crate::layout::app_layout;
use crate::snippet::File;
use crate::snippet::Snippet;
use crate::util::remote_data::RemoteData;
use crate::util::select_list::SelectList;
use crate::util::user_agent::UserAgent;
use crate::view::dropdown;
use crate::view::modal;
use maud::html;
use maud::Markup;
use poly::browser;
use poly::browser::dom_id::DomId;
use poly::browser::effect;
use poly::browser::effect::clipboard::WriteTextResult;
use poly::browser::effect::console;
use poly::browser::effect::dom;
use poly::browser::effect::local_storage;
use poly::browser::effect::Effect;
use poly::browser::keyboard::Key;
use poly::browser::selector::Selector;
use poly::browser::subscription;
use poly::browser::subscription::event_listener;
use poly::browser::subscription::Subscription;
use poly::browser::value::Capture;
use poly::browser::value::Value;
use poly::browser::WindowSize;
use poly::page::JsMsg;
use poly::page::Page;
use poly::page::PageMarkup;
use serde::{Deserialize, Serialize};
use std::cmp::max;
use std::fmt;
use std::time::Duration;
use url::Url;

const MIN_EDITOR_HEIGHT: u64 = 300;
const LOADING_TEXT: &'static str = r#"
LOAD"*",8,1

SEARCHING FOR *
LOADING
"#;

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    pub window_size: Option<WindowSize>,
    pub user_agent: UserAgent,
    pub language: language::Config,
    pub files: SelectList<File>,
    pub title: String,
    pub active_modal: Modal,
    pub editor_keyboard_bindings: EditorKeyboardBindings,
    pub editor_theme: EditorTheme,
    pub stdin: String,
    pub layout_state: app_layout::State,
    pub current_route: Route,
    pub current_url: Url,
    pub run_result: RemoteData<FailedRunResult, RunResult>,
    pub language_version_result: RemoteData<FailedRunResult, RunResult>,
    pub snippet: Option<Snippet>,
    pub search_modal_state: search_modal::State<QuickAction>,
}

#[derive(strum_macros::Display, poly_macro::DomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
    Glot,
    OpenSidebar,
    CloseSidebar,
    Editor,
    ModalBackdrop,
    ModalClose,
    ShowSettingsModal,
    ShowAddFileModal,
    AddFileConfirm,
    UpdateFileConfirm,
    DeleteFileConfirm,
    Filename,
    NewFileForm,
    EditFileForm,
    SelectedFile,
    EditorKeyboardBindings,
    EditorTheme,
    CloseSettings,
    ShowStdinModal,
    ShowStdinEditModal,
    Stdin,
    UpdateStdin,
    ClearStdin,
    Run,
    Share,
    CloseSharingModal,
    SnippetUrl,
    CopyUrl,
    // Title related
    Title,
    TopBarTitle,
    TitleForm,
    TitleInput,
    UpdateTitleConfirm,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub enum Msg {
    WindowSizeChanged(Capture<Value>),
    EditorContentChanged(Capture<String>),
    FileSelected(Capture<String>),
    ShowAddFileModalClicked,
    ShowSettingsModalClicked,
    ShowStdinModalClicked,
    CloseModalTriggered,
    ConfirmAddFile,
    ConfirmUpdateFile,
    ConfirmDeleteFile,
    FilenameChanged(Capture<String>),
    EditFileClicked,
    KeyboardBindingsChanged(Capture<Value>),
    EditorThemeChanged(Capture<Value>),
    GotSettings(Capture<Value>),
    SavedSettings(Capture<bool>),
    StdinChanged(Capture<String>),
    UpdateStdinClicked,
    ClearStdinClicked,
    OpenSidebarClicked,
    CloseSidebarClicked,
    RunClicked,
    ShareClicked,
    CopyUrlClicked,
    GotCopyUrlResult(Capture<WriteTextResult>),
    EncodeSnippetUrl,
    ClearCopyStateTimeout,
    // Title related
    EditTitleClicked,
    TitleChanged(Capture<String>),
    ConfirmUpdateTitle,
    // Search modal related
    SearchModalMsg(search_modal::Msg),
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Modal {
    None,
    File(FileState),
    Settings,
    Stdin(StdinState),
    Sharing(SharingState),
    Title(TitleState),
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FileState {
    filename: String,
    is_new: bool,
    error: Option<String>,
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TitleState {
    title: String,
    error: Option<String>,
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StdinState {
    stdin: String,
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SharingState {
    snippet_url: Option<String>,
    copy_state: RemoteData<String, ()>,
}

pub struct SnippetPage {
    pub window_size: Option<WindowSize>,
    pub user_agent: UserAgent,
    pub current_url: Url,
}

impl SnippetPage {
    fn get_model(&self) -> Result<Model, String> {
        let current_route = Route::from_path(self.current_url.path());

        match &current_route {
            Route::NewSnippet(language) => self.model_for_new_snippet(&current_route, language),

            Route::EditSnippet(language, encoded_snippet) => {
                self.model_for_existing_snippet(&current_route, language, encoded_snippet)
            }

            _ => Err("Invalid route".to_string()),
        }
    }

    fn model_for_new_snippet(&self, route: &Route, language: &Language) -> Result<Model, String> {
        let language_config = language.config();

        let file = File {
            name: language_config.editor_config.default_filename.clone(),
            content: language_config.editor_config.example_code.clone(),
        };

        Ok(Model {
            window_size: self.window_size.clone(),
            user_agent: self.user_agent.clone(),
            language: language_config,
            files: SelectList::singleton(file),
            title: "Hello World".to_string(),
            active_modal: Modal::None,
            editor_keyboard_bindings: EditorKeyboardBindings::Default,
            editor_theme: EditorTheme::TextMate,
            stdin: "".to_string(),
            layout_state: app_layout::State::new(),
            current_url: self.current_url.clone(),
            current_route: route.clone(),
            run_result: RemoteData::NotAsked,
            language_version_result: RemoteData::Loading,
            snippet: None,
            search_modal_state: search_modal::State::default(),
        })
    }

    fn model_for_existing_snippet(
        &self,
        route: &Route,
        language: &Language,
        encoded_snippet: &str,
    ) -> Result<Model, String> {
        let snippet = Snippet::from_encoded_string(encoded_snippet)
            .map_err(|err| format!("Failed to decode snippet: {}", err))?;

        let snippet_clone = snippet.clone();

        let language_config = language.config();

        let default_file = File {
            name: language_config.editor_config.default_filename.clone(),
            content: language_config.editor_config.example_code.clone(),
        };

        let snippet_files: Vec<File> = snippet
            .files
            .iter()
            .map(|file| File {
                name: file.name.clone(),
                content: file.content.clone(),
            })
            .collect();

        let files = SelectList::from_vec(snippet_files)
            .unwrap_or_else(|| SelectList::singleton(default_file));

        Ok(Model {
            window_size: self.window_size.clone(),
            user_agent: self.user_agent.clone(),
            language: language_config,
            files,
            title: snippet.title,
            active_modal: Modal::None,
            editor_keyboard_bindings: EditorKeyboardBindings::Default,
            editor_theme: EditorTheme::TextMate,
            stdin: snippet.stdin.to_string(),
            layout_state: app_layout::State::new(),
            current_url: self.current_url.clone(),
            current_route: route.clone(),
            run_result: RemoteData::NotAsked,
            language_version_result: RemoteData::Loading,
            snippet: Some(snippet_clone),
            search_modal_state: search_modal::State::default(),
        })
    }
}

impl Page<Model, Msg, AppEffect, Markup> for SnippetPage {
    fn id(&self) -> &'static dyn DomId {
        &Id::Glot
    }

    fn init(&self) -> Result<(Model, Effect<Msg, AppEffect>), String> {
        let model = self.get_model()?;

        let effect = effect::batch(vec![
            load_settings_effect(),
            get_language_version_effect(&model.language),
        ]);

        Ok((model, effect))
    }

    fn subscriptions(&self, model: &Model) -> Subscription<Msg, AppEffect> {
        let search_modal_subscriptions: Subscription<Msg, AppEffect> = search_modal::subscriptions(
            &model.user_agent,
            &model.search_modal_state,
            Msg::SearchModalMsg,
        );

        let run_key_combo = KeyboardShortcut::RunCode.key_combo(&model.user_agent);

        // TODO: add conditionals
        subscription::batch(vec![
            event_listener::on_change_string(Id::Editor, Msg::EditorContentChanged),
            event_listener::on_click_selector_closest(
                Selector::data("filename"),
                dom::get_target_data_string_value("filename"),
                Msg::FileSelected,
            ),
            event_listener::on_click_closest(Id::ShowAddFileModal, Msg::ShowAddFileModalClicked),
            event_listener::on_click_closest(Id::ShowSettingsModal, Msg::ShowSettingsModalClicked),
            event_listener::on_click_closest(Id::ShowStdinModal, Msg::ShowStdinModalClicked),
            event_listener::on_click_closest(Id::ShowStdinEditModal, Msg::ShowStdinModalClicked),
            event_listener::on_click_closest(Id::ModalClose, Msg::CloseModalTriggered),
            event_listener::on_click(Id::CloseSettings, Msg::CloseModalTriggered),
            event_listener::on_mouse_down(Id::ModalBackdrop, Msg::CloseModalTriggered),
            event_listener::on_click(Id::AddFileConfirm, Msg::ConfirmAddFile),
            event_listener::on_click(Id::UpdateFileConfirm, Msg::ConfirmUpdateFile),
            event_listener::on_click(Id::DeleteFileConfirm, Msg::ConfirmDeleteFile),
            event_listener::on_input(Id::Filename, Msg::FilenameChanged),
            event_listener::on_click_closest(Id::SelectedFile, Msg::EditFileClicked),
            event_listener::on_submit(Id::NewFileForm, Msg::ConfirmAddFile),
            event_listener::on_submit(Id::EditFileForm, Msg::ConfirmUpdateFile),
            event_listener::on_keyup(Key::Escape, Msg::CloseModalTriggered),
            event_listener::on_keydown(run_key_combo.key, run_key_combo.modifier, Msg::RunClicked),
            event_listener::on_window_resize(Msg::WindowSizeChanged),
            event_listener::on_change(Id::EditorKeyboardBindings, Msg::KeyboardBindingsChanged),
            event_listener::on_change(Id::EditorTheme, Msg::EditorThemeChanged),
            event_listener::on_input(Id::Stdin, Msg::StdinChanged),
            event_listener::on_click(Id::ClearStdin, Msg::ClearStdinClicked),
            event_listener::on_click(Id::UpdateStdin, Msg::UpdateStdinClicked),
            event_listener::on_click_closest(Id::OpenSidebar, Msg::OpenSidebarClicked),
            event_listener::on_click_closest(Id::CloseSidebar, Msg::CloseSidebarClicked),
            event_listener::on_click_closest(Id::Run, Msg::RunClicked),
            event_listener::on_click_closest(Id::Share, Msg::ShareClicked),
            event_listener::on_click_closest(Id::CopyUrl, Msg::CopyUrlClicked),
            event_listener::on_click(Id::CloseSharingModal, Msg::CloseModalTriggered),
            // Title
            event_listener::on_click_closest(Id::Title, Msg::EditTitleClicked),
            event_listener::on_click_closest(Id::TopBarTitle, Msg::EditTitleClicked),
            event_listener::on_input(Id::TitleInput, Msg::TitleChanged),
            event_listener::on_click(Id::UpdateTitleConfirm, Msg::ConfirmUpdateTitle),
            event_listener::on_submit(Id::TitleForm, Msg::ConfirmUpdateTitle),
            search_modal_subscriptions,
        ])
    }

    fn update(&self, msg: &Msg, model: &mut Model) -> Result<Effect<Msg, AppEffect>, String> {
        match msg {
            Msg::OpenSidebarClicked => {
                model.layout_state.open_sidebar();
                Ok(effect::none())
            }

            Msg::CloseSidebarClicked => {
                model.layout_state.close_sidebar();
                Ok(effect::none())
            }

            Msg::WindowSizeChanged(captured) => {
                let window_size = captured
                    .value()
                    .parse()
                    .map_err(|err| format!("Failed to parse window size: {}", err))?;

                model.window_size = Some(window_size);
                Ok(effect::none())
            }

            Msg::EditorContentChanged(captured) => {
                model.files.update_selected(|file| {
                    file.content = captured.value();
                });

                Ok(effect::none())
            }

            Msg::FileSelected(captured) => {
                let filename = captured.value();

                model
                    .files
                    .to_vec()
                    .iter()
                    .enumerate()
                    .find(|(_, file)| file.name == filename)
                    .map(|(index, _)| {
                        model.files.select_index(index);
                    });

                Ok(focus_editor_effect())
            }

            Msg::ShowAddFileModalClicked => {
                model.active_modal = Modal::File(FileState {
                    filename: "".to_string(),
                    is_new: true,
                    error: None,
                });

                Ok(dom::focus_element(Id::Filename))
            }

            Msg::ShowSettingsModalClicked => {
                model.active_modal = Modal::Settings;

                Ok(dom::focus_element(Id::EditorKeyboardBindings))
            }

            Msg::ShowStdinModalClicked => {
                model.active_modal = Modal::Stdin(StdinState {
                    stdin: model.stdin.clone(),
                });

                Ok(dom::focus_element(Id::Stdin))
            }

            Msg::FilenameChanged(captured) => {
                if let Modal::File(state) = &mut model.active_modal {
                    state.filename = captured.value();
                    state.error = None;
                }

                Ok(effect::none())
            }

            Msg::ConfirmAddFile => {
                if let Modal::File(state) = &mut model.active_modal {
                    match validate_filename(&model.files, &state.filename, true) {
                        Ok(_) => {
                            model.files.push(File {
                                name: state.filename.clone(),
                                content: "".to_string(),
                            });

                            model.files.select_last();
                            model.active_modal = Modal::None;
                            return Ok(focus_editor_effect());
                        }

                        Err(err) => {
                            state.error = Some(err);
                        }
                    }
                }

                Ok(effect::none())
            }

            Msg::ConfirmUpdateFile => {
                if let Modal::File(state) = &mut model.active_modal {
                    match validate_filename(&model.files, &state.filename, false) {
                        Ok(_) => {
                            model.files.update_selected(|file| {
                                file.name = state.filename.clone();
                            });

                            model.active_modal = Modal::None;
                            return Ok(focus_editor_effect());
                        }

                        Err(err) => {
                            state.error = Some(err);
                        }
                    }
                }

                Ok(effect::none())
            }

            Msg::ConfirmDeleteFile => {
                model.files.remove_selected();
                model.active_modal = Modal::None;
                Ok(focus_editor_effect())
            }

            Msg::CloseModalTriggered => {
                model.active_modal = Modal::None;
                Ok(effect::none())
            }

            Msg::EditFileClicked => {
                model.active_modal = Modal::File(FileState {
                    filename: model.files.selected().name.clone(),
                    is_new: false,
                    error: None,
                });

                Ok(dom::select_input_text(Id::Filename))
            }

            Msg::KeyboardBindingsChanged(captured) => {
                let keyboard_bindings = captured
                    .value()
                    .parse()
                    .map_err(|err| format!("Failed to parse keyboard bindings: {}", err))?;

                model.editor_keyboard_bindings = keyboard_bindings;

                Ok(save_settings_effect(&model))
            }

            Msg::EditorThemeChanged(captured) => {
                let editor_theme = captured
                    .value()
                    .parse()
                    .map_err(|err| format!("Failed to parse keyboard bindings: {}", err))?;

                model.editor_theme = editor_theme;

                Ok(save_settings_effect(&model))
            }

            Msg::GotSettings(captured) => {
                let maybe_settings: Option<LocalStorageSettings> = captured
                    .value()
                    .parse()
                    .map_err(|err| format!("Failed to parse settings: {}", err))?;

                if let Some(settings) = maybe_settings {
                    model.editor_keyboard_bindings = settings.editor_keyboard_bindings;
                    model.editor_theme = settings.editor_theme;
                }

                Ok(effect::none())
            }

            Msg::SavedSettings(_captured) => Ok(effect::none()),

            Msg::StdinChanged(captured) => {
                if let Modal::Stdin(state) = &mut model.active_modal {
                    state.stdin = captured.value()
                }

                Ok(effect::none())
            }

            Msg::ClearStdinClicked => {
                model.stdin.clear();
                model.active_modal = Modal::None;

                Ok(effect::none())
            }

            Msg::UpdateStdinClicked => {
                if let Modal::Stdin(state) = &mut model.active_modal {
                    model.stdin = state.stdin.clone();
                }

                model.active_modal = Modal::None;

                Ok(effect::none())
            }

            Msg::RunClicked => {
                let effect = run_effect(model);
                Ok(effect)
            }

            Msg::ShareClicked => {
                let state = SharingState {
                    snippet_url: None,
                    copy_state: RemoteData::NotAsked,
                };

                model.active_modal = Modal::Sharing(state);

                // TODO: request_animation_frame
                Ok(browser::effect::browser::set_timeout(
                    Duration::from_millis(500),
                    Msg::EncodeSnippetUrl,
                ))
            }

            Msg::EncodeSnippetUrl => {
                let snippet_url = get_snippet_url(model)?;
                if let Modal::Sharing(state) = &mut model.active_modal {
                    state.snippet_url = Some(snippet_url);
                }

                Ok(effect::none())
            }

            Msg::CopyUrlClicked => {
                if let Modal::Sharing(state) = &model.active_modal {
                    if let Some(snippet_url) = &state.snippet_url {
                        Ok(browser::effect::clipboard::write_text(
                            snippet_url,
                            Msg::GotCopyUrlResult,
                        ))
                    } else {
                        Ok(effect::none())
                    }
                } else {
                    Ok(effect::none())
                }
            }

            Msg::GotCopyUrlResult(captured) => {
                let result = captured.value();

                if let Modal::Sharing(state) = &mut model.active_modal {
                    if result.success {
                        state.copy_state = RemoteData::Success(());
                        Ok(browser::effect::browser::set_timeout(
                            Duration::from_secs(3),
                            Msg::ClearCopyStateTimeout,
                        ))
                    } else {
                        state.copy_state = RemoteData::Failure(result.error.unwrap_or_default());
                        Ok(browser::effect::browser::set_timeout(
                            Duration::from_secs(5),
                            Msg::ClearCopyStateTimeout,
                        ))
                    }
                } else {
                    Ok(effect::none())
                }
            }

            Msg::ClearCopyStateTimeout => {
                if let Modal::Sharing(state) = &mut model.active_modal {
                    state.copy_state = RemoteData::NotAsked
                }

                Ok(effect::none())
            }

            Msg::EditTitleClicked => {
                model.active_modal = Modal::Title(TitleState {
                    title: model.title.clone(),
                    error: None,
                });

                Ok(dom::select_input_text(Id::TitleInput))
            }

            Msg::TitleChanged(captured) => {
                if let Modal::Title(state) = &mut model.active_modal {
                    state.title = captured.value();
                    state.error = None;
                }

                Ok(effect::none())
            }

            Msg::ConfirmUpdateTitle => {
                if let Modal::Title(state) = &mut model.active_modal {
                    match validate_title(&state.title) {
                        Ok(_) => {
                            model.title = state.title.clone();
                            model.active_modal = Modal::None;
                            return Ok(focus_editor_effect());
                        }

                        Err(err) => {
                            state.error = Some(err);
                        }
                    }
                }

                Ok(effect::none())
            }

            Msg::SearchModalMsg(child_msg) => {
                let data: search_modal::UpdateData<Msg, AppEffect, QuickAction> =
                    search_modal::update(
                        &child_msg,
                        &mut model.search_modal_state,
                        quick_actions(),
                        Msg::SearchModalMsg,
                    )?;

                let effect = if let Some(entry) = data.selected_entry {
                    match entry {
                        QuickAction::Run => run_effect(model),

                        QuickAction::GoToLanguage(language) => {
                            let route = Route::NewSnippet(language);
                            let url = route.to_absolute_path(&model.current_url);
                            browser::effect::navigation::set_location(&url)
                        }
                    }
                } else {
                    effect::none()
                };

                Ok(effect::batch(vec![effect, data.effect]))
            }
        }
    }

    fn update_from_js(
        &self,
        msg: JsMsg,
        model: &mut Model,
    ) -> Result<Effect<Msg, AppEffect>, String> {
        match msg.type_.as_ref() {
            "GotRunResponse" => {
                let outcome = RunOutcome::from_value(msg.data)
                    .map_err(|err| format!("Failed to decode run response from js: {}", err))?;

                match outcome {
                    RunOutcome::Success(run_result) => {
                        model.run_result = RemoteData::Success(run_result);
                    }

                    RunOutcome::Failure(err) => {
                        model.run_result = RemoteData::Failure(err);
                    }
                }

                Ok(effect::none())
            }

            "GotLanguageVersionResponse" => {
                let outcome = RunOutcome::from_value(msg.data)
                    .map_err(|err| format!("Failed to decode run response from js: {}", err))?;

                match outcome {
                    RunOutcome::Success(run_result) => {
                        model.language_version_result = RemoteData::Success(run_result);
                    }

                    RunOutcome::Failure(err) => {
                        model.language_version_result = RemoteData::Failure(err);
                    }
                }

                Ok(effect::none())
            }

            _ => {
                let log_effect =
                    console::log(&format!("Got unknown message from JS: {}", msg.type_));
                Ok(log_effect)
            }
        }
    }

    fn view(&self, model: &Model) -> PageMarkup<Markup> {
        PageMarkup {
            head: view_head(model),
            body: view_body(model),
        }
    }

    fn render(&self, markup: Markup) -> String {
        markup.into_string()
    }

    fn render_page(&self, markup: PageMarkup<Markup>) -> String {
        app_layout::render_page(markup)
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

fn validate_filename(files: &SelectList<File>, filename: &str, is_new: bool) -> Result<(), String> {
    let is_duplicate = files
        .to_vec()
        .iter()
        .map(|file| &file.name)
        .any(|name| name == filename);

    let is_duplicate_of_selected = filename == files.selected().name;

    if filename.is_empty() {
        Err("Filename cannot be empty".to_string())
    } else if is_new && is_duplicate {
        Err("Filename is already used by another file".to_string())
    } else if is_duplicate && !is_duplicate_of_selected {
        Err("Filename is already used by another file".to_string())
    } else {
        Ok(())
    }
}

#[derive(Clone, serde::Serialize, serde::Deserialize, PartialEq)]
#[serde(rename_all = "camelCase")]
pub enum EditorKeyboardBindings {
    Default,
    Vim,
    Emacs,
}

impl EditorKeyboardBindings {
    fn ace_keyboard_handler(&self) -> String {
        match self {
            EditorKeyboardBindings::Default => "".into(),
            EditorKeyboardBindings::Vim => "ace/keyboard/vim".into(),
            EditorKeyboardBindings::Emacs => "ace/keyboard/emacs".into(),
        }
    }

    fn label(&self) -> String {
        match self {
            EditorKeyboardBindings::Default => "Default".into(),
            EditorKeyboardBindings::Vim => "Vim".into(),
            EditorKeyboardBindings::Emacs => "Emacs".into(),
        }
    }
}

#[derive(Clone, serde::Serialize, serde::Deserialize, PartialEq)]
#[serde(rename_all = "camelCase")]
pub enum EditorTheme {
    // Bright themes
    Chrome,
    Clouds,
    CrimsonEditor,
    Dawn,
    Dreamweaver,
    Eclipse,
    GitHub,
    SolarizedLight,
    TextMate,
    Tomorrow,
    XCode,
    Kuroir,
    KatzenMilch,
    // Dark themes
    Ambiance,
    Chaos,
    CloudsMidnight,
    Cobalt,
    IdleFingers,
    KrTheme,
    Merbivore,
    MerbivoreSoft,
    MonoIndustrial,
    Monokai,
    PastelOnDark,
    SolarizedDark,
    Terminal,
    TomorrowNight,
    TomorrowNightBlue,
    TomorrowNightBright,
    TomorrowNightEighties,
    Twilight,
    VibrantInk,
}

impl EditorTheme {
    fn label(&self) -> String {
        match self {
            EditorTheme::Chrome => "Chrome".into(),
            EditorTheme::Clouds => "Clouds".into(),
            EditorTheme::CrimsonEditor => "Crimson Editor".into(),
            EditorTheme::Dawn => "Dawn".into(),
            EditorTheme::Dreamweaver => "Dreamweaver".into(),
            EditorTheme::Eclipse => "Eclipse".into(),
            EditorTheme::GitHub => "GitHub".into(),
            EditorTheme::SolarizedLight => "Solarized Light".into(),
            EditorTheme::TextMate => "TextMate".into(),
            EditorTheme::Tomorrow => "Tomorrow".into(),
            EditorTheme::XCode => "XCode".into(),
            EditorTheme::Kuroir => "Kuroir".into(),
            EditorTheme::KatzenMilch => "KatzenMilch".into(),
            EditorTheme::Ambiance => "Ambiance".into(),
            EditorTheme::Chaos => "Chaos".into(),
            EditorTheme::CloudsMidnight => "Clouds Midnight".into(),
            EditorTheme::Cobalt => "Cobalt".into(),
            EditorTheme::IdleFingers => "Idle Fingers".into(),
            EditorTheme::KrTheme => "krTheme".into(),
            EditorTheme::Merbivore => "Merbivore".into(),
            EditorTheme::MerbivoreSoft => "Merbivore Soft".into(),
            EditorTheme::MonoIndustrial => "Mono Industrial".into(),
            EditorTheme::Monokai => "Monokai".into(),
            EditorTheme::PastelOnDark => "Pastel on dark".into(),
            EditorTheme::SolarizedDark => "Solarized Dark".into(),
            EditorTheme::Terminal => "Terminal".into(),
            EditorTheme::TomorrowNight => "Tomorrow Night".into(),
            EditorTheme::TomorrowNightBlue => "Tomorrow Night Blue".into(),
            EditorTheme::TomorrowNightBright => "Tomorrow Night Bright".into(),
            EditorTheme::TomorrowNightEighties => "Tomorrow Night 80s".into(),
            EditorTheme::Twilight => "Twilight".into(),
            EditorTheme::VibrantInk => "Vibrant Ink".into(),
        }
    }

    fn ace_theme(&self) -> String {
        match self {
            EditorTheme::Chrome => "ace/theme/chrome".into(),
            EditorTheme::Clouds => "ace/theme/clouds".into(),
            EditorTheme::CrimsonEditor => "ace/theme/crimson_editor".into(),
            EditorTheme::Dawn => "ace/theme/dawn".into(),
            EditorTheme::Dreamweaver => "ace/theme/dreamweaver".into(),
            EditorTheme::Eclipse => "ace/theme/eclipse".into(),
            EditorTheme::GitHub => "ace/theme/github".into(),
            EditorTheme::SolarizedLight => "ace/theme/solarized_light".into(),
            EditorTheme::TextMate => "ace/theme/textmate".into(),
            EditorTheme::Tomorrow => "ace/theme/tomorrow".into(),
            EditorTheme::XCode => "ace/theme/xcode".into(),
            EditorTheme::Kuroir => "ace/theme/kuroir".into(),
            EditorTheme::KatzenMilch => "ace/theme/katzenmilch".into(),
            EditorTheme::Ambiance => "ace/theme/ambiance".into(),
            EditorTheme::Chaos => "ace/theme/chaos".into(),
            EditorTheme::CloudsMidnight => "ace/theme/clouds_midnight".into(),
            EditorTheme::Cobalt => "ace/theme/cobalt".into(),
            EditorTheme::IdleFingers => "ace/theme/idle_fingers".into(),
            EditorTheme::KrTheme => "ace/theme/kr_theme".into(),
            EditorTheme::Merbivore => "ace/theme/merbivore".into(),
            EditorTheme::MerbivoreSoft => "ace/theme/merbivore_soft".into(),
            EditorTheme::MonoIndustrial => "ace/theme/mono_industrial".into(),
            EditorTheme::Monokai => "ace/theme/monokai".into(),
            EditorTheme::PastelOnDark => "ace/theme/pastel_on_dark".into(),
            EditorTheme::SolarizedDark => "ace/theme/solarized_dark".into(),
            EditorTheme::Terminal => "ace/theme/terminal".into(),
            EditorTheme::TomorrowNight => "ace/theme/tomorrow_night".into(),
            EditorTheme::TomorrowNightBlue => "ace/theme/tomorrow_night_blue".into(),
            EditorTheme::TomorrowNightBright => "ace/theme/tomorrow_night_bright".into(),
            EditorTheme::TomorrowNightEighties => "ace/theme/tomorrow_night_eighties".into(),
            EditorTheme::Twilight => "ace/theme/twilight".into(),
            EditorTheme::VibrantInk => "ace/theme/vibrant_ink".into(),
        }
    }
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(tag = "type", content = "config")]
#[serde(rename_all = "camelCase")]
pub enum AppEffect {
    Run(RunRequest),
    GetLanguageVersion(RunRequest),
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RunRequest {
    pub image: String,
    pub payload: RunRequestPayload,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RunResult {
    pub stdout: String,
    pub stderr: String,
    pub error: String,
}

impl RunResult {
    fn is_empty(&self) -> bool {
        self.stdout.is_empty() && self.stderr.is_empty() && self.error.is_empty()
    }
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FailedRunResult {
    message: String,
}

pub enum RunOutcome {
    Success(RunResult),
    Failure(FailedRunResult),
}

impl RunOutcome {
    fn from_value(value: serde_json::Value) -> Result<Self, serde_json::error::Error> {
        serde_json::from_value(value.clone())
            .map(Self::Success)
            .or_else(|_| serde_json::from_value(value).map(Self::Failure))
    }
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RunRequestPayload {
    pub language: language::Language,
    pub files: Vec<File>,
    pub stdin: String,
    pub command: Option<String>,
}

fn view_head(model: &Model) -> maud::Markup {
    let description = format!("Run and share {} snippets", model.language.name);

    html! {
        title { (model.title) " - " (model.language.name) " snippet" }
        meta name="description" content=(description);
        meta name="viewport" content="width=device-width, initial-scale=1";
        link id="app-styles" rel="stylesheet" href="/static/app.css?hash=checksum";
        script defer src="/static/vendor/ace/ace.js?hash=checksum" {}
        script defer type="module" src="/sw.js?hash=checksum" {}
        script defer type="module" src="/static/app.js?hash=checksum" {}
    }
}

fn view_body(model: &Model) -> maud::Markup {
    let layout_config = app_layout::Config {
        open_sidebar_id: Id::OpenSidebar,
        close_sidebar_id: Id::CloseSidebar,
    };

    let modal_config = modal::Config {
        backdrop_id: Id::ModalBackdrop,
        close_button_id: Id::ModalClose,
    };

    html! {
        div id=(Id::Glot) .h-full {
            (app_layout::app_shell(
                view_content(model),
                Some(view_topbar_title(model)),
                &layout_config,
                &model.layout_state,
                &model.current_route,
            ))


            @match &model.active_modal {
                Modal::None => {},

                Modal::File(state) => {
                    (modal::view(view_file_modal(model, state), &modal_config))
                },

                Modal::Stdin(state) => {
                    (modal::view(view_stdin_modal(state), &modal_config))
                }

                Modal::Settings => {
                    (modal::view(view_settings_modal(model), &modal_config))
                }

                Modal::Sharing(state) => {
                    (modal::view(view_sharing_modal(state), &modal_config))
                }

                Modal::Title(state) => {
                    (modal::view(view_title_modal(state), &modal_config))
                }
            }

            (search_modal::view(&model.user_agent, &model.search_modal_state))
        }
    }
}

fn view_topbar_title(model: &Model) -> maud::Markup {
    html! {
        h1 class="title my-auto ml-4 text-2xl font-semibold text-gray-900 relative" {
            button id=(Id::TopBarTitle) {
                (model.title)
            }

            span class="hidden edit-overlay absolute z-10 w-[30px] top-1/2 bottom-1/2 translate-y-1/2" {
                span class="absolute z-20 inset-0 m-auto w-5 h-5 text-black" {
                    (heroicons_maud::pencil_square_solid())
                }
            }
        }
    }
}

fn view_content(model: &Model) -> Markup {
    let has_real_window_size = model.window_size.is_some();
    let window_size = model.window_size.clone().unwrap_or_default();
    let editor_height = calc_editor_height(&window_size);
    let inline_styles = format!("height: {}px;", editor_height);
    let height = format!("{}px", editor_height);
    let content = model.files.selected().content;

    html! {
        div class="pt-6 h-full flex flex-col" {
            div {
                div class="max-w-7xl mx-auto pb-3 px-4 sm:px-6 lg:px-8 hidden xl:block" {
                    h1 class="title text-2xl font-semibold text-gray-900 relative inline" {
                        button id=(Id::Title) {
                            (model.title)
                        }
                        span class="hidden edit-overlay absolute z-10 w-[30px] top-1/2 bottom-1/2 translate-y-1/2" {
                            span class="absolute z-20 inset-0 m-auto w-5 h-5 text-black" {
                                (heroicons_maud::pencil_square_solid())
                            }
                        }
                    }
                }

                div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-8" {
                    div .hidden[!has_real_window_size] {
                        div class="border border-gray-400 shadow-lg" {
                            (view_tab_bar(model))

                            poly-ace-editor id=(Id::Editor)
                                style=(inline_styles)
                                class="relative block w-full text-base whitespace-pre font-mono"
                                editor-class="w-full text-base whitespace-pre font-mono"
                                stylesheet-id="app-styles"
                                height=(height)
                                keyboard-handler=(model.editor_keyboard_bindings.ace_keyboard_handler())
                                mode=(model.language.editor_config.mode)
                                use-soft-tabs=(model.language.editor_config.use_soft_tabs)
                                tab-size=(model.language.editor_config.soft_tab_size)
                                theme=(model.editor_theme.ace_theme())
                            {
                                (content)
                            }

                            (view_stdin_bar(model))
                            (view_action_bar())
                        }
                    }
                }
            }

            div class="w-full flex-1 max-w-7xl mx-auto pb-4 px-4 sm:px-6 md:px-8" {
                div ."h-full" ."pt-4" .hidden[!has_real_window_size] {
                    (view_output_panel(model))
                }
            }
        }
    }
}

fn extract_language_version(model: &Model) -> Option<String> {
    if let RemoteData::Success(run_result) = &model.language_version_result {
        if run_result.stdout.is_empty() {
            None
        } else {
            Some(run_result.stdout.clone())
        }
    } else {
        None
    }
}

fn view_output_panel(model: &Model) -> Markup {
    let ready_info = if let Some(version) = extract_language_version(model) {
        format!("READY.\n\n{}", version)
    } else {
        "READY.".to_string()
    };

    html! {
        div class="h-full border-b border-x border-gray-400 shadow-lg" {
            dl {
                @match &model.run_result {
                    RemoteData::NotAsked => {
                        (view_info(&ready_info))
                    }

                    RemoteData::Loading => {
                        (view_info(LOADING_TEXT))
                    }

                    RemoteData::Success(run_result) => {
                        @if run_result.is_empty() {
                            (view_info("EMPTY OUTPUT"))
                        } @else {
                            (view_run_result(run_result))
                        }
                    }

                    RemoteData::Failure(err) => {
                        (view_info(&format!("ERROR: {}", err.message)))
                    }
                }
            }
        }
    }
}

fn view_info(text: &str) -> Markup {
    html! {
        dt class="px-4 py-1 border-t border-b border-gray-400 text-sm text-slate-700 font-bold bg-blue-400" {
            pre { "INFO" }
        }
        dd class="px-4 py-2 overflow-y-auto" {
            pre { (text) }
        }
    }
}

fn view_run_result(run_result: &RunResult) -> Markup {
    html! {
        @if !run_result.stdout.is_empty() {
            dt class="px-4 py-1 border-t border-b border-gray-400 text-sm text-slate-700 font-bold bg-green-400" {
                pre { "STDOUT" }
            }
            dd class="px-4 py-2 overflow-y-auto" {
                pre {
                    (run_result.stdout)
                }
            }
        }

        @if !run_result.stderr.is_empty() {
            dt class="px-4 py-1 border-t border-b border-gray-400 text-sm text-slate-700 font-bold bg-yellow-400" {
                pre { "STDERR" }
            }
            dd class="px-4 py-2 overflow-y-auto" {
                pre {
                    (run_result.stderr)
                }
            }
        }

        @if !run_result.error.is_empty() {
            dt class="px-4 py-1 border-t border-b border-gray-400 text-sm text-slate-700 font-bold bg-red-400" {
                pre { "ERROR" }
            }
            dd class="px-4 py-2 overflow-y-auto" {
                pre {
                    (run_result.error)
                }
            }
        }
    }
}

fn view_tab_bar(model: &Model) -> Markup {
    let files = model.files.to_vec();

    html! {
        div class="h-10 flex border-b border-gray-400" {
            button id=(Id::ShowSettingsModal) class="inline-flex items-center text-gray-500 hover:text-gray-700 px-3" type="button" {
                span class="w-6 h-6" {
                    (heroicons_maud::cog_6_tooth_outline())
                }
            }

            div class="flex" {
                @for file in &files {
                    (view_file_tab(model, file))
                }
            }

            button id=(Id::ShowAddFileModal) class="inline-flex items-center text-gray-500 hover:text-gray-700 px-3 font-semibold text-sm border-l border-gray-400" type="button"{
                span class="w-5 h-5" {
                    (heroicons_maud::document_plus_outline())
                }
            }
        }
    }
}

fn view_file_tab(model: &Model, file: &File) -> Markup {
    let is_selected = model.files.selected().name == file.name;
    let id = is_selected.then_some(Id::SelectedFile);

    html! {
        button id=[id] data-filename=(file.name) .file .relative ."[min-width:5rem]" ."border-l" ."border-gray-400" ."cursor-pointer" ."inline-flex" ."items-center" ."justify-center" ."px-3" ."bg-indigo-100"[is_selected]  ."cursor-pointer" ."text-gray-500"[!is_selected] ."text-gray-800"[is_selected] ."hover:text-gray-800" ."text-sm" type="button" {
            span class {
                (file.name)
            }
            @if is_selected {
                span class="hidden edit-overlay absolute z-10 inset-0 w-full h-full bg-gray-500 bg-opacity-70" {
                    span class="absolute z-20 inset-0 m-auto w-5 h-5 text-slate-50" {
                        (heroicons_maud::pencil_square_solid())
                    }
                }
            }
        }
    }
}

fn view_stdin_bar(model: &Model) -> Markup {
    html! {
        @if model.stdin.is_empty() {
            button id=(Id::ShowStdinModal) class="flex justify-center h-10 w-full bg-white hover:bg-gray-50 text-gray-700 inline-flex items-center px-3 font-semibold text-sm border-t border-gray-400" type="button" {
                span class="w-5 h-5 mr-1" { (heroicons_maud::plus_circle_outline()) }
                span { "STDIN" }
            }
        } @else {
            div class="w-full h-24 border-t border-gray-400 overflow-hidden" {
                dt class="px-4 py-1 border-b border-gray-400 text-sm text-slate-700 font-bold bg-blue-400" {
                    pre { "STDIN" }
                }
                dd id=(Id::ShowStdinEditModal) class="h-full px-4 py-2 relative cursor-pointer stdin-preview" {
                    pre {
                        (model.stdin)
                    }

                    span class="hidden stdin-overlay absolute z-10 inset-0 w-full h-full bg-gray-500 bg-opacity-30" {
                        span class="absolute z-20 inset-0 mt-5 mx-auto w-5 h-5 text-slate-50" {
                            (heroicons_maud::pencil_square_solid())
                        }
                    }
                }
            }
        }
    }
}

fn view_action_bar() -> Markup {
    html! {
        div class="h-12 flex border-t border-gray-400" {
            button id=(Id::Run) class="bg-white hover:bg-gray-50 text-gray-700 w-full inline-flex items-center justify-center px-3 py-1 font-semibold text-sm" type="button" {
                span class="w-5 h-5 mr-2" { (heroicons_maud::play_outline()) }
                span { "RUN" }
            }

            button id=(Id::Share) class="bg-white hover:bg-gray-50 text-gray-700 w-full inline-flex items-center justify-center px-3 py-1 font-semibold text-sm border-l border-gray-400" type="button" {
                span class="w-5 h-5 mr-2" { (heroicons_maud::share_outline()) }
                span { "SHARE" }
            }
        }
    }
}

fn view_title_modal(state: &TitleState) -> maud::Markup {
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

fn view_file_modal(model: &Model, state: &FileState) -> maud::Markup {
    let form_id = if state.is_new {
        Id::NewFileForm
    } else {
        Id::EditFileForm
    };

    let files_count = model.files.len();

    html! {
        div class="text-center" {
            h3 class="text-lg leading-6 font-medium text-gray-900" {
                @if state.is_new {
                    "New File"
                } @else {
                    "Edit File"
                }
            }
        }

        form id=(form_id) class="mt-8" {
            label class="block text-sm font-medium text-gray-700" for=(Id::Filename) {
                "Filename"
            }
            @match &state.error {
                Some(err) => {
                    div class="relative mt-1 rounded-md shadow-sm" {
                        input id=(Id::Filename) value=(state.filename) class="block w-full rounded-md border-red-300 pr-10 text-red-900 placeholder-red-300 focus:border-red-500 focus:outline-none focus:ring-red-500 sm:text-sm" type="text" placeholder="main.rs" aria-invalid="true";
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
                        input id=(Id::Filename) value=(state.filename) class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" type="text" placeholder="main.rs";
                    }
                }
            }
        }

        div class="flex mt-4" {
            @if state.is_new {
                button id=(Id::AddFileConfirm) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                    "Add file"
                }
            } @else if files_count > 1 {
                button id=(Id::DeleteFileConfirm) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-red-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                    "Delete file"
                }

                button id=(Id::UpdateFileConfirm) class="flex-1 w-full ml-4 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                    "Update file"
                }
            } @else {
                button id=(Id::UpdateFileConfirm) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                    "Update file"
                }
            }
        }
    }
}

fn view_stdin_modal(state: &StdinState) -> maud::Markup {
    html! {
        div class="text-center" {
            h3 class="text-lg leading-6 font-medium text-gray-900" {
                "Stdin Data"
            }
        }

        form class="mt-8" {
            label class="block text-sm font-medium text-gray-700" for=(Id::Stdin) {
                "Data will be sent to stdin of the program"
            }
            div class="mt-1" {
                textarea id=(Id::Stdin) class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 font-mono" rows="8" {
                    (state.stdin)
                }
            }
        }

        div class="flex mt-4" {
            button id=(Id::ClearStdin) class="flex-1 w-full inline-flex items-center justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                "Clear"
            }
            button id=(Id::UpdateStdin) class="ml-4 flex-1 w-full w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                "Update"
            }
        }
    }
}

fn view_settings_modal(model: &Model) -> maud::Markup {
    html! {
        div class="text-center" {
            h3 class="text-lg leading-6 font-medium text-gray-900" {
                "Settings"
            }
        }

        div class="border-b border-gray-200 pb-5 mt-8" {
            h3 class="text-lg font-medium leading-6 text-gray-900" {
                "Editor Settings"
            }
        }

        (dropdown::view(&dropdown::Config{
            id: Id::EditorKeyboardBindings,
            title: "Keyboard Bindings",
            selected_value: &model.editor_keyboard_bindings,
            options: dropdown::Options::Ungrouped(vec![
                (&EditorKeyboardBindings::Default, &EditorKeyboardBindings::Default.label()),
                (&EditorKeyboardBindings::Vim, &EditorKeyboardBindings::Vim.label()),
                (&EditorKeyboardBindings::Emacs, &EditorKeyboardBindings::Emacs.label()),
            ]),
        }))

        (dropdown::view(&dropdown::Config{
            id: Id::EditorTheme,
            title: "Theme",
            selected_value: &model.editor_theme,
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

        div class="flex mt-4" {
            button id=(Id::CloseSettings) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                "Close"
            }
        }
    }
}

enum SnippetUrlOverlay {
    Encoding,
    Copied,
    Failure,
}

impl SnippetUrlOverlay {
    fn from_state(state: &SharingState) -> Option<Self> {
        match state.copy_state {
            RemoteData::Success(_) => Some(Self::Copied),
            RemoteData::Failure(_) => Some(Self::Failure),
            RemoteData::NotAsked => {
                if state.snippet_url.is_none() {
                    Some(Self::Encoding)
                } else {
                    None
                }
            }
            _ => None,
        }
    }
}

impl fmt::Display for SnippetUrlOverlay {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Self::Encoding => write!(f, "Encoding snippet..."),
            Self::Copied => write!(f, "Copied to clipboard!"),
            Self::Failure => write!(f, "Failed to copy url"),
        }
    }
}

fn view_sharing_modal(state: &SharingState) -> maud::Markup {
    let url_max_length = 16000;
    let maybe_overlay = SnippetUrlOverlay::from_state(state);
    let snippet_url_value = state.snippet_url.clone().unwrap_or_default();
    let url_length = snippet_url_value.len();

    html! {
        div class="text-center" {
            h3 class="text-lg leading-6 font-medium text-gray-900" {
                "Share snippet"
            }
        }

        div class="mt-4" {
            label class="block text-sm font-medium leading-6 text-gray-900" for=(Id::SnippetUrl) {
                "Snippet url"
            }
            div class="mt-2 flex rounded-md shadow-sm" {
                div class="relative flex flex-grow items-stretch focus-within:z-10" {
                    input id=(Id::SnippetUrl) value=(snippet_url_value) readonly class="block w-full rounded-none rounded-l-md border-0 py-1.5 px-2 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6";

                    @if let Some(overlay) = maybe_overlay {
                        div class="absolute flex justify-center items-center w-full h-full rounded-none rounded-l-md border-0 bg-white ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 text-grey-900" {
                            (overlay)
                        }
                    }
                }
                button id=(Id::CopyUrl) disabled[state.snippet_url.is_none()] class="relative -ml-px inline-flex items-center gap-x-1.5 rounded-r-md px-3 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50" type="button" {
                    span class="w-4 h-4" {
                        (heroicons_maud::clipboard_outline())
                    }
                    "Copy"
                }
            }
            p class="mt-2 text-sm text-gray-500" {
                "The snippet is embedded in the url using brotli compression and base62 encoding."
            }

            @if url_length > url_max_length {
                p class="mt-2 text-sm text-red-500" {
                    (format!("{} / {}", url_length, url_max_length))
                }
            } @else {
                p class="mt-2 text-sm text-gray-500" {
                    (format!("{} / {}", url_length, url_max_length))
                }
            }
        }

        div class="flex mt-6" {
            button id=(Id::CloseSharingModal) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                "Close"
            }
        }
    }
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LocalStorageSettings {
    pub editor_keyboard_bindings: EditorKeyboardBindings,
    pub editor_theme: EditorTheme,
}

fn load_settings_effect() -> Effect<Msg, AppEffect> {
    local_storage::get_item("settings", Msg::GotSettings)
}

fn save_settings_effect(model: &Model) -> Effect<Msg, AppEffect> {
    local_storage::set_item(
        "settings",
        LocalStorageSettings {
            editor_keyboard_bindings: model.editor_keyboard_bindings.clone(),
            editor_theme: model.editor_theme.clone(),
        },
        Msg::SavedSettings,
    )
}

fn get_language_version_effect(language: &language::Config) -> Effect<Msg, AppEffect> {
    let config = RunRequest {
        image: language.run_config.container_image.clone(),
        payload: RunRequestPayload {
            language: language.id.clone(),
            files: vec![],
            stdin: "".to_string(),
            command: Some(language.run_config.version_command.clone()),
        },
    };

    effect::app_effect(AppEffect::GetLanguageVersion(config))
}

fn focus_editor_effect() -> Effect<Msg, AppEffect> {
    dom::dispatch_element_event(Id::Editor, "focus")
}

fn calc_editor_height(window_size: &WindowSize) -> u64 {
    let height = if window_size.height < 800 {
        (window_size.height as f64 * 0.4) as u64
    } else if window_size.height < 1100 {
        (window_size.height as f64 * 0.5) as u64
    } else if window_size.height < 1400 {
        (window_size.height as f64 * 0.6) as u64
    } else {
        (window_size.height as f64 * 0.7) as u64
    };

    max(height, MIN_EDITOR_HEIGHT)
}

fn get_snippet_url(model: &Model) -> Result<String, String> {
    let snippet = Snippet {
        language: model.language.id.to_string(),
        title: model.title.clone(),
        stdin: model.stdin.clone(),
        files: model.files.to_vec(),
    };

    let encoded_snippet = snippet
        .to_encoded_string()
        .map_err(|err| format!("Failed to encode snippet: {}", err))?;

    let route = Route::EditSnippet(model.language.id.clone(), encoded_snippet.clone());
    Ok(route.to_absolute_path(&model.current_url))
}

fn run_effect(model: &mut Model) -> Effect<Msg, AppEffect> {
    let config = RunRequest {
        image: model.language.run_config.container_image.clone(),
        payload: RunRequestPayload {
            language: model.language.id.clone(),
            files: model.files.to_vec(),
            stdin: model.stdin.clone(),
            command: None,
        },
    };

    model.run_result = RemoteData::Loading;

    effect::app_effect(AppEffect::Run(config))
}

#[derive(Clone, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum QuickAction {
    Run,
    GoToLanguage(Language),
}

impl search_modal::EntryExtra for QuickAction {
    fn title(&self) -> String {
        match self {
            QuickAction::Run => "Run code".to_string(),
            QuickAction::GoToLanguage(language) => format!("Go to {}", language.config().name),
        }
    }

    fn keywords(&self) -> Vec<String> {
        match self {
            QuickAction::Run => vec!["run".to_string()],
            QuickAction::GoToLanguage(language) => {
                vec![language.to_string(), language.config().name.clone()]
            }
        }
    }

    fn icon(&self) -> maud::Markup {
        match self {
            QuickAction::Run => heroicons_maud::play_outline(),
            QuickAction::GoToLanguage(_) => heroicons_maud::link_outline(),
        }
    }

    fn extra_text(&self, user_agent: &UserAgent) -> Option<String> {
        match self {
            QuickAction::Run => {
                let key_combo = KeyboardShortcut::RunCode.key_combo(user_agent);
                Some(key_combo.to_string())
            }
            _ => None,
        }
    }
}

impl fmt::Display for QuickAction {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            QuickAction::Run => write!(f, "run"),
            QuickAction::GoToLanguage(language) => write!(f, "goto-{}", language),
        }
    }
}

fn quick_actions() -> Vec<search_modal::Entry<QuickAction>> {
    let mut entries = vec![search_modal::Entry::new(QuickAction::Run)];

    let language_entries: Vec<_> = Language::list()
        .iter()
        .map(|language| search_modal::Entry::new(QuickAction::GoToLanguage(language.clone())))
        .collect();

    entries.extend(language_entries);

    entries
}
