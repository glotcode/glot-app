use std::fmt;

use crate::common::keyboard_shortcut::KeyboardShortcut;
use crate::common::route::Route;
use crate::components::search_modal;
use crate::language;
use crate::language::d;
use crate::language::Language;
use crate::layout::app_layout;
use crate::util::user_agent::UserAgent;
use crate::view::features;
use crate::view::language_grid;
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
    pub current_url: Url,
    pub user_agent: UserAgent,
    pub layout_state: app_layout::State,
    pub languages: Vec<language::Config>,
    pub search_modal_state: search_modal::State<QuickAction>,
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
            layout_state: app_layout::State::new(),
            current_route: Route::from_path(self.current_url.path()),
            current_url: self.current_url.clone(),
            user_agent: self.user_agent.clone(),
            languages,
            search_modal_state: search_modal::State::default(),
        };

        Ok((model, effect::none()))
    }

    fn subscriptions(&self, model: &Model) -> browser::Subscriptions<Msg, AppEffect> {
        let search_modal_subscriptions: Vec<browser::Subscription<Msg, AppEffect>> =
            search_modal::subscriptions(
                &model.user_agent,
                &model.search_modal_state,
                Msg::SearchModalMsg,
            );

        let mut subscriptions = vec![
            browser::on_click_closest(Id::OpenSidebar, Msg::OpenSidebarClicked),
            browser::on_click_closest(Id::CloseSidebar, Msg::CloseSidebarClicked),
            browser::on_click_closest(Id::QuickActionButton, Msg::QuickActionButtonClicked),
        ];

        subscriptions.extend(search_modal_subscriptions);

        subscriptions
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

            Msg::QuickActionButtonClicked => {
                // fmt
                Ok(model.search_modal_state.open())
            }

            Msg::SearchModalMsg(child_msg) => {
                let data: search_modal::UpdateData<Msg, AppEffect, QuickAction> =
                    search_modal::update(
                        &child_msg,
                        &mut model.search_modal_state,
                        quick_actions(),
                        Msg::SearchModalMsg,
                    )?;

                let effect = if let Some(entry) = data.selected_entry {
                    match entry {
                        QuickAction::GoToLanguage(language) => {
                            let route = Route::NewSnippet(language);
                            let url = route.to_absolute_path(&model.current_url);
                            browser::effect::navigation::set_location(&url)
                        }
                    }
                } else {
                    effect::none()
                };

                Ok(effect::batch(vec![effect, data.effect]))
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
    OpenSidebar,
    CloseSidebar,
    QuickActionButton,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Msg {
    OpenSidebarClicked,
    CloseSidebarClicked,
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

#[derive(Clone, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum QuickAction {
    GoToLanguage(Language),
}

impl search_modal::EntryExtra for QuickAction {
    fn title(&self) -> String {
        match self {
            QuickAction::GoToLanguage(language) => format!("Go to {}", language.config().name),
        }
    }

    fn keywords(&self) -> Vec<String> {
        match self {
            QuickAction::GoToLanguage(language) => {
                vec![language.to_string(), language.config().name.clone()]
            }
        }
    }

    fn icon(&self) -> maud::Markup {
        match self {
            QuickAction::GoToLanguage(_) => heroicons_maud::link_outline(),
        }
    }
}

impl fmt::Display for QuickAction {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            QuickAction::GoToLanguage(language) => write!(f, "goto-{}", language),
        }
    }
}

fn quick_actions() -> Vec<search_modal::Entry<QuickAction>> {
    Language::list()
        .iter()
        .map(|language| search_modal::Entry::new(QuickAction::GoToLanguage(language.clone())))
        .collect()
}
