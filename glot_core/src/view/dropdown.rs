use maud::html;
use maud::Markup;
use polyester::browser::DomId;
use serde::Serialize;
use serde_json::json;
use std::fmt::Display;

pub struct Config<Id, Disp, Val> {
    pub id: Id,
    pub title: Disp,
    pub selected_value: Val,
    pub options: Vec<(Val, Disp)>,
}

pub fn view<Id, Disp, Val>(config: &Config<Id, Disp, Val>) -> Markup
where
    Id: DomId,
    Disp: Display,
    Val: PartialEq,
    Val: Serialize,
{
    html! {
        div class="mt-4" {
            label class="block text-sm font-medium text-gray-700" for=(config.id) {
                (config.title)
            }
            select #(config.id) class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md" {
                @for (value, name) in &config.options {
                    option value=(json!(value)) selected[config.selected_value == *value] {
                        (name)
                    }
                }
            }
        }
    }
}
