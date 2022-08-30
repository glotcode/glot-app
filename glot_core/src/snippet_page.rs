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
                    "Dashboard"
                }
            }
            div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-8" {
                div class="py-4" {
                    div class="editor-container" style=(editor_style) {
                        div #(editor_id(0)) class="editor border border-gray-400 shadow" unmanaged { (model.editorContent[0]) }
                    }
                }
            }
        }
    }
}

fn editor_id(n: u8) -> DomId {
    DomId::new(&format!("{}-{}", Id::Editor, n))
}
