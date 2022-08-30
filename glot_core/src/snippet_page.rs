use crate::layout::app_layout;
use maud::html;
use maud::Markup;
use polyester::browser;
use polyester::browser::DomId;
use polyester::browser::Effects;
use polyester::browser::ToDomId;
use polyester::page;
use polyester::page::Page;
use polyester::page::PageMarkup;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    pub count: isize,
}

pub struct SnippetPage {}

impl Page<Model, Msg, AppEffect, Markup> for SnippetPage {
    fn id(&self) -> DomId {
        DomId::new("glot")
    }

    fn init(&self) -> (Model, Effects<Msg, AppEffect>) {
        let model = Model { count: 0 };

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
    html! {
        div class="py-6" {
            div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8" {
                h1 class="text-2xl font-semibold text-gray-900" {
                    "Dashboard"
                }
            }
            div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-8" {
                div class="py-4" {
                    div class="border-4 border-dashed border-gray-200 rounded-lg h-96" {
                    }
                }
            }
        }

    }
}
