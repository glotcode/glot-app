use crate::common::route::Route;
use crate::layout::app_layout;
use maud::html;
use maud::Markup;
use poly::browser;
use poly::browser::effect;
use poly::browser::DomId;
use poly::browser::Effect;
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
            layout_state: app_layout::State::new(),
            current_route: Route::from_path(self.current_url.path()),
        };

        Ok((model, effect::none()))
    }

    fn subscriptions(&self, _model: &Model) -> browser::Subscriptions<Msg, AppEffect> {
        vec![
            browser::on_click_closest(Id::OpenSidebar, Msg::OpenSidebarClicked),
            browser::on_click_closest(Id::CloseSidebar, Msg::CloseSidebarClicked),
        ]
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
    OpenSidebar,
    CloseSidebar,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Msg {
    OpenSidebarClicked,
    CloseSidebarClicked,
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
    let layout_config = app_layout::Config {
        open_sidebar_id: Id::OpenSidebar,
        close_sidebar_id: Id::CloseSidebar,
    };

    html! {
        div id=(Id::Glot) class="h-full" {
            (app_layout::app_shell(
                view_content(model),
                None,
                &layout_config,
                &model.layout_state,
                &model.current_route,
            ))

        }
    }
}

fn view_content(model: &Model) -> Markup {
    html! {
        div class="h-full flex flex-col bg-white" {
            h1 class="text-lg h-full text-center mt-8" {
                "Page not found"
            }
        }
    }
}
