use maud::html;
use maud::Markup;
use poly::browser::dom_id::DomId;
use poly::browser::keyboard::Key;
use poly::browser::subscription;
use poly::browser::subscription::event_listener;
use poly::browser::subscription::Subscription;

pub struct Config<Id> {
    pub backdrop_id: Id,
    pub close_button_id: Id,
}

pub fn subscriptions<Msg: Clone, Id: DomId>(config: &Config<Id>, msg: Msg) -> Subscription<Msg> {
    subscription::batch(vec![
        event_listener::on_mouse_down(&config.backdrop_id, msg.clone()),
        event_listener::on_click_closest(&config.close_button_id, msg.clone()),
        event_listener::on_keyup(Key::Escape, msg),
    ])
}

pub fn view<Id: DomId>(content: Markup, config: &Config<Id>) -> Markup {
    html! {
        div class="relative z-10" aria-labelledby="modal-title" role="dialog" aria-modal="true" {
            div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" {}
            div class="fixed z-10 inset-0 overflow-y-auto" {
                div id=(config.backdrop_id) class="flex items-end sm:items-center justify-center min-h-full p-4 text-center sm:p-0" {
                    div class="relative bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:max-w-sm sm:w-full sm:p-6" {
                        div class="absolute top-0 right-0 hidden pt-4 pr-4 sm:block" {
                            button id=(config.close_button_id) class="rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                                span class="sr-only" {
                                    "Close"
                                }
                                span class="block h-6 w-6" {
                                    (heroicons_maud::x_mark_outline())
                                }
                            }
                        }
                        (content)
                    }
                }
            }
        }
    }
}

pub fn view_minimal<Id: DomId>(content: Markup, config: &Config<Id>) -> Markup {
    html! {
        div class="relative z-10" aria-labelledby="modal-title" role="dialog" aria-modal="true" {
            div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" {}
            div class="fixed z-10 inset-0 overflow-y-auto" {
                div id=(config.backdrop_id) class="flex items-end sm:items-center justify-center min-h-full p-4 text-center sm:p-0" {
                    div class="relative bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:max-w-sm sm:w-full" {
                        (content)
                    }
                }
            }
        }
    }
}
