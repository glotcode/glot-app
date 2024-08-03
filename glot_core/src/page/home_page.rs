use crate::common::keyboard_shortcut::KeyboardShortcut;
use crate::common::quick_action;
use crate::common::quick_action::LanguageQuickAction;
use crate::common::route::Route;
use crate::components::search_modal;
use crate::language;
use crate::language::Language;
use crate::layout::app_layout;
use crate::util::user_agent::UserAgent;
use crate::view::features;
use crate::view::language_grid;
use maud::html;
use maud::Markup;
use poly::browser::dom_id::DomId;
use poly::browser::effect;
use poly::browser::effect::Effect;
use poly::browser::subscription;
use poly::browser::subscription::event_listener;
use poly::browser::subscription::Subscription;
use poly::page::Page;
use poly::page::PageMarkup;
use serde::{Deserialize, Serialize};
use url::Url;

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    pub current_route: Route,
    pub current_url: Url,
    pub user_agent: UserAgent,
    pub layout_state: app_layout::State,
    pub languages: Vec<language::Config>,
    pub search_modal_state: search_modal::State<LanguageQuickAction>,
}

pub struct HomePage {
    pub current_url: Url,
    pub user_agent: UserAgent,
}

impl Page<Model, Msg, AppEffect, Markup> for HomePage {
    fn id(&self) -> &'static dyn DomId {
        &Id::Glot
    }

    fn init(&self) -> Result<(Model, Effect<Msg, AppEffect>), String> {
        let languages: Vec<language::Config> = Language::list()
            .iter()
            .map(|language| language.config())
            .collect();

        let model = Model {
            layout_state: app_layout::State::default(),
            current_route: Route::from_path(self.current_url.path()),
            current_url: self.current_url.clone(),
            user_agent: self.user_agent.clone(),
            languages,
            search_modal_state: search_modal::State::default(),
        };

        Ok((model, effect::none()))
    }

    fn subscriptions(&self, model: &Model) -> Subscription<Msg, AppEffect> {
        let search_modal_subscriptions = search_modal::subscriptions(
            &model.user_agent,
            &model.search_modal_state,
            Msg::SearchModalMsg,
        );

        let app_layout_subscriptions =
            app_layout::subscriptions(&model.layout_state, Msg::AppLayoutMsg);

        subscription::batch(vec![
            event_listener::on_click_closest(Id::QuickActionButton, Msg::QuickActionButtonClicked),
            search_modal_subscriptions,
            app_layout_subscriptions,
        ])
    }

    fn update(&self, msg: &Msg, model: &mut Model) -> Result<Effect<Msg, AppEffect>, String> {
        match msg {
            Msg::QuickActionButtonClicked => {
                // fmt
                Ok(model.search_modal_state.open())
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
                    .map(|entry| entry.perform_action(&model.current_url))
                    .unwrap_or_else(effect::none);

                Ok(effect::batch(vec![effect, data.effect]))
            }

            Msg::AppLayoutMsg(child_msg) => {
                app_layout::update(child_msg, &mut model.layout_state, Msg::AppLayoutMsg)
            }
        }
    }

    fn view(&self, model: &Model) -> PageMarkup<Markup> {
        PageMarkup {
            head: view_head(model),
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
    QuickActionButton,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Msg {
    AppLayoutMsg(app_layout::Msg),
    // Search modal related
    QuickActionButtonClicked,
    SearchModalMsg(search_modal::Msg),
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum AppEffect {}

fn view_head(model: &Model) -> maud::Markup {
    let description = format!("glot.io is an open source code sandbox for running and sharing code snippets. Currently supports {} different programming languages.", model.languages.len());

    html! {
        title { "glot.io - code sandbox" }
        meta name="description" content=(description);
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

            (search_modal::view(&model.user_agent, &model.search_modal_state))
        }
    }
}

fn view_content(model: &Model) -> Markup {
    html! {
        div class="h-full flex flex-col bg-white" {
            div class="background-banner h-60 min-h-[15rem]" {
                div class="flex flex-col h-full items-center justify-center" {
                    img class="h-[100px]" src="/static/assets/logo-white.svg?hash=checksum" alt="glot.io logo" {}
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
                            description: "Snippets can be embedded into the URL so that they can be easily shared.",
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

            div class="pt-6 flex justify-center" {
                (view_search_button(model))
            }

            div class="pb-6" {
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

fn view_search_button(model: &Model) -> Markup {
    let key_combo = KeyboardShortcut::OpenQuickSearch.key_combo(&model.user_agent);

    html! {
        button id=(Id::QuickActionButton) class="hidden sm:flex items-center w-72 text-left space-x-3 px-4 h-12 bg-white ring-1 ring-slate-900/10 hover:ring-slate-300 focus:outline-none focus:ring-2 focus:ring-sky-500 shadow-sm rounded-lg text-slate-400" type="button" {
            span class="text-slate-300 w-6 h-6" {
                (heroicons_maud::magnifying_glass_outline())
            }
            span class="flex-auto" {
                "Quick action..."
            }
            kbd class="font-sans font-semibold dark:text-slate-500" {
                abbr class="no-underline text-slate-300 dark:text-slate-500" title="Command" {
                    (key_combo)
                }
            }
        }
    }
}

fn to_grid_language(language: &language::Config) -> language_grid::Language {
    language_grid::Language {
        name: language.name.clone(),
        icon_path: language.logo_svg_path.to_string(),
        route: Route::NewSnippet(language.id.clone()),
    }
}
