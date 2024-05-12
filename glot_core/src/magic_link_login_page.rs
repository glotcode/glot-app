use maud::html;
use maud::Markup;
use poly::browser;
use poly::browser::effect;
use poly::browser::DomId;
use poly::browser::Effects;
use poly::page;
use poly::page::JsMsg;
use poly::page::Page;
use poly::page::PageMarkup;
use serde::{Deserialize, Serialize};
use url::Url;

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {}

pub struct MagicLinkLoginPage {
    pub current_url: Url,
}

impl Page<Model, Msg, AppEffect, Markup> for MagicLinkLoginPage {
    fn id(&self) -> &'static dyn DomId {
        &Id::Glot
    }

    fn init(&self) -> Result<(Model, Effects<Msg, AppEffect>), String> {
        let model = Model {};

        let maybe_token = self
            .current_url
            .query_pairs()
            .find(|(key, _)| key == "token")
            .map(|(_, value)| value);

        let effects = match maybe_token {
            Some(token) => {
                // fmt
                vec![effect::app_effect(AppEffect::Login(token.to_string()))]
            }
            None => {
                // fmt
                vec![]
            }
        };

        Ok((model, effects))
    }

    fn subscriptions(&self, _model: &Model) -> browser::Subscriptions<Msg, AppEffect> {
        vec![]
    }

    fn update(&self, msg: &Msg, model: &mut Model) -> Result<Effects<Msg, AppEffect>, String> {
        match msg {
            Msg::NoOp => {
                // fmt
                Ok(vec![])
            }
        }
    }

    fn update_from_js(
        &self,
        msg: JsMsg,
        model: &mut Model,
    ) -> Result<Effects<Msg, AppEffect>, String> {
        match msg.type_.as_ref() {
            "LoggedIn" => {
                // fmt
                let url_effect = browser::set_location("/");

                Ok(vec![url_effect])
            }

            _ => {
                let log_effect =
                    browser::console::log(&format!("Got unknown message from JS: {}", msg.type_));
                Ok(vec![log_effect])
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
        page::render_page_maud(markup)
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
    NoOp,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
#[serde(tag = "type", content = "config")]
pub enum AppEffect {
    Login(String),
}

fn view_head() -> maud::Markup {
    html! {
        title { "Magic Link Login Page" }
        meta name="viewport" content="width=device-width, initial-scale=1";
        link rel="stylesheet" href="/app.css";
        script defer type="module" src="/magic_link_login_page.js" {}
    }
}

fn view_body(model: &Model) -> maud::Markup {
    html! {
        div id=(Id::Glot) {
            div class="flex p-4" {
                h4 { "Logging in..." }
            }
        }
    }
}
