use crate::common::browser_context::BrowserContext;
use crate::common::quick_action;
use crate::common::quick_action::LanguageQuickAction;
use crate::common::route::Route;
use crate::components::search_modal;
use crate::layout::app_layout;
use maud::html;
use maud::Markup;
use poly::browser::dom_id::DomId;
use poly::browser::effect;
use poly::browser::effect::Effect;
use poly::browser::subscription;
use poly::browser::subscription::Subscription;
use poly::page::Page;
use poly::page::PageMarkup;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    pub browser_ctx: BrowserContext,
    pub layout_state: app_layout::State,
    pub search_modal_state: search_modal::State<LanguageQuickAction>,
}

pub struct NotFoundPage {
    pub browser_ctx: BrowserContext,
}

impl Page<Model, Msg, AppEffect, Markup> for NotFoundPage {
    fn id(&self) -> &'static dyn DomId {
        &Id::Glot
    }

    fn init(&self) -> Result<(Model, Effect<Msg, AppEffect>), String> {
        let model = Model {
            browser_ctx: self.browser_ctx.clone(),
            layout_state: Default::default(),
            search_modal_state: Default::default(),
        };

        Ok((model, effect::none()))
    }

    fn subscriptions(&self, model: &Model) -> Subscription<Msg, AppEffect> {
        subscription::batch(vec![
            app_layout::subscriptions(&model.layout_state, Msg::AppLayoutMsg),
            search_modal::subscriptions(
                &model.browser_ctx.user_agent,
                &model.search_modal_state,
                Msg::SearchModalMsg,
            ),
        ])
    }

    fn update(&self, msg: &Msg, model: &mut Model) -> Result<Effect<Msg, AppEffect>, String> {
        match msg {
            Msg::AppLayoutMsg(child_msg) => {
                let event = app_layout::update(child_msg, &mut model.layout_state)?;
                match event {
                    app_layout::Event::None => Ok(effect::none()),
                    app_layout::Event::OpenSearch => Ok(model.search_modal_state.open()),
                }
            }

            Msg::SearchModalMsg(child_msg) => {
                let data: search_modal::UpdateData<Msg, AppEffect, LanguageQuickAction> =
                    search_modal::update(
                        child_msg,
                        &mut model.search_modal_state,
                        quick_action::language_entries(),
                        Msg::SearchModalMsg,
                    )?;

                let effect = data
                    .action
                    .map(|entry| entry.perform_action(&model.browser_ctx.current_url))
                    .unwrap_or_else(effect::none);

                Ok(effect::batch(vec![effect, data.effect]))
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
    SearchModalMsg(search_modal::Msg),
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
                &model.browser_ctx.current_route(),
            ))

            div class="search-wrapper" {
                (search_modal::view(&model.browser_ctx.user_agent, &model.search_modal_state))
            }
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
