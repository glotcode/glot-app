use crate::common::route::Route;
use crate::layout::app_layout;
use crate::view::features;
use crate::view::language_grid;
use maud::html;
use maud::Markup;
use polyester::browser;
use polyester::browser::DomId;
use polyester::browser::Effects;
use polyester::page::Page;
use polyester::page::PageMarkup;
use serde::{Deserialize, Serialize};
use url::Url;

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    pub current_route: Route,
    pub layout_state: app_layout::State,
}

pub struct HomePage {
    pub current_url: Url,
}

impl Page<Model, Msg, AppEffect, Markup> for HomePage {
    fn id(&self) -> &'static dyn DomId {
        &Id::Glot
    }

    fn init(&self) -> (Model, Effects<Msg, AppEffect>) {
        let model = Model {
            layout_state: app_layout::State::new(),
            current_route: Route::Home,
        };

        let effects = vec![];

        (model, effects)
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

#[derive(strum_macros::Display, polyester_macro::DomId)]
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
        link rel="stylesheet" href="/app.css";
        script defer type="module" src="/home_page.js" {}
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
            div class="background-banner h-60" {
                div class="flex flex-col h-full items-center justify-center" {
                    img class="w-72" src="/assets/logo-white.svg" alt="glot.io logo" {}
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
                            description: "Support for over 40 languages. If your favorite language or library is missing you can open an issue or pull request on GitHub to get it added.",
                        },
                        features::Feature {
                            icon: heroicons_maud::share_outline(),
                            title: "Share snippets",
                            description: "Save your snippet to get a unique url you can share with your friends. As a registered user you can also edit your snippets.",
                        },
                        features::Feature {
                            icon: heroicons_maud::key_outline(),
                            title: "Key bindings",
                            description: "The code editor supports Vim and Emacs key bindings.",
                        },
                        features::Feature {
                            icon: heroicons_maud::globe_alt_outline(),
                            title: "Open source",
                            description: "Everything is open souce. Including the code for this page and the service that runs the code.",
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
                        (language_grid::view(&[
                            language_grid::Language{
                                name: "Assembly",
                                icon_path: "/assets/language/generic.svg",
                                route: Route::NewSnippetEditor("assembly".to_string()),
                            },
                            language_grid::Language{
                                name: "ATS",
                                icon_path: "/assets/language/ats.svg",
                                route: Route::NewSnippetEditor("ats".to_string()),
                            },
                            language_grid::Language{
                                name: "Bash",
                                icon_path: "/assets/language/bash.svg",
                                route: Route::NewSnippetEditor("bash".to_string()),
                            },
                            language_grid::Language{
                                name: "C",
                                icon_path: "/assets/language/c.svg",
                                route: Route::NewSnippetEditor("c".to_string()),
                            },
                            language_grid::Language{
                                name: "Clojure",
                                icon_path: "/assets/language/clojure.svg",
                                route: Route::NewSnippetEditor("clojure".to_string()),
                            },
                            language_grid::Language{
                                name: "Cobol",
                                icon_path: "/assets/language/generic.svg",
                                route: Route::NewSnippetEditor("cobol".to_string()),
                            },
                            language_grid::Language{
                                name: "CoffeeScript",
                                icon_path: "/assets/language/coffeescript.svg",
                                route: Route::NewSnippetEditor("coffeescript".to_string()),
                            },
                            language_grid::Language{
                                name: "C++",
                                icon_path: "/assets/language/cpp.svg",
                                route: Route::NewSnippetEditor("cpp".to_string()),
                            },
                            language_grid::Language{
                                name: "Crystal",
                                icon_path: "/assets/language/crystal.svg",
                                route: Route::NewSnippetEditor("crystal".to_string()),
                            },
                            language_grid::Language{
                                name: "D",
                                icon_path: "/assets/language/d.svg",
                                route: Route::NewSnippetEditor("d".to_string()),
                            },
                            language_grid::Language{
                                name: "Rust",
                                icon_path: "/assets/language/rust.svg",
                                route: Route::NewSnippetEditor("rust".to_string()),
                            }
                        ]))
                    }
                }
            }
        }
    }
}
