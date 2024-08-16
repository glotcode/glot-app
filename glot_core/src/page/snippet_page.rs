use crate::ace_editor::EditorKeyboardBindings;
use crate::ace_editor::EditorTheme;
use crate::common::browser_context::BrowserContext;
use crate::common::keyboard_shortcut::KeyboardShortcut;
use crate::common::route::Route;
use crate::components::file_modal;
use crate::components::search_modal;
use crate::components::settings_modal;
use crate::components::sharing_modal;
use crate::components::stdin_modal;
use crate::components::title_modal;
use crate::layout::app_layout;
use crate::run::FailedRunResult;
use crate::run::RunOutcome;
use crate::run::RunRequest;
use crate::run::RunRequestPayload;
use crate::run::RunResult;
use crate::snippet::File;
use crate::snippet::Snippet;
use crate::util::remote_data::RemoteData;
use crate::util::select_list::SelectList;
use glot_languages::language::Language;
use maud::html;
use maud::Markup;
use poly::browser::dom_id::DomId;
use poly::browser::effect;
use poly::browser::effect::console;
use poly::browser::effect::dom;
use poly::browser::effect::local_storage;
use poly::browser::effect::navigation;
use poly::browser::effect::session_storage;
use poly::browser::effect::Effect;
use poly::browser::selector::Selector;
use poly::browser::subscription;
use poly::browser::subscription::event_listener;
use poly::browser::subscription::Subscription;
use poly::browser::value::Capture;
use poly::browser::WindowSize;
use poly::page::JsMsg;
use poly::page::Page;
use poly::page::PageMarkup;
use quick_action::QuickAction;
use serde::{Deserialize, Serialize};
use std::cmp::max;
use url::Url;

pub mod output_panel;
pub mod quick_action;

const MIN_EDITOR_HEIGHT: u64 = 300;

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    pub browser_ctx: BrowserContext,
    pub language: Language,
    pub files: SelectList<File>,
    pub title: String,
    pub editor_keyboard_bindings: EditorKeyboardBindings,
    pub editor_theme: EditorTheme,
    pub stdin: String,
    pub layout_state: app_layout::State,
    pub run_result: RemoteData<FailedRunResult, RunResult>,
    pub language_version_result: RemoteData<FailedRunResult, RunResult>,
    pub snippet: Option<Snippet>,
    pub search_modal_state: search_modal::State<QuickAction>,
    pub title_modal_state: title_modal::State,
    pub sharing_modal_state: sharing_modal::State,
    pub settings_modal_state: settings_modal::State,
    pub stdin_modal_state: stdin_modal::State,
    pub file_modal_state: file_modal::State,
}

#[derive(strum_macros::Display, poly_macro::DomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
    Glot,
    Editor,
    SettingsButton,
    AddFileButton,
    EditFileButton,
    StdinButton,
    RunButton,
    ShareButton,
    Title,
    TopBarTitle,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub enum Msg {
    WindowSizeChanged(Capture<WindowSize>),
    EditorContentChanged(Capture<String>),
    RunClicked,

    // Title related
    EditTitleClicked,
    TitleModalMsg(title_modal::Msg),

    // Sharing related
    ShareClicked,
    SharingModalMsg(sharing_modal::Msg),

    // Settings related
    SettingsButtonClicked,
    SettingsModalMsg(settings_modal::Msg),
    GotSettings(Capture<Option<LocalStorageSettings>>),
    SavedSettings(Capture<bool>),

    // Session related
    GotSessionSnippet(Capture<Option<Snippet>>),
    SavedSessionSnippet(Capture<bool>),

    // Stdin related
    StdinButtonClicked,
    StdinModalMsg(stdin_modal::Msg),

    // File related
    FileSelected(Capture<String>),
    AddFileClicked,
    EditFileClicked,
    FileModalMsg(file_modal::Msg),

    // Search modal related
    SearchModalMsg(search_modal::Msg),

    // App layout related
    AppLayoutMsg(app_layout::Msg),
}

pub struct SnippetPage {
    pub browser_ctx: BrowserContext,
}

impl SnippetPage {
    fn get_model(&self) -> Result<Model, String> {
        let current_route = self.browser_ctx.current_route();

        match &current_route {
            Route::NewSnippet(language) => self.model_for_new_snippet(*language),

            Route::EditSnippet(language, encoded_snippet) => {
                self.model_for_existing_snippet(*language, encoded_snippet)
            }

            _ => Err("Invalid route".to_string()),
        }
    }

    fn model_for_new_snippet(&self, language: Language) -> Result<Model, String> {
        let editor_config = language.config().editor_config();

        let file = File {
            name: editor_config.default_filename,
            content: editor_config.example_code,
        };

        let title = "Hello World".to_string();

        Ok(Model {
            browser_ctx: self.browser_ctx.clone(),
            language,
            files: SelectList::singleton(file),
            title,
            editor_keyboard_bindings: Default::default(),
            editor_theme: Default::default(),
            stdin: "".to_string(),
            layout_state: app_layout::State::default(),
            run_result: RemoteData::NotAsked,
            language_version_result: RemoteData::Loading,
            snippet: None,
            search_modal_state: Default::default(),
            title_modal_state: Default::default(),
            sharing_modal_state: Default::default(),
            settings_modal_state: Default::default(),
            stdin_modal_state: Default::default(),
            file_modal_state: Default::default(),
        })
    }

    fn model_for_existing_snippet(
        &self,
        language: Language,
        encoded_snippet: &str,
    ) -> Result<Model, String> {
        let snippet = Snippet::from_encoded_string(encoded_snippet)
            .map_err(|err| format!("Failed to decode snippet: {}", err))?;

        let snippet_clone = snippet.clone();

        let editor_config = language.config().editor_config();

        let default_file = File {
            name: editor_config.default_filename,
            content: editor_config.example_code,
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
            browser_ctx: self.browser_ctx.clone(),
            language,
            files,
            title: snippet.title,
            editor_keyboard_bindings: Default::default(),
            editor_theme: Default::default(),
            stdin: snippet.stdin.to_string(),
            layout_state: app_layout::State::default(),
            run_result: RemoteData::NotAsked,
            language_version_result: RemoteData::Loading,
            snippet: Some(snippet_clone),
            search_modal_state: Default::default(),
            title_modal_state: Default::default(),
            sharing_modal_state: Default::default(),
            settings_modal_state: Default::default(),
            stdin_modal_state: Default::default(),
            file_modal_state: Default::default(),
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
            focus_editor_effect(),
            load_settings_effect(),
            load_session_snippet_effect(&model.browser_ctx.current_url),
            get_language_version_effect(model.language),
        ]);

        Ok((model, effect))
    }

    fn subscriptions(&self, model: &Model) -> Subscription<Msg, AppEffect> {
        let run_key_combo = KeyboardShortcut::RunCode.key_combo(&model.browser_ctx.user_agent);

        subscription::batch(vec![
            event_listener::on_change_string(Id::Editor, Msg::EditorContentChanged),
            event_listener::on_click_selector_closest(
                Selector::data("filename"),
                dom::get_target_data_string_value("filename"),
                Msg::FileSelected,
            ),
            event_listener::on_click_closest(Id::AddFileButton, Msg::AddFileClicked),
            event_listener::on_click_closest(Id::SettingsButton, Msg::SettingsButtonClicked),
            event_listener::on_click_closest(Id::StdinButton, Msg::StdinButtonClicked),
            event_listener::on_click_closest(Id::EditFileButton, Msg::EditFileClicked),
            event_listener::on_keydown(run_key_combo.key, run_key_combo.modifier, Msg::RunClicked),
            event_listener::on_window_resize(Msg::WindowSizeChanged),
            event_listener::on_click_closest(Id::RunButton, Msg::RunClicked),
            event_listener::on_click_closest(Id::ShareButton, Msg::ShareClicked),
            event_listener::on_click_closest(Id::Title, Msg::EditTitleClicked),
            event_listener::on_click_closest(Id::TopBarTitle, Msg::EditTitleClicked),
            search_modal::subscriptions(
                &model.browser_ctx.user_agent,
                &model.search_modal_state,
                Msg::SearchModalMsg,
            ),
            app_layout::subscriptions(&model.layout_state, Msg::AppLayoutMsg),
            title_modal::subscriptions(&model.title_modal_state, Msg::TitleModalMsg),
            sharing_modal::subscriptions(&model.sharing_modal_state, Msg::SharingModalMsg),
            settings_modal::subscriptions(&model.settings_modal_state, Msg::SettingsModalMsg),
            stdin_modal::subscriptions(&model.stdin_modal_state, Msg::StdinModalMsg),
            file_modal::subscriptions(&model.file_modal_state, Msg::FileModalMsg),
        ])
    }

    fn update(&self, msg: &Msg, model: &mut Model) -> Result<Effect<Msg, AppEffect>, String> {
        match msg {
            Msg::WindowSizeChanged(captured) => {
                let window_size = captured.value();

                model.browser_ctx.window_size = Some(window_size);
                Ok(effect::none())
            }

            Msg::EditorContentChanged(captured) => {
                model.files.update_selected(|file| {
                    file.content = captured.value();
                });

                Ok(save_session_snippet_effect(model))
            }

            Msg::StdinButtonClicked => Ok(open_stdin_modal(model)),

            Msg::StdinModalMsg(child_msg) => {
                let event = stdin_modal::update(child_msg, &mut model.stdin_modal_state)?;

                match event {
                    stdin_modal::Event::StdinChanged(stdin) => {
                        model.stdin = stdin;
                        Ok(effect::batch(vec![
                            save_session_snippet_effect(model),
                            focus_editor_effect(),
                        ]))
                    }
                    stdin_modal::Event::ModalClosed => Ok(focus_editor_effect()),
                    stdin_modal::Event::None => Ok(effect::none()),
                }
            }

            Msg::FileSelected(captured) => {
                let filename = captured.value();
                let effect = select_file(model, &filename);
                Ok(effect)
            }

            Msg::EditFileClicked => Ok(open_edit_file_modal(model)),

            Msg::AddFileClicked => Ok(open_add_file_modal(model)),

            Msg::FileModalMsg(child_msg) => {
                let event = file_modal::update(child_msg, &mut model.file_modal_state)?;

                match event {
                    file_modal::Event::FilenameChanged(filename) => {
                        model.files.update_selected(|file| {
                            file.name = filename.clone();
                        });

                        Ok(effect::batch(vec![
                            save_session_snippet_effect(model),
                            focus_editor_effect(),
                        ]))
                    }

                    file_modal::Event::FileAdded(filename) => {
                        model.files.push(File {
                            name: filename.clone(),
                            content: "".to_string(),
                        });

                        model.files.select_last();
                        Ok(effect::batch(vec![
                            save_session_snippet_effect(model),
                            focus_editor_effect(),
                        ]))
                    }

                    file_modal::Event::FileDeleted => {
                        model.files.remove_selected();
                        Ok(effect::batch(vec![
                            save_session_snippet_effect(model),
                            focus_editor_effect(),
                        ]))
                    }

                    file_modal::Event::ModalClosed => Ok(focus_editor_effect()),
                    file_modal::Event::None => Ok(effect::none()),
                }
            }

            Msg::SettingsButtonClicked => Ok(open_settings_modal(model)),
            Msg::SettingsModalMsg(child_msg) => {
                let event = settings_modal::update(child_msg, &mut model.settings_modal_state)?;

                match event {
                    settings_modal::Event::SettingsChanged(settings) => {
                        model.editor_keyboard_bindings = settings.keyboard_bindings;
                        model.editor_theme = settings.theme;
                        let effects =
                            effect::batch(vec![focus_editor_effect(), save_settings_effect(model)]);

                        Ok(effects)
                    }

                    settings_modal::Event::ModalClosed => Ok(focus_editor_effect()),
                    settings_modal::Event::None => Ok(effect::none()),
                }
            }

            Msg::GotSettings(captured) => {
                if let Some(settings) = captured.value() {
                    model.editor_keyboard_bindings = settings.editor_keyboard_bindings;
                    model.editor_theme = settings.editor_theme;
                }

                Ok(effect::none())
            }

            Msg::SavedSettings(_captured) => Ok(effect::none()),

            Msg::GotSessionSnippet(captured) => {
                if let Some(snippet) = captured.value() {
                    model.title = snippet.title;
                    model.stdin = snippet.stdin;

                    if let Some(files) = SelectList::from_vec(snippet.files) {
                        model.files = files
                    }
                }

                Ok(effect::none())
            }

            Msg::SavedSessionSnippet(_captured) => Ok(effect::none()),

            Msg::RunClicked => {
                let effect = run_effect(model);
                Ok(effect)
            }

            Msg::ShareClicked => Ok(open_sharing_modal(model)),

            Msg::EditTitleClicked => Ok(open_title_modal(model)),

            Msg::SearchModalMsg(child_msg) => {
                let files = model.files.to_vec();

                let data: search_modal::UpdateData<Msg, AppEffect, QuickAction> =
                    search_modal::update(
                        child_msg,
                        &mut model.search_modal_state,
                        quick_action::actions(files),
                        Msg::SearchModalMsg,
                    )?;

                let effect = if let Some(entry) = data.action {
                    match entry {
                        QuickAction::Run => run_effect(model),
                        QuickAction::EditTitle => open_title_modal(model),
                        QuickAction::EditFile => open_edit_file_modal(model),
                        QuickAction::EditStdin => open_stdin_modal(model),
                        QuickAction::AddFile => open_add_file_modal(model),
                        QuickAction::Share => open_sharing_modal(model),
                        QuickAction::Settings => open_settings_modal(model),
                        QuickAction::SelectFile(name) => select_file(model, &name),
                        QuickAction::GoToFrontPage => go_to_home(model),

                        QuickAction::GoToLanguage(action) => {
                            action.perform_action(&model.browser_ctx.current_url)
                        }
                    }
                } else {
                    effect::none()
                };

                Ok(effect::batch(vec![effect, data.effect]))
            }

            Msg::AppLayoutMsg(child_msg) => {
                let event = app_layout::update(child_msg, &mut model.layout_state)?;
                match event {
                    app_layout::Event::None => Ok(effect::none()),
                    app_layout::Event::OpenSearch => Ok(model.search_modal_state.open()),
                }
            }

            Msg::TitleModalMsg(child_msg) => {
                let event = title_modal::update(child_msg, &mut model.title_modal_state)?;

                match event {
                    title_modal::Event::TitleChanged(title) => {
                        model.title = title;

                        Ok(effect::batch(vec![
                            save_session_snippet_effect(model),
                            focus_editor_effect(),
                        ]))
                    }

                    title_modal::Event::ModalClosed => Ok(focus_editor_effect()),

                    title_modal::Event::None => Ok(effect::none()),
                }
            }

            Msg::SharingModalMsg(child_msg) => {
                let context = sharing_modal::Context {
                    current_url: model.browser_ctx.current_url.clone(),
                    language: model.language,
                    snippet: snippet_from_model(model),
                };

                let data = sharing_modal::update(
                    child_msg,
                    &mut model.sharing_modal_state,
                    context,
                    Msg::SharingModalMsg,
                )?;

                let effect = match data.event {
                    sharing_modal::Event::None => data.effect,
                    sharing_modal::Event::ModalClosed => {
                        effect::batch(vec![focus_editor_effect(), data.effect])
                    }
                };

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

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(tag = "type", content = "config")]
#[serde(rename_all = "camelCase")]
pub enum AppEffect {
    Run(RunRequest),
    GetLanguageVersion(RunRequest),
}

fn view_head(model: &Model) -> maud::Markup {
    let language_name = model.language.config().name();
    let description = format!("{} playground - glot.io", language_name);

    html! {
        title { (model.title) " - " (language_name) " snippet" }
        meta name="description" content=(description);
        meta name="viewport" content="width=device-width, initial-scale=1";
        link id="app-styles" rel="stylesheet" href="/static/app.css?hash=checksum";
        script defer src="/static/vendor/ace/ace.js?hash=checksum" {}
        script defer type="module" src="/sw.js?hash=checksum" {}
        script defer type="module" src="/static/app.js?hash=checksum" {}
    }
}

fn view_body(model: &Model) -> maud::Markup {
    html! {
        div id=(Id::Glot) .h-full {
            (app_layout::app_shell(
                view_content(model),
                Some(view_topbar_title(model)),
                &model.layout_state,
                &model.browser_ctx.current_route(),
            ))

            (title_modal::view(&model.title_modal_state))
            (search_modal::view(&model.browser_ctx.user_agent, &model.search_modal_state))
            (sharing_modal::view(&model.sharing_modal_state))
            (settings_modal::view(&model.settings_modal_state))
            (stdin_modal::view(&model.stdin_modal_state))
            (file_modal::view(&model.file_modal_state))
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
    let has_real_window_size = model.browser_ctx.window_size.is_some();
    let window_size = model.browser_ctx.window_size.clone().unwrap_or_default();
    let editor_height = calc_editor_height(&window_size);
    let inline_styles = format!("height: {}px;", editor_height);
    let height = format!("{}px", editor_height);
    let content = model.files.selected().content;
    let editor_config = model.language.config().editor_config();

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
                                mode=(editor_config.mode)
                                use-soft-tabs=(editor_config.use_soft_tabs)
                                tab-size=(editor_config.soft_tab_size)
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
                    (output_panel::view(output_panel::ViewModel {
                        run_result: &model.run_result,
                        version_result: &model.language_version_result,
                    }))
                }
            }
        }
    }
}

fn view_tab_bar(model: &Model) -> Markup {
    let files = model.files.to_vec();

    html! {
        div class="h-10 flex border-b border-gray-400" {
            button id=(Id::SettingsButton) class="inline-flex items-center text-gray-500 hover:text-gray-700 px-3" type="button" {
                span class="w-6 h-6" {
                    (heroicons_maud::cog_6_tooth_outline())
                }
            }

            div class="flex" {
                @for file in &files {
                    (view_file_tab(model, file))
                }
            }

            button id=(Id::AddFileButton) class="inline-flex items-center text-gray-500 hover:text-gray-700 px-3 font-semibold text-sm border-l border-gray-400" type="button"{
                span class="w-5 h-5" {
                    (heroicons_maud::document_plus_outline())
                }
            }
        }
    }
}

fn view_file_tab(model: &Model, file: &File) -> Markup {
    let is_selected = model.files.selected().name == file.name;
    let id = is_selected.then_some(Id::EditFileButton);

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
            button id=(Id::StdinButton) class="flex justify-center h-10 w-full bg-white hover:bg-gray-50 text-gray-700 inline-flex items-center px-3 font-semibold text-sm border-t border-gray-400" type="button" {
                span class="w-5 h-5 mr-1" { (heroicons_maud::pencil_square_outline()) }
                span { "STDIN" }
            }
        } @else {
            div class="w-full h-24 border-t border-gray-400 overflow-hidden" {
                dt class="px-4 py-1 border-b border-gray-400 text-sm text-slate-700 font-bold bg-blue-400" {
                    pre { "STDIN" }
                }
                dd id=(Id::StdinButton) class="h-full px-4 py-2 relative cursor-pointer stdin-preview" {
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
            button id=(Id::RunButton) class="bg-white hover:bg-gray-50 text-gray-700 w-full inline-flex items-center justify-center px-3 py-1 font-semibold text-sm" type="button" {
                span class="w-5 h-5 mr-2" { (heroicons_maud::play_outline()) }
                span { "RUN" }
            }

            button id=(Id::ShareButton) class="bg-white hover:bg-gray-50 text-gray-700 w-full inline-flex items-center justify-center px-3 py-1 font-semibold text-sm border-l border-gray-400" type="button" {
                span class="w-5 h-5 mr-2" { (heroicons_maud::share_outline()) }
                span { "SHARE" }
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

fn load_session_snippet_effect(url: &Url) -> Effect<Msg, AppEffect> {
    session_storage::get_item(url.path(), Msg::GotSessionSnippet)
}

fn save_session_snippet_effect(model: &Model) -> Effect<Msg, AppEffect> {
    let path = model.browser_ctx.current_url.path();
    let snippet = snippet_from_model(model);
    session_storage::set_item(path, snippet, Msg::SavedSessionSnippet)
}

fn get_language_version_effect(language: Language) -> Effect<Msg, AppEffect> {
    let run_config = language.config().run_config();

    let config = RunRequest {
        image: run_config.container_image,
        payload: RunRequestPayload {
            language,
            files: vec![],
            stdin: "".to_string(),
            command: Some(run_config.version_command),
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
    let run_config = model.language.config().run_config();

    let config = RunRequest {
        image: run_config.container_image.clone(),
        payload: RunRequestPayload {
            language: model.language,
            files: model.files.to_vec(),
            stdin: model.stdin.clone(),
            command: None,
        },
    };

    model.run_result = RemoteData::Loading;

    effect::app_effect(AppEffect::Run(config))
}

fn open_stdin_modal(model: &mut Model) -> Effect<Msg, AppEffect> {
    stdin_modal::open(&mut model.stdin_modal_state, &model.stdin)
}

fn open_sharing_modal(model: &mut Model) -> Effect<Msg, AppEffect> {
    sharing_modal::open(&mut model.sharing_modal_state, Msg::SharingModalMsg)
}

fn open_title_modal(model: &mut Model) -> Effect<Msg, AppEffect> {
    title_modal::open(&mut model.title_modal_state, &model.title)
}

fn open_settings_modal(model: &mut Model) -> Effect<Msg, AppEffect> {
    settings_modal::open(
        &mut model.settings_modal_state,
        &model.editor_keyboard_bindings,
        &model.editor_theme,
    )
}

fn open_edit_file_modal(model: &mut Model) -> Effect<Msg, AppEffect> {
    let current_filename = model.files.selected().name.clone();

    let existing_filenames = model
        .files
        .to_vec()
        .iter()
        .map(|file| file.name.clone())
        .filter(|name| name != &current_filename)
        .collect();

    file_modal::open_for_edit(
        &mut model.file_modal_state,
        file_modal::EditContext {
            filename: model.files.selected().name.clone(),
            language: model.language,
            existing_filenames,
        },
    )
}

fn open_add_file_modal(model: &mut Model) -> Effect<Msg, AppEffect> {
    let existing_filenames = model
        .files
        .to_vec()
        .iter()
        .map(|file| file.name.clone())
        .collect();

    file_modal::open_for_add(
        &mut model.file_modal_state,
        file_modal::AddContext {
            language: model.language,
            existing_filenames,
        },
    )
}

fn select_file(model: &mut Model, filename: &str) -> Effect<Msg, AppEffect> {
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

    focus_editor_effect()
}

fn go_to_home(model: &Model) -> Effect<Msg, AppEffect> {
    let route = Route::Home;
    let url = route.to_absolute_path(&model.browser_ctx.current_url);
    navigation::set_location(&url)
}

fn snippet_from_model(model: &Model) -> Snippet {
    Snippet {
        title: model.title.clone(),
        files: model.files.to_vec(),
        stdin: model.stdin.clone(),
        language: model.language,
    }
}
