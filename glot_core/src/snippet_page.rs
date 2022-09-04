use crate::icons::heroicons;
use crate::layout::app_layout;
use crate::util::select_list::SelectList;
use maud::html;
use maud::Markup;
use polyester::browser;
use polyester::browser::effect::dom;
use polyester::browser::DomId;
use polyester::browser::Effects;
use polyester::browser::ToDomId;
use polyester::browser::WindowSize;
use polyester::page::Page;
use polyester::page::PageMarkup;
use serde::{Deserialize, Serialize};
use std::cmp::max;

const MIN_EDITOR_HEIGHT: i64 = 300;

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    pub window_size: Option<WindowSize>,
    pub files: SelectList<File>,
    pub active_modal: Modal,
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct File {
    pub name: String,
    pub content: String,
}

impl Default for File {
    fn default() -> Self {
        Self {
            name: "untitled".to_string(),
            content: "".to_string(),
        }
    }
}

pub struct SnippetPage {
    pub window_size: Option<WindowSize>,
}

impl Page<Model, Msg, AppEffect, Markup> for SnippetPage {
    fn id(&self) -> DomId {
        DomId::new("glot")
    }

    fn init(&self) -> (Model, Effects<Msg, AppEffect>) {
        let file = File {
            name: "main.rs".to_string(),
            content: "Hello World!".to_string(),
        };

        let model = Model {
            window_size: self.window_size.clone(),
            files: SelectList::singleton(file),
            active_modal: Modal::None,
        };

        let effects = vec![];

        (model, effects)
    }

    fn subscriptions(&self, _model: &Model) -> browser::Subscriptions<Msg, AppEffect> {
        // TODO: add conditionals
        vec![
            browser::on_change_string(&Id::Editor, Msg::EditorContentChanged),
            browser::on_click_closest_data_string("filename", Msg::FileSelected),
            browser::on_click_closest(&Id::AddFile, Msg::AddFileClicked),
            browser::on_click_closest(&Id::CloseModal, Msg::CloseModalTriggered),
            browser::on_click(&Id::FileModalBackdrop, Msg::CloseModalTriggered),
            browser::on_click(&Id::FileModalCancel, Msg::CloseModalTriggered),
            browser::on_click(&Id::FileModalAdd, Msg::ConfirmAddFile),
            browser::on_click(&Id::FileModalUpdate, Msg::ConfirmUpdateFile),
            browser::on_click(&Id::FileModalDelete, Msg::ConfirmDeleteFile),
            browser::on_input(&Id::Filename, Msg::FilenameChanged),
            browser::on_click_closest(&Id::SelectedFile, Msg::EditFileClicked),
            browser::on_submit(&Id::NewFileForm, Msg::ConfirmAddFile),
            browser::on_submit(&Id::EditFileForm, Msg::ConfirmUpdateFile),
            browser::on_keyup_document(browser::Key::Escape, Msg::CloseModalTriggered),
            browser::on_window_resize(Msg::WindowSizeChanged),
        ]
    }

    fn update(&self, msg: &Msg, model: &mut Model) -> Result<Effects<Msg, AppEffect>, String> {
        match msg {
            Msg::WindowSizeChanged(value) => {
                let window_size = value
                    .parse()
                    .map_err(|err| format!("Failed to parse window size: {}", err))?;

                model.window_size = Some(window_size);
                browser::no_effects()
            }

            Msg::EditorContentChanged(content) => {
                model.files.update_selected(|file| {
                    file.content = content.clone();
                });

                Ok(vec![])
            }

            Msg::FileSelected(filename) => {
                model
                    .files
                    .to_vec()
                    .iter()
                    .enumerate()
                    .find(|(_, file)| &file.name == filename)
                    .map(|(index, _)| {
                        model.files.select_index(index);
                    });

                Ok(vec![])
            }

            Msg::AddFileClicked => {
                model.active_modal = Modal::File(FileState {
                    filename: "".to_string(),
                    is_new: true,
                    error: None,
                });

                Ok(vec![dom::focus_element(Id::Filename)])
            }

            Msg::FilenameChanged(filename) => {
                if let Modal::File(state) = &mut model.active_modal {
                    state.filename = filename.clone();
                    state.error = None;
                }

                Ok(vec![])
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
                        }

                        Err(err) => {
                            state.error = Some(err);
                        }
                    }
                }

                Ok(vec![])
            }

            Msg::ConfirmUpdateFile => {
                if let Modal::File(state) = &mut model.active_modal {
                    match validate_filename(&model.files, &state.filename, false) {
                        Ok(_) => {
                            model.files.update_selected(|file| {
                                file.name = state.filename.clone();
                            });

                            model.active_modal = Modal::None;
                        }

                        Err(err) => {
                            state.error = Some(err);
                        }
                    }
                }

                Ok(vec![])
            }

            Msg::ConfirmDeleteFile => {
                model.files.remove_selected();
                model.active_modal = Modal::None;
                Ok(vec![])
            }

            Msg::CloseModalTriggered => {
                model.active_modal = Modal::None;
                Ok(vec![])
            }

            Msg::EditFileClicked => {
                model.active_modal = Modal::File(FileState {
                    filename: model.files.selected().name.clone(),
                    is_new: false,
                    error: None,
                });

                Ok(vec![dom::select_input_text(Id::Filename)])
            }
        }
    }

    fn view(&self, model: &Model) -> PageMarkup<Markup> {
        PageMarkup {
            head: view_head(),
            body: view_body(&self.id(), model),
        }
    }

    fn render_partial(&self, markup: Markup) -> String {
        markup.into_string()
    }

    fn render_page(&self, markup: PageMarkup<Markup>) -> String {
        app_layout::render(markup)
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

#[derive(strum_macros::Display, polyester_macro::ToDomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
    Editor,
    AddFile,
    FileModalBackdrop,
    FileModalCancel,
    FileModalAdd,
    FileModalUpdate,
    FileModalDelete,
    Filename,
    NewFileForm,
    EditFileForm,
    SelectedFile,
    CloseModal,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub enum Msg {
    WindowSizeChanged(browser::Value),
    EditorContentChanged(String),
    FileSelected(String),
    AddFileClicked,
    CloseModalTriggered,
    ConfirmAddFile,
    ConfirmUpdateFile,
    ConfirmDeleteFile,
    FilenameChanged(String),
    EditFileClicked,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum AppEffect {}

fn view_head() -> maud::Markup {
    html! {
        title { "Snippet Page" }
        link id="app-styles" rel="stylesheet" href="/app.css";
        script defer nohash src="/vendor/ace/ace.js" {}
        script defer type="module" src="/snippet_page.js" {}
    }
}

fn view_body(page_id: &browser::DomId, model: &Model) -> maud::Markup {
    html! {
        div id=(page_id) class="h-full" {
            @match &model.window_size {
                Some(window_size) => {
                    (app_layout::app_shell(view_content(model, window_size)))
                }

                None => {
                    (app_layout::app_shell(view_spinner()))
                }
            }

            @match &model.active_modal {
                Modal::None => {},
                Modal::File(state) => {
                    (view_file_modal(model, state))
                },
            }
        }
    }
}

fn view_spinner() -> maud::Markup {
    html! {
        div class="spinner" {
            div class="rect1" {}
            div class="rect2" {}
            div class="rect3" {}
            div class="rect4" {}
            div class="rect5" {}
        }
    }
}

fn view_content(model: &Model, window_size: &WindowSize) -> Markup {
    let editor_height = max(i64::from(window_size.height) / 2, MIN_EDITOR_HEIGHT);
    let inline_styles = format!("height: {}px;", editor_height);
    let height = format!("{}px", editor_height);
    let content = model.files.selected().content;

    html! {
        div class="py-6 h-full flex flex-col" {
            div {
                div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8" {
                    h1 class="text-2xl font-semibold text-gray-900" {
                        "Untitled"
                    }
                }

                div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-8" {
                    div class="pt-3" {
                        div class="border border-gray-400 shadow" {
                            (view_tab_bar(model))

                            poly-ace-editor id=(Id::Editor)
                                style=(inline_styles)
                                class="block w-full text-base whitespace-pre font-mono"
                                stylesheet-id="app-styles"
                                height=(height)
                            {
                                (content)
                            }

                            (view_stdin_bar())
                            (view_action_bar())
                        }
                    }
                }
            }

            div class="overflow-hidden h-full w-full flex-1 max-w-7xl mx-auto px-4 sm:px-6 md:px-8" {
                div class="h-full pt-4" {
                    (view_output_panel())
                }
            }
        }
    }
}

fn view_output_panel() -> Markup {
    html! {
        div class="overflow-auto h-full border border-gray-400 shadow" {
            dl {
                // NOTE: first visible dt should not have top border
                dt class="px-4 py-1 border-t border-b border-gray-400 text-sm text-slate-700 font-bold bg-blue-400" {
                    pre { "INFO" }
                }
                dd class="px-4 py-2" {
                    pre {
                        "READY."
                    }
                }

                dt class="px-4 py-1 border-t border-b border-gray-400 text-sm text-slate-700 font-bold bg-green-400" {
                    pre { "STDOUT" }
                }
                dd class="px-4 py-2" {
                    pre {
                        "Hello World\n"
                        "Hello World\n"
                        "Hello World\n"
                        "Hello World\n"
                        "Hello World\n"
                        "Hello World\n"
                        "Hello World\n"
                        "Hello World\n"
                        "Hello World\n"
                        "Hello World\n"
                        "Hello World\n"
                    }
                }

                dt class="px-4 py-1 border-t border-b border-gray-400 text-sm text-slate-700 font-bold bg-yellow-400" {
                    pre { "STDERR" }
                }
                dd class="px-4 py-2"{
                    pre {
                        "err"
                    }
                }

                dt class="px-4 py-1 border-t border-b border-gray-400 text-sm text-slate-700 font-bold bg-red-400" {
                    pre { "ERROR" }
                }
                dd class="px-4 py-2" {
                    pre {
                        "Exit code: 1"
                    }
                }

            }
        }
    }
}

fn view_tab_bar(model: &Model) -> Markup {
    let files = model.files.to_vec();

    html! {
        div class="h-10 flex border-b border-gray-400" {
            button class="inline-flex items-center text-gray-500 hover:text-gray-700 px-3" type="button" {
                span class="w-6 h-6" {
                    (heroicons::cog_6_tooth())
                }
            }

            div class="flex" {
                @for file in &files {
                    (view_file_tab(model, file))
                }
            }

            button id=(Id::AddFile) class="inline-flex items-center text-gray-500 hover:text-gray-700 px-3 font-semibold text-sm border-l border-gray-400" type="button"{
                span class="w-5 h-5" {
                    (heroicons::document_plus())
                }
            }
        }
    }
}

fn view_file_tab(model: &Model, file: &File) -> Markup {
    let is_selected = model.files.selected().name == file.name;
    let id = is_selected.then_some(Id::SelectedFile);

    html! {
        button id=[id] data-filename=(file.name) .file .relative ."border-l" ."border-gray-400" ."cursor-pointer" ."inline-flex" ."items-center" ."justify-center" ."px-3" ."bg-indigo-100"[is_selected]  ."cursor-pointer" ."text-gray-500"[!is_selected] ."text-gray-800"[is_selected] ."hover:text-gray-800" ."text-sm" type="button" {
            span class {
                (file.name)
            }
            @if is_selected {
                span class="hidden edit-overlay absolute z-10 inset-0 w-full h-full bg-gray-500 bg-opacity-70" {
                    span class="absolute z-20 inset-0 m-auto w-5 h-5 text-slate-50" {
                        (heroicons::pencil_square_solid())
                    }
                }
            }
        }
    }
}

fn view_stdin_bar() -> Markup {
    html! {
        button class="flex justify-center h-10 w-full bg-white hover:bg-gray-50 text-gray-700 inline-flex items-center px-3 font-semibold text-sm border-t border-gray-400" type="button" {
            span class="w-5 h-5 mr-1" { (heroicons::plus_circle()) }
            span { "STDIN" }
        }
    }
}

fn view_action_bar() -> Markup {
    html! {
        div class="h-12 flex border-t border-gray-400" {
            button class="bg-white hover:bg-gray-50 text-gray-700 w-full inline-flex items-center justify-center px-3 py-1 font-semibold text-sm" type="button" {
                span class="w-5 h-5 mr-2" { (heroicons::play()) }
                span { "RUN" }
            }

            button class="bg-white hover:bg-gray-50 text-gray-700 w-full inline-flex items-center justify-center px-3 py-1 font-semibold text-sm border-l border-gray-400" type="button" {
                span class="w-5 h-5 mr-2" { (heroicons::cloud_arrow_up()) }
                span { "SAVE" }
            }

            button class="bg-white hover:bg-gray-50 text-gray-700 w-full inline-flex items-center justify-center px-3 py-1 font-semibold text-sm border-l border-gray-400" type="button" {
                span class="w-5 h-5 mr-2" { (heroicons::trash()) }
                span { "DELETE" }
            }

            button class="bg-white hover:bg-gray-50 text-gray-700 w-full inline-flex items-center justify-center px-3 py-1 font-semibold text-sm border-l border-gray-400" type="button" {
                span class="w-5 h-5 mr-2" { (heroicons::share()) }
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
        div class="relative z-10" aria-labelledby="modal-title" role="dialog" aria-modal="true" {
            div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" {}
            div class="fixed z-10 inset-0 overflow-y-auto" {
                div id=(Id::FileModalBackdrop) class="flex items-end sm:items-center justify-center min-h-full p-4 text-center sm:p-0" {
                    div class="relative bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:max-w-sm sm:w-full sm:p-6" {
                        div class="absolute top-0 right-0 hidden pt-4 pr-4 sm:block" {
                            button id=(Id::CloseModal) class="rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                                span class="sr-only" {
                                    "Close"
                                }
                                span class="block h-6 w-6" {
                                    (heroicons::x_mark())
                                }
                            }
                        }

                        div {
                            div class="text-center" {
                                h3 class="text-lg leading-6 font-medium text-gray-900" {
                                    @if state.is_new {
                                        "New File"
                                    } @else {
                                        "Edit File"
                                    }
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
                                            svg class="h-5 w-5 text-red-500" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true" {
                                                path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-5a.75.75 0 01.75.75v4.5a.75.75 0 01-1.5 0v-4.5A.75.75 0 0110 5zm0 10a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" {
                                                }
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
                                button id=(Id::FileModalAdd) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                                    "Add file"
                                }
                            } @else if files_count > 1 {
                                button id=(Id::FileModalDelete) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-red-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                                    "Delete file"
                                }

                                button id=(Id::FileModalUpdate) class="flex-1 w-full ml-4 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                                    "Update file"
                                }
                            } @else {
                                button id=(Id::FileModalUpdate) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                                    "Update file"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
