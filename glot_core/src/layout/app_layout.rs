use maud::html;
use maud::Markup;
use polyester::browser::DomId;
use polyester::page::PageMarkup;
use serde::{Deserialize, Serialize};

pub fn render_page(markup: PageMarkup<Markup>) -> String {
    (html! {
        (maud::DOCTYPE)
        html class="h-full bg-gray-100" {
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

pub fn app_shell<Id>(content: Markup, config: &Config<Id>, state: &State) -> Markup
where
    Id: DomId,
{
    html! {
        div class="h-full" {
            @if state.sidebar_is_open {
                div class="relative z-40 md:hidden" role="dialog" aria-modal="true" {
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
                            div class="flex-1 h-0 pt-5 pb-4 overflow-y-auto" {
                                div class="flex-shrink-0 flex items-center px-4" {
                                    img class="h-8 w-auto" src="https://tailwindui.com/img/logos/workflow-mark.svg?color=indigo&shade=500" alt="Workflow";
                                }
                                nav class="mt-5 px-2 space-y-1" {
                                    a class="bg-gray-900 text-white group flex items-center px-2 py-2 text-base font-medium rounded-md" href="#" {
                                        span class="text-gray-300 mr-4 flex-shrink-0 h-6 w-6" {
                                            (heroicons_maud::home_outline())
                                        }
                                        "Home"
                                    }
                                    a class="text-gray-300 hover:bg-gray-700 hover:text-white group flex items-center px-2 py-2 text-base font-medium rounded-md" href="#" {
                                        span class="text-gray-400 group-hover:text-gray-300 mr-4 flex-shrink-0 h-6 w-6" {
                                            (heroicons_maud::pencil_square_solid())
                                        }
                                        "New"
                                    }
                                }
                            }
                        }
                        div class="flex-shrink-0 w-14" {
                        }
                    }
                }
            }

            div class="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0" {
                div class="flex-1 flex flex-col min-h-0 bg-gray-800" {
                    div class="flex-1 flex flex-col pt-5 pb-4 overflow-y-auto" {
                        div class="flex items-center flex-shrink-0 px-4" {
                            img class="h-8 w-auto" src="https://tailwindui.com/img/logos/workflow-mark.svg?color=indigo&shade=500" alt="Workflow";
                        }
                        nav class="mt-5 flex-1 px-2 space-y-1" {
                            a class="text-gray-300 group flex items-center px-2 py-2 text-sm font-medium rounded-md" href="#" {
                                span class="text-gray-300 mr-3 flex-shrink-0 h-6 w-6" {
                                    (heroicons_maud::home_outline())
                                }
                                "Home"
                            }
                            a class="bg-gray-900 text-white text-gray-300 hover:bg-gray-700 hover:text-white group flex items-center px-2 py-2 text-sm font-medium rounded-md" href="#" {
                                span class="text-gray-400 group-hover:text-gray-300 mr-3 flex-shrink-0 h-6 w-6" {
                                    (heroicons_maud::pencil_square_solid())
                                }
                                "New"

                            }
                        }
                    }
                }
            }
            div class="h-full md:pl-64 flex flex-col flex-1" {
                div class="sticky top-0 z-10 md:hidden pl-1 pt-1 sm:pl-3 sm:pt-3 bg-gray-100" {
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
