use maud::html;
use maud::Markup;

pub struct Config<'a> {
    pub title: &'a str,
    pub features: &'a [Feature<'a>],
}

pub struct Feature<'a> {
    pub icon: Markup,
    pub title: &'a str,
    pub description: &'a str,
}

pub fn view(config: &Config) -> Markup {
    html! {
        div class="bg-white py-12" {
            div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8" {
                div class="lg:text-center" {
                    p class="mt-4 max-w-2xl text-xl text-gray-500 lg:mx-auto" {
                        (config.title)
                    }
                }
                div class="mt-10" {
                    dl class="space-y-10 md:grid md:grid-cols-2 md:gap-x-8 md:gap-y-10 md:space-y-0" {
                        @for feature in config.features {
                            div class="relative" {
                                dt {
                                    div class="absolute flex h-12 w-12 items-center justify-center rounded-md bg-indigo-500 text-white" {
                                        span class="h-6 w-6" {
                                            (feature.icon)
                                        }
                                    }
                                    p class="ml-16 text-lg font-medium leading-6 text-gray-900" {
                                        (feature.title)
                                    }
                                }
                                dd class="mt-2 ml-16 text-base text-gray-500" {
                                    (feature.description)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
