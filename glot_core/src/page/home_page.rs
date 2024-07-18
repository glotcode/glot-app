use crate::common::route::Route;
use crate::language;
use crate::language::Language;
use crate::layout::app_layout;
use crate::view::features;
use crate::view::language_grid;
use maud::html;
use maud::Markup;
use poly::browser;
use poly::browser::DomId;
use poly::browser::Effects;
use poly::page::Page;
use poly::page::PageMarkup;
use serde::{Deserialize, Serialize};
use url::Url;

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    pub current_route: Route,
    pub layout_state: app_layout::State,
    pub languages: Vec<language::Config>,
}

pub struct HomePage {
    pub current_url: Url,
}

impl Page<Model, Msg, AppEffect, Markup> for HomePage {
    fn id(&self) -> &'static dyn DomId {
        &Id::Glot
    }

    fn init(&self) -> Result<(Model, Effects<Msg, AppEffect>), String> {
        let languages: Vec<language::Config> = Language::list()
            .iter()
            .map(|language| language.config())
            .collect();

        let model = Model {
            layout_state: app_layout::State::new(),
            current_route: Route::Home,
            languages,
        };

        let effects = vec![];

        Ok((model, effects))
    }

    fn subscriptions(&self, _model: &Model) -> browser::Subscriptions<Msg, AppEffect> {
        vec![
            browser::on_click_closest(Id::OpenSidebar, Msg::OpenSidebarClicked),
            browser::on_click_closest(Id::CloseSidebar, Msg::CloseSidebarClicked),
        ]
    }

    fn update(&self, msg: &Msg, model: &mut Model) -> Result<Effects<Msg, AppEffect>, String> {
        match msg {
            Msg::OpenSidebarClicked => {
                model.layout_state.open_sidebar();
                Ok(vec![])
            }

            Msg::CloseSidebarClicked => {
                model.layout_state.close_sidebar();
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
        title { "Home Page" }
        meta name="viewport" content="width=device-width, initial-scale=1";
        link rel="stylesheet" href="/static/app.css";
        link rel="preload" href="/wasm/glot_bg.wasm" as="fetch" crossorigin="anonymous";
        script defer type="module" src="/static/app.js" {}
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
            div class="background-banner h-60 min-h-[15rem]" {
                div class="flex flex-col h-full items-center justify-center" {
                    img class="h-[100px]" src="/static/assets/logo-white.svg" alt="glot.io logo" {}
                    p class="mt-4 text-white text-2xl" {
                        span { "an " }
                        a href="https://github.com/glotcode/glot" class="underline hover:no-underline text-gray-200 hover:text-gray-400 visited:text-purple-400" {
                            "open source"
                        }
                        span { " code sandbox." }
                    }
                }
            }

            div {
                (features::view(&features::Config{
                    title: "Features",
                    features: &[
                        features::Feature {
                            icon: heroicons_maud::play_outline(),
                            title: "Run code",
                            description: &format!("Support for {} different languages. The code is executed in a transient docker container without network.", model.languages.len()),
                        },
                        features::Feature {
                            icon: heroicons_maud::share_outline(),
                            title: "Share snippets",
                            description: "The code will be encoded in the URL so you can easily share it with others.",
                        },
                        features::Feature {
                            icon: heroicons_maud::cog_6_tooth_outline(),
                            title: "Key bindings",
                            description: "The editor supports Vim and Emacs key bindings.",
                        },
                        features::Feature {
                            icon: heroicons_maud::globe_alt_outline(),
                            title: "Open source",
                            description: "If your favorite language or library is missing you can open an issue or pull request on GitHub to get it added.",
                        },
                    ],
                }))
            }

            div class="py-6" {
                div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8" {
                    div class="border-b border-gray-200 pb-5 mt-8" {
                        h3 class="text-lg font-medium leading-6 text-gray-900" {
                            "Languages"
                        }
                    }

                    div class="mt-4" {
                        (language_grid::view(model.languages.iter().map(to_grid_language).collect::<Vec<_>>()))
                    }
                }
            }
        }
    }
}

fn to_grid_language(language: &language::Config) -> language_grid::Language {
    language_grid::Language {
        name: language.name.clone(),
        icon_path: language.svg_icon_path(),
        route: Route::NewSnippet(language.id.clone()),
    }
}
