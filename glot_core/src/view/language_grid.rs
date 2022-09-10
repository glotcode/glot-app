use maud::html;
use maud::Markup;

pub fn view() -> Markup {
    html! {
        ul class="grid grid-cols-1 gap-6 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4" role="list" {
            li class="col-span-1 flex flex-col divide-y divide-gray-200 rounded-lg bg-white text-center shadow" {
                div class="flex flex-1 flex-col px-8 py-4" {
                    img class="mx-auto h-32 w-32 flex-shrink-0 rounded-full" src="/assets/language/rust.svg";
                    h3 class="mt-4 text-2xl font-medium text-gray-900" {
                        "Rust"
                    }
                }
            }
        }
    }
}
