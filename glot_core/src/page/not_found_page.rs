use crate::common::route::Route;
use crate::layout::app_layout;
use maud::html;
use maud::Markup;
use poly::browser::dom_id::DomId;
use poly::browser::effect;
use poly::browser::effect::Effect;
use poly::browser::subscription::Subscription;
use poly::page::Page;
use poly::page::PageMarkup;
use serde::{Deserialize, Serialize};
use url::Url;

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    pub current_route: Route,
    pub layout_state: app_layout::State,
}

pub struct NotFoundPage {
    pub current_url: Url,
}

impl Page<Model, Msg, AppEffect, Markup> for NotFoundPage {
    fn id(&self) -> &'static dyn DomId {
        &Id::Glot
    }

    fn init(&self) -> Result<(Model, Effect<Msg, AppEffect>), String> {
        let model = Model {
            layout_state: app_layout::State::default(),
            current_route: Route::from_path(self.current_url.path()),
        };

        Ok((model, effect::none()))
    }

    fn subscriptions(&self, model: &Model) -> Subscription<Msg, AppEffect> {
        app_layout::subscriptions(&model.layout_state, Msg::AppLayoutMsg)
    }

    fn update(&self, msg: &Msg, model: &mut Model) -> Result<Effect<Msg, AppEffect>, String> {
        match msg {
            Msg::AppLayoutMsg(child_msg) => {
                app_layout::update(child_msg, &mut model.layout_state, Msg::AppLayoutMsg)
            }
        }
    }

    fn view(&self, model: &Model) -> PageMarkup<Markup> {
        PageMarkup {
            head: view_head(),
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

#[derive(strum_macros::Display, poly_macro::DomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
    Glot,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Msg {
    AppLayoutMsg(app_layout::Msg),
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum AppEffect {}

fn view_head() -> maud::Markup {
    html! {
        title { "Page not found" }
        meta name="viewport" content="width=device-width, initial-scale=1";
        link rel="stylesheet" href="/static/app.css?hash=checksum";
        script defer type="module" src="/sw.js?hash=checksum" {}
        script defer type="module" src="/static/app.js?hash=checksum" {}
    }
}

fn view_body(model: &Model) -> maud::Markup {
    html! {
        div id=(Id::Glot) class="h-full" {
            (app_layout::app_shell(
                view_content(model),
                None,
                &model.layout_state,
                &model.current_route,
            ))

        }
    }
}

fn view_content(_model: &Model) -> Markup {
    html! {
        div class="h-full flex flex-col bg-white" {
            h1 class="text-lg h-full text-center mt-8" {
                "Page not found"
            }
        }
    }
}
