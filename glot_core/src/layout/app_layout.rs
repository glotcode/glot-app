use crate::common::route::Route;
use maud::html;
use maud::Markup;
use poly::browser::DomId;
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

pub struct Config<Id> {
    pub open_sidebar_id: Id,
    pub close_sidebar_id: Id,
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct State {
    sidebar_is_open: bool,
}

impl State {
    pub fn new() -> Self {
        Self {
            sidebar_is_open: false,
        }
    }

    pub fn open_sidebar(&mut self) {
        self.sidebar_is_open = true;
    }

    pub fn close_sidebar(&mut self) {
        self.sidebar_is_open = false;
    }
}

pub struct SidebarItem {
    pub label: String,
    pub icon: Markup,
    pub route: Route,
}

impl SidebarItem {
    fn view(&self, current_route: &Route) -> Markup {
        html! {
            @if self.route.name() == current_route.name() {
                a href=(self.route.to_path()) class="bg-gray-900 text-white group flex items-center px-2 py-2 text-base font-medium rounded-md" {
                    span class="text-gray-300 mr-4 flex-shrink-0 h-6 w-6" {
                        (self.icon)
                    }
                    (self.label)
                }
            } @else {
                a href=(self.route.to_path()) class="text-gray-300 hover:bg-gray-700 hover:text-white group flex items-center px-2 py-2 text-base font-medium rounded-md" {
                    span class="text-gray-400 group-hover:text-gray-300 mr-4 flex-shrink-0 h-6 w-6" {
                        (self.icon)
                    }
                    (self.label)
                }
            }
        }
    }
}

fn sidebar_items() -> Vec<SidebarItem> {
    vec![SidebarItem {
        label: "Home".to_string(),
        icon: heroicons_maud::home_solid(),
        route: Route::Home,
    }]
}

pub fn app_shell<Id>(
    content: Markup,
    config: &Config<Id>,
    state: &State,
    current_route: &Route,
) -> Markup
where
    Id: DomId,
{
    let items = sidebar_items();
    let commit_hash = env!("GIT_HASH");
    let commit_url = format!("https://github.com/glotlabs/glot/commit/{}", commit_hash);

    html! {
        div class="h-full" {
            @if state.sidebar_is_open {
                div class="relative z-40 xl:hidden" role="dialog" aria-modal="true" {
                    div class="fixed inset-0 bg-gray-600 bg-opacity-75" {}
                    div class="fixed inset-0 flex z-40" {
                        div class="relative flex-1 flex flex-col max-w-xs w-full bg-gray-800" {
                            div class="absolute top-0 right-0 -mr-12 pt-2" {
                                button id=(config.close_sidebar_id) class="ml-1 flex items-center justify-center h-10 w-10 rounded-full focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white" type="button" {
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
                                    img class="h-10 w-auto" src="/assets/logo-white.svg" alt="glot.io logo";
                                }
                                nav class="mt-5 px-2 space-y-1 flex-1" {
                                    @for item in &items {
                                        (item.view(current_route))
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
                            img class="h-10 w-auto" src="/assets/logo-white.svg" alt="glot.io logo";
                        }
                        nav class="mt-5 flex-1 px-2 space-y-1" {
                            @for item in &items {
                                (item.view(current_route))
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
                div class="sticky top-0 z-10 xl:hidden pl-1 pt-1 sm:pl-3 sm:pt-3 bg-gray-100" {
                    button id=(config.open_sidebar_id) class="-ml-0.5 -mt-0.5 h-12 w-12 inline-flex items-center justify-center rounded-md text-gray-500 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500" type="button" {
                        span class="sr-only" {
                            "Open sidebar"
                        }
                        span class="h-6 w-6" {
                            (heroicons_maud::bars_3_outline())
                        }
                    }
                }

                main class="flex-1 h-full" {
                    (content)
                }
            }
        }
    }
}
