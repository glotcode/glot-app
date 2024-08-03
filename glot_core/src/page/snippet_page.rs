use crate::ace_editor::EditorKeyboardBindings;
use crate::ace_editor::EditorTheme;
use crate::common::keyboard_shortcut::KeyboardShortcut;
use crate::common::route::Route;
use crate::components::search_modal;
use crate::components::settings_modal;
use crate::components::sharing_modal;
use crate::components::stdin_modal;
use crate::components::title_modal;
use crate::language;
use crate::language::Language;
use crate::layout::app_layout;
use crate::snippet::File;
use crate::snippet::Snippet;
use crate::util::remote_data::RemoteData;
use crate::util::select_list::SelectList;
use crate::util::user_agent::UserAgent;
use crate::view::modal;
use maud::html;
use maud::Markup;
use poly::browser;
use poly::browser::dom_id::DomId;
use poly::browser::effect;
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
use poly::browser::WindowSize;
use poly::page::JsMsg;
use poly::page::Page;
use poly::page::PageMarkup;
use serde::{Deserialize, Serialize};
use std::cmp::max;
use std::fmt;
use url::Url;

const MIN_EDITOR_HEIGHT: u64 = 300;
const LOADING_TEXT: &str = r#"
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
    pub title_modal_state: title_modal::State,
    pub sharing_modal_state: sharing_modal::State,
    pub settings_modal_state: settings_modal::State,
    pub stdin_modal_state: stdin_modal::State,
}

#[derive(strum_macros::Display, poly_macro::DomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
    Glot,
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
    CloseSettings,
    ShowStdinModal,
    Run,
    Share,
    // Title related
    Title,
    TopBarTitle,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub enum Msg {
    WindowSizeChanged(Capture<WindowSize>),
    EditorContentChanged(Capture<String>),
    FileSelected(Capture<String>),
    ShowAddFileModalClicked,
    ShowSettingsModalClicked,
    CloseModalTriggered,
    ConfirmAddFile,
    ConfirmUpdateFile,
    ConfirmDeleteFile,
    FilenameChanged(Capture<String>),
    EditFileClicked,
    RunClicked,

    // Title related
    EditTitleClicked,
    TitleModalMsg(title_modal::Msg),

    // Sharing related
    ShareClicked,
    SharingModalMsg(sharing_modal::Msg),

    // Settings related
    SettingsModalMsg(settings_modal::Msg),
    GotSettings(Capture<Option<LocalStorageSettings>>),
    SavedSettings(Capture<bool>),

    // Stdin related
    ShowStdinModalClicked,
    StdinModalMsg(stdin_modal::Msg),

    // Search modal related
    SearchModalMsg(search_modal::Msg),

    // App layout related
    AppLayoutMsg(app_layout::Msg),
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Modal {
    None,
    File(FileState),
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FileState {
    filename: String,
    is_new: bool,
    error: Option<String>,
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

        let title = "Hello World".to_string();

        Ok(Model {
            window_size: self.window_size.clone(),
            user_agent: self.user_agent.clone(),
            language: language_config,
            files: SelectList::singleton(file),
            title,
            active_modal: Modal::None,
            editor_keyboard_bindings: Default::default(),
            editor_theme: Default::default(),
            stdin: "".to_string(),
            layout_state: app_layout::State::default(),
            current_url: self.current_url.clone(),
            current_route: route.clone(),
            run_result: RemoteData::NotAsked,
            language_version_result: RemoteData::Loading,
            snippet: None,
            search_modal_state: Default::default(),
            title_modal_state: Default::default(),
            sharing_modal_state: Default::default(),
            settings_modal_state: Default::default(),
            stdin_modal_state: Default::default(),
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
            editor_keyboard_bindings: Default::default(),
            editor_theme: Default::default(),
            stdin: snippet.stdin.to_string(),
            layout_state: app_layout::State::default(),
            current_url: self.current_url.clone(),
            current_route: route.clone(),
            run_result: RemoteData::NotAsked,
            language_version_result: RemoteData::Loading,
            snippet: Some(snippet_clone),
            search_modal_state: Default::default(),
            title_modal_state: Default::default(),
            sharing_modal_state: Default::default(),
            settings_modal_state: Default::default(),
            stdin_modal_state: Default::default(),
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
        let search_modal_subscriptions = search_modal::subscriptions(
            &model.user_agent,
            &model.search_modal_state,
            Msg::SearchModalMsg,
        );

        let app_layout_subscriptions =
            app_layout::subscriptions(&model.layout_state, Msg::AppLayoutMsg);

        let title_modal_subscriptions =
            title_modal::subscriptions(&model.title_modal_state, Msg::TitleModalMsg);

        let sharing_modal_subscriptions =
            sharing_modal::subscriptions(&model.sharing_modal_state, Msg::SharingModalMsg);

        let settings_modal_subscriptions =
            settings_modal::subscriptions(&model.settings_modal_state, Msg::SettingsModalMsg);

        let stdin_modal_subscriptions =
            stdin_modal::subscriptions(&model.stdin_modal_state, Msg::StdinModalMsg);

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
            event_listener::on_click_closest(Id::Run, Msg::RunClicked),
            event_listener::on_click_closest(Id::Share, Msg::ShareClicked),
            // Title
            event_listener::on_click_closest(Id::Title, Msg::EditTitleClicked),
            event_listener::on_click_closest(Id::TopBarTitle, Msg::EditTitleClicked),
            search_modal_subscriptions,
            app_layout_subscriptions,
            title_modal_subscriptions,
            sharing_modal_subscriptions,
            settings_modal_subscriptions,
            stdin_modal_subscriptions,
        ])
    }

    fn update(&self, msg: &Msg, model: &mut Model) -> Result<Effect<Msg, AppEffect>, String> {
        match msg {
            Msg::WindowSizeChanged(captured) => {
                let window_size = captured.value();

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

                let maybe_index = model
                    .files
                    .to_vec()
                    .iter()
                    .enumerate()
                    .find(|(_, file)| file.name == filename)
                    .map(|(index, _)| index);

                if let Some(index) = maybe_index {
                    model.files.select_index(index);
                }

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
                let effect = settings_modal::open(
                    &mut model.settings_modal_state,
                    &model.editor_keyboard_bindings,
                    &model.editor_theme,
                );

                Ok(effect)
            }

            Msg::ShowStdinModalClicked => {
                let effect = stdin_modal::open(&mut model.stdin_modal_state, &model.stdin);
                Ok(effect)
            }

            Msg::StdinModalMsg(child_msg) => {
                let event = stdin_modal::update(child_msg, &mut model.stdin_modal_state)?;

                match event {
                    stdin_modal::Event::StdinChanged(stdin) => {
                        model.stdin = stdin;
                        Ok(effect::none())
                    }
                    stdin_modal::Event::None => Ok(effect::none()),
                }
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

            Msg::SettingsModalMsg(child_msg) => {
                let event = settings_modal::update(child_msg, &mut model.settings_modal_state)?;

                match event {
                    settings_modal::Event::SettingsChanged(settings) => {
                        model.editor_keyboard_bindings = settings.keyboard_bindings;
                        model.editor_theme = settings.theme;
                    }

                    settings_modal::Event::None => {}
                }

                Ok(save_settings_effect(model))
            }

            Msg::GotSettings(captured) => {
                let maybe_settings = captured.value();

                if let Some(settings) = maybe_settings {
                    model.editor_keyboard_bindings = settings.editor_keyboard_bindings;
                    model.editor_theme = settings.editor_theme;
                }

                Ok(effect::none())
            }

            Msg::SavedSettings(_captured) => Ok(effect::none()),

            Msg::RunClicked => {
                let effect = run_effect(model);
                Ok(effect)
            }

            Msg::ShareClicked => {
                let effect =
                    sharing_modal::open(&mut model.sharing_modal_state, Msg::SharingModalMsg);
                Ok(effect)
            }

            Msg::EditTitleClicked => {
                let effect = title_modal::open(&mut model.title_modal_state, &model.title);
                Ok(effect)
            }

            Msg::SearchModalMsg(child_msg) => {
                let data: search_modal::UpdateData<Msg, AppEffect, QuickAction> =
                    search_modal::update(
                        child_msg,
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

            Msg::AppLayoutMsg(child_msg) => {
                app_layout::update(child_msg, &mut model.layout_state, Msg::AppLayoutMsg)
            }

            Msg::TitleModalMsg(child_msg) => {
                let event = title_modal::update(child_msg, &mut model.title_modal_state)?;

                match event {
                    title_modal::Event::TitleChanged(title) => {
                        model.title = title;
                        Ok(effect::none())
                    }

                    title_modal::Event::None => Ok(effect::none()),
                }
            }

            Msg::SharingModalMsg(child_msg) => {
                let context = sharing_modal::Context {
                    current_url: model.current_url.clone(),
                    language: model.language.id.clone(),
                    snippet: Snippet {
                        title: model.title.clone(),
                        files: model.files.to_vec(),
                        stdin: model.stdin.clone(),
                        language: model.language.id.to_string(),
                    },
                };

                let effect = sharing_modal::update(
                    child_msg,
                    &mut model.sharing_modal_state,
                    context,
                    Msg::SharingModalMsg,
                )?;
                Ok(effect)
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

fn validate_filename(files: &SelectList<File>, filename: &str, is_new: bool) -> Result<(), String> {
    let is_duplicate = files
        .to_vec()
        .iter()
        .map(|file| &file.name)
        .any(|name| name == filename);

    let is_duplicate_of_selected = filename == files.selected().name;

    if filename.is_empty() {
        Err("Filename cannot be empty".to_string())
    } else if (!is_duplicate_of_selected || is_new) && is_duplicate {
        Err("Filename is already used by another file".to_string())
    } else {
        Ok(())
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
    let modal_config = modal::Config {
        backdrop_id: Id::ModalBackdrop,
        close_button_id: Id::ModalClose,
    };

    html! {
        div id=(Id::Glot) .h-full {
            (app_layout::app_shell(
                view_content(model),
                Some(view_topbar_title(model)),
                &model.layout_state,
                &model.current_route,
            ))


            @match &model.active_modal {
                Modal::None => {},

                Modal::File(state) => {
                    (modal::view(view_file_modal(model, state), &modal_config))
                },
            }

            (title_modal::view(&model.title_modal_state))
            (search_modal::view(&model.user_agent, &model.search_modal_state))
            (sharing_modal::view(&model.sharing_modal_state))
            (settings_modal::view(&model.settings_modal_state))
            (stdin_modal::view(&model.stdin_modal_state))
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
                dd id=(Id::ShowStdinModal) class="h-full px-4 py-2 relative cursor-pointer stdin-preview" {
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
