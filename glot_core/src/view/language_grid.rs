use crate::common::route::Route;
use maud::html;
use maud::Markup;

pub struct Language<'a> {
    pub icon_path: &'a str,
    pub name: &'a str,
    pub route: Route,
}

pub fn view(languages: &[Language]) -> Markup {
    html! {
        div {
            ul class="mt-3 grid grid-cols-1 gap-5 sm:grid-cols-2 sm:gap-6 lg:grid-cols-4" role="list" {
                @for language in languages {
                    li class="col-span-1 rounded-md shadow-sm border border-gray-200 bg-white" {
                        a class="flex" href=(language.route.to_path()) {
                            div class="p-2 flex-shrink-0 flex items-center justify-center w-16 h-16 text-white text-sm font-medium" {
                                img class="mx-auto flex-shrink-0" src=(language.icon_path);
                            }
                            div class="flex flex-1 items-center justify-between border-l border-gray-200 truncate" {
                                div class="flex-1 truncate px-4 py-2 text-2xl" {
                                    p class="font-medium text-gray-900 hover:text-gray-600" {
                                        (language.name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}