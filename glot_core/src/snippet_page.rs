use crate::layout::app_layout;
use maud::html;
use maud::Markup;
use polyester::browser;
use polyester::browser::DomId;
use polyester::browser::Effects;
use polyester::browser::ToDomId;
use polyester::page::Page;
use polyester::page::PageMarkup;
use serde::{Deserialize, Serialize};
use std::cmp::max;

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    pub editorContent: [String; 10],
    pub count: isize,
}

pub struct SnippetPage {}

impl Page<Model, Msg, AppEffect, Markup> for SnippetPage {
    fn id(&self) -> DomId {
        DomId::new("glot")
    }

    fn init(&self) -> (Model, Effects<Msg, AppEffect>) {
        let model = Model {
            count: 0,
            editorContent: Default::default(),
        };

        let effects = vec![];

        (model, effects)
    }

    fn subscriptions(&self, _model: &Model) -> browser::Subscriptions<Msg, AppEffect> {
        vec![
            browser::on_click(&Id::Increment, Msg::Increment),
            browser::on_click(&Id::Decrement, Msg::Decrement),
        ]
    }

    fn update(&self, msg: &Msg, model: &mut Model) -> Result<Effects<Msg, AppEffect>, String> {
        match msg {
            Msg::Increment => {
                model.count += 1;
                Ok(vec![])
            }

            Msg::Decrement => {
                model.count -= 1;
                Ok(vec![])
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

#[derive(strum_macros::Display, polyester_macro::ToDomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
    Editor,
    Increment,
    Decrement,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Msg {
    Increment,
    Decrement,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum AppEffect {}

fn view_head() -> maud::Markup {
    html! {
        title { "Snippet Page" }
        link rel="stylesheet" href="/app.css";
        script defer nohash src="/vendor/ace/ace.js" {}
        script defer type="module" src="/snippet_page.js" {}
    }
}

fn view_body(page_id: &browser::DomId, model: &Model) -> maud::Markup {
    html! {
        div id=(page_id) {
            (app_layout::app_shell(view_content(model)))
        }
    }
}

fn view_content(model: &Model) -> Markup {
    let window_size_height = 600;
    let editor_height = max(i64::from(window_size_height) - 96, 500);
    let editor_style = format!("height: {}px;", editor_height);

    html! {
        div class="py-6" {
            div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8" {
                h1 class="text-2xl font-semibold text-gray-900" {
                    "Untitled"
                }
            }

            div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-8" {
                div class="pt-4" {
                    (view_editor_tabs())
                }
            }

            div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-8" {
                div class="pt-3" {
                    div class="editor-container" style=(editor_style) {
                        div #(editor_id(0)) class="editor border border-gray-400 shadow" unmanaged { (model.editorContent[0]) }
                    }
                }
            }
        }
    }
}

fn view_editor_tabs() -> Markup {
    html! {
        div class="flex border border-gray-400 shadow" {
            a class="inline-flex items-center text-gray-500 hover:text-gray-700 px-3 py-1 font-medium text-sm" href="#" {
                span class="w-6 h-6" {
                    (view_cog_6_tooth())
                }
            }

            nav class="flex" aria-label="Tabs" {
                a class="inline-flex items-center text-gray-500 hover:text-gray-700 px-3 py-1 font-medium text-sm border-l border-gray-400" href="#" {
                    span { "main.rs" }
                    span class="w-4 h-4 ml-2 hover:text-emerald-500" { (view_pencil_square()) }
                }
                a class="inline-flex items-center text-gray-500 hover:text-gray-700 px-3 py-1 font-medium text-sm border-l border-gray-400" href="#" {
                    span { "foo.rs" }
                    span class="w-5 h-5 ml-2 hover:text-red-400" { (view_x_circle()) }
                }
                a class="inline-flex items-center text-gray-500 hover:text-gray-700 px-3 py-1 font-medium text-sm border-l border-gray-400" href="#" {
                    span { "bar.rs" }
                    span class="w-5 h-5 ml-2 hover:text-red-400" { (view_x_circle()) }
                }
                span class="border-l border-gray-400" { }
            }
        }
    }
}

fn view_pencil_square() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" {
            path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10" {
            }
        }
    }
}

fn view_cog_6_tooth() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" {
            path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z" {
            }
            path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" {
            }
        }
    }
}

fn view_x_circle() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" {
            path stroke-linecap="round" stroke-linejoin="round" d="M9.75 9.75l4.5 4.5m0-4.5l-4.5 4.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z" {
            }
        }
    }
}

fn view_x_mark() -> Markup {
    html! {
        svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" {
            path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" {
            }
        }
    }
}

fn editor_id(n: u8) -> DomId {
    DomId::new(&format!("{}-{}", Id::Editor, n))
}
