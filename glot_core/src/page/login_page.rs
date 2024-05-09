use maud::html;
use maud::Markup;
use poly::browser;
use poly::browser::DomId;
use poly::browser::Effects;
use poly::page;
use poly::page::Page;
use poly::page::PageMarkup;
use serde::{Deserialize, Serialize};
use url::Url;

use crate::layout::app_layout;

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    pub window_size: Option<WindowSize>,
}

pub struct LoginPage {
    pub current_url: Url,
}

impl Page<Model, Msg, AppEffect, Markup> for LoginPage {
    fn id(&self) -> &'static dyn DomId {
        &Id::Glot
    }

    fn init(&self) -> Result<(Model, Effects<Msg, AppEffect>), String> {
        let model = Model { count: 0 };

        let effects = vec![];

        Ok((model, effects))
    }

    fn subscriptions(&self, _model: &Model) -> browser::Subscriptions<Msg, AppEffect> {
        vec![
            browser::on_click(Id::Increment, Msg::Increment),
            browser::on_click(Id::Decrement, Msg::Decrement),
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
    OpenSidebar,
    CloseSidebar,
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
        title { "Login Page" }
        meta name="viewport" content="width=device-width, initial-scale=1";
        link rel="stylesheet" href="/app.css";
        script defer type="module" src="/login_page.js" {}
    }
}

fn view_body(model: &Model) -> maud::Markup {
    let layout_config = app_layout::Config {
        open_sidebar_id: Id::OpenSidebar,
        close_sidebar_id: Id::CloseSidebar,
    };

    html! {
        div id=(Id::Glot) class="h-full" {
            @match &model.window_size {
                Some(window_size) => {
                    (app_layout::app_shell(
                        view_content(model),
                        None,
                        &layout_config,
                        &model.layout_state,
                        &model.current_route,
                    ))
                }

                None => {
                    (app_layout::app_shell(
                        view_spinner(),
                        None,
                        &layout_config,
                        &model.layout_state,
                        &model.current_route,
                    ))
                }
            }
        }
    }
}

fn view_content(model: &Model) -> maud::Markup {
    html! {
        div class="flex min-h-full flex-col justify-center py-12 sm:px-6 lg:px-8" {
            div class="sm:mx-auto sm:w-full sm:max-w-md" {
                img class="mx-auto h-10 w-auto" src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=600" alt="Your Company";
                h2 class="mt-6 text-center text-2xl font-bold leading-9 tracking-tight text-gray-900" {
                    "Sign in to your account"
                }
            }
            div class="mt-10 sm:mx-auto sm:w-full sm:max-w-[480px]" {
                div class="bg-white px-6 py-12 shadow sm:rounded-lg sm:px-12" {
                    form class="space-y-6" action="#" method="POST" {
                        div {
                            label class="block text-sm font-medium leading-6 text-gray-900" for="email" {
                                "Email address"
                            }
                            div class="mt-2" {
                                input id="email" class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6" name="email" type="email" autocomplete="email" required;
                            }
                        }
                        div {
                            button class="flex w-full justify-center rounded-md bg-indigo-600 px-3 py-1.5 text-sm font-semibold leading-6 text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600" type="submit" {
                                "Send magic link"
                            }
                        }
                    }
                }
            }
        }
    }
}
