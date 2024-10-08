use crate::common::route::Route;
use crate::view::svg;
use maud::html;
use maud::Markup;
use poly::browser::dom_id::DomId;
use poly::browser::subscription;
use poly::browser::subscription::event_listener;
use poly::browser::subscription::Subscription;
use poly::page::PageMarkup;
use serde::{Deserialize, Serialize};

pub fn render_page(markup: PageMarkup<Markup>) -> String {
    (html! {
        (maud::DOCTYPE)
        html class="h-full bg-white" {
            head {
                meta charset="utf-8";
                (markup.head)
            }
            body class="h-full" {
                (markup.body)
            }
        }
    })
    .into_string()
}

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub enum State {
    #[default]
    Closed,
    Open,
}

#[derive(strum_macros::Display, poly_macro::DomId)]
#[strum(serialize_all = "kebab-case")]
pub enum Id {
    OpenSidebar,
    CloseSidebar,
    SidebarSearch,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Msg {
    OpenSidebarClicked,
    CloseSidebarClicked,
    SidebarSearchClicked,
}

pub fn subscriptions<ToParentMsg, ParentMsg>(
    state: &State,
    to_parent_msg: ToParentMsg,
) -> Subscription<ParentMsg>
where
    ToParentMsg: Fn(Msg) -> ParentMsg,
{
    let search_listener = event_listener::on_click_closest(
        Id::SidebarSearch,
        to_parent_msg(Msg::SidebarSearchClicked),
    );

    match state {
        State::Open => subscription::batch(vec![
            event_listener::on_click_closest(
                Id::CloseSidebar,
                to_parent_msg(Msg::CloseSidebarClicked),
            ),
            search_listener,
        ]),

        State::Closed => subscription::batch(vec![
            event_listener::on_click_closest(
                Id::OpenSidebar,
                to_parent_msg(Msg::OpenSidebarClicked),
            ),
            search_listener,
        ]),
    }
}

pub enum Event {
    None,
    OpenSearch,
}

pub fn update(msg: &Msg, state: &mut State) -> Result<Event, String> {
    match msg {
        Msg::OpenSidebarClicked => {
            *state = State::Open;
            Ok(Event::None)
        }

        Msg::CloseSidebarClicked => {
            *state = State::Closed;
            Ok(Event::None)
        }

        Msg::SidebarSearchClicked => {
            *state = State::Closed;
            Ok(Event::OpenSearch)
        }
    }
}

pub enum ItemType {
    Route(Route),
    Button(Id),
}

pub struct SidebarItem {
    pub label: String,
    pub icon: Markup,
    pub type_: ItemType,
}

impl SidebarItem {
    fn view(&self, current_route: &Route) -> Markup {
        match &self.type_ {
            ItemType::Route(route) => self.view_route(route, current_route),
            ItemType::Button(id) => self.view_button(id),
        }
    }

    fn view_route(&self, route: &Route, current_route: &Route) -> Markup {
        html! {
            @if route.name() == current_route.name() {
                a href=(route.to_path()) class="bg-gray-900 text-white group flex items-center px-2 py-2 text-base font-medium rounded-md" {
                    span class="flex text-gray-300 mr-4 flex-shrink-0 h-6 w-6" {
                        (self.icon)
                    }
                    (self.label)
                }
            } @else {
                a href=(route.to_path()) class="text-gray-300 hover:bg-gray-700 hover:text-white group flex items-center px-2 py-2 text-base font-medium rounded-md" {
                    span class="flex text-gray-400 group-hover:text-gray-300 mr-4 flex-shrink-0 h-6 w-6" {
                        (self.icon)
                    }
                    (self.label)
                }
            }
        }
    }

    fn view_button(&self, id: &Id) -> Markup {
        html! {
            button id=(id) class="w-full text-gray-300 hover:bg-gray-700 hover:text-white group flex items-center px-2 py-2 text-base font-medium rounded-md" {
                span class="text-gray-400 group-hover:text-gray-300 mr-4 flex-shrink-0 h-6 w-6" {
                    (self.icon)
                }
                (self.label)
            }
        }
    }
}

fn sidebar_items() -> Vec<SidebarItem> {
    vec![
        SidebarItem {
            label: "Home".to_string(),
            icon: heroicons_maud::home_solid(),
            type_: ItemType::Route(Route::Home),
        },
        SidebarItem {
            label: "Quick Action".to_string(),
            icon: heroicons_maud::magnifying_glass_outline(),
            type_: ItemType::Button(Id::SidebarSearch),
        },
    ]
}

pub fn app_shell(
    content: Markup,
    topbar_content: Option<Markup>,
    state: &State,
    current_route: &Route,
) -> Markup {
    let items = sidebar_items();
    let commit_hash = env!("GIT_HASH");
    let commit_url = format!(
        "https://github.com/glotcode/glot-app/commit/{}",
        commit_hash
    );

    html! {
        div class="h-full" {
            @if let State::Open = state {
                div class="relative z-40 xl:hidden" role="dialog" aria-modal="true" {
                    div class="fixed inset-0 bg-gray-600 bg-opacity-75" {}
                    div class="fixed inset-0 flex z-40" {
                        div class="relative flex-1 flex flex-col max-w-xs w-full bg-gray-800" {
                            div class="absolute top-0 right-0 -mr-12 pt-2" {
                                button id=(Id::CloseSidebar) class="ml-1 flex items-center justify-center h-10 w-10 rounded-full focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white" type="button" {
                                    span class="sr-only" {
                                        "Close sidebar"
                                    }
                                    span class="h6 w-6 text-white" {
                                        (heroicons_maud::x_mark_outline())
                                    }
                                }
                            }
                            div class="flex-1 h-0 pt-5 pb-4 overflow-y-auto flex flex-col" {
                                div class="flex-shrink-0 flex items-center px-4" {
                                    img class="h-10 w-auto" src="/static/assets/logo-white.svg?hash=checksum" alt="glot.io logo";
                                }
                                nav class="mt-5 px-2 space-y-1 flex-1" {
                                    @for item in &items {
                                        (item.view(current_route))
                                    }
                                }
                                div class="mx-4 flex mb-4 gap-6" {
                                    a href="https://twitter.com/glotcode" target="_blank" {
                                        span class="flex w-6 h-6" {
                                            (svg::x_logo())
                                        }
                                    }
                                    a href="https://discord.gg/5fyVwp8559" target="_blank" {
                                        span class="flex w-6 h-6" {
                                            (svg::discord_logo())
                                        }
                                    }
                                    a href="https://github.com/glotcode/glot" target="_blank" {
                                        span class="flex w-6 h-6" {
                                            (svg::github_logo())
                                        }
                                    }
                                }
                                div class="ml-4 text-white" {
                                    "Version: "
                                    a href=(commit_url) class="underline hover:no-underline text-gray-200 hover:text-gray-400 visited:text-purple-400" target="_blank" {
                                        (&commit_hash[0..7])
                                    }
                                }
                            }
                        }
                        div class="flex-shrink-0 w-14" {
                        }
                    }
                }
            }

            div class="hidden xl:flex xl:w-60 xl:flex-col xl:fixed xl:inset-y-0" {
                div class="flex-1 flex flex-col min-h-0 bg-gray-800" {
                    div class="flex-1 flex flex-col pt-5 pb-4 overflow-y-auto" {
                        div class="flex items-center flex-shrink-0 px-4" {
                            img class="h-10 w-auto" src="/static/assets/logo-white.svg?hash=checksum" alt="glot.io logo";
                        }
                        nav class="mt-5 flex-1 px-2 space-y-1" {
                            @for item in &items {
                                (item.view(current_route))
                            }
                        }
                        div class="mx-4 flex mb-4 gap-6" {
                            a href="https://twitter.com/glotcode" target="_blank" {
                                span class="flex w-6 h-6" {
                                    (svg::x_logo())
                                }
                            }
                            a href="https://discord.gg/5fyVwp8559" target="_blank" {
                                span class="flex w-6 h-6" {
                                    (svg::discord_logo())
                                }
                            }
                            a href="https://github.com/glotcode/glot" target="_blank" {
                                span class="flex w-6 h-6" {
                                    (svg::github_logo())
                                }
                            }
                        }
                        div class="ml-4 text-white" {
                            "Version: "
                            a href=(commit_url) class="underline hover:no-underline text-gray-200 hover:text-gray-400 visited:text-purple-400" target="_blank" {
                                (&commit_hash[0..7])
                            }
                        }
                    }
                }
            }
            div class="h-full xl:pl-60 flex flex-col flex-1" {
                div class="flex sticky top-0 z-10 xl:hidden pl-1 py-0.5 sm:pl-3 bg-gray-100" {
                    button id=(Id::OpenSidebar) class="-ml-0.5 my-auto h-12 w-12 inline-flex items-center justify-center rounded-md text-gray-500 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500" type="button" {
                        span class="sr-only" {
                            "Open sidebar"
                        }
                        span class="h-6 w-6" {
                            (heroicons_maud::bars_3_outline())
                        }
                    }
                    @if let Some(markup) = topbar_content {
                        (markup)
                    }
                }

                main class="flex-1 h-full" {
                    (content)
                }
            }
        }
    }
}
