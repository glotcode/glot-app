use maud::html;
use maud::Markup;
use polyester::page::PageMarkup;

pub fn render(markup: PageMarkup<Markup>) -> String {
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

pub fn app_shell(content: Markup) -> Markup {
    html! {
        div {
            div class="relative z-40 md:hidden" role="dialog" aria-modal="true" {
                div class="fixed inset-0 bg-gray-600 bg-opacity-75" {}
                div class="fixed inset-0 flex z-40" {
                    div class="relative flex-1 flex flex-col max-w-xs w-full bg-gray-800" {
                        div class="absolute top-0 right-0 -mr-12 pt-2" {
                            button class="ml-1 flex items-center justify-center h-10 w-10 rounded-full focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white" type="button" {
                                span class="sr-only" {
                                    "Close sidebar"
                                }
                                svg class="h-6 w-6 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" {
                                    path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" {
                                    }
                                }
                            }
                        }
                        div class="flex-1 h-0 pt-5 pb-4 overflow-y-auto" {
                            div class="flex-shrink-0 flex items-center px-4" {
                                img class="h-8 w-auto" src="https://tailwindui.com/img/logos/workflow-mark.svg?color=indigo&shade=500" alt="Workflow";
                            }
                            nav class="mt-5 px-2 space-y-1" {
                                a class="bg-gray-900 text-white group flex items-center px-2 py-2 text-base font-medium rounded-md" href="#" {
                                    svg class="text-gray-300 mr-4 flex-shrink-0 h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" {
                                        path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25" {
                                        }
                                    }
                                    "Home"
                                }
                                a class="text-gray-300 hover:bg-gray-700 hover:text-white group flex items-center px-2 py-2 text-base font-medium rounded-md" href="#" {
                                    svg class="text-gray-400 group-hover:text-gray-300 mr-4 flex-shrink-0 h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" {
                                        path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" {
                                        }
                                    }
                                    "Snippet"
                                }
                            }
                        }
                    }
                    div class="flex-shrink-0 w-14" {
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
                                svg class="text-gray-300 mr-3 flex-shrink-0 h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" {
                                    path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25" {
                                    }
                                }
                                "Home"
                            }
                            a class="bg-gray-900 text-white text-gray-300 hover:bg-gray-700 hover:text-white group flex items-center px-2 py-2 text-sm font-medium rounded-md" href="#" {
                                svg class="text-gray-400 group-hover:text-gray-300 mr-3 flex-shrink-0 h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" {
                                    path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" {
                                    }
                                }
                                "New"
                            }
                        }
                    }
                }
            }
            div class="md:pl-64 flex flex-col flex-1" {
                div class="sticky top-0 z-10 md:hidden pl-1 pt-1 sm:pl-3 sm:pt-3 bg-gray-100" {
                    button class="-ml-0.5 -mt-0.5 h-12 w-12 inline-flex items-center justify-center rounded-md text-gray-500 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500" type="button" {
                        span class="sr-only" {
                            "Open sidebar"
                        }
                        svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" {
                            path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" {
                            }
                        }
                    }
                }

                main class="flex-1" {
                    (content)
                }
            }
        }
    }
}
