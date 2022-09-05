use maud::html;
use maud::Markup;
use polyester::browser::DomId;
use serde::Serialize;
use serde_json::json;

pub fn view<V, Id: DomId>(title: &str, id: Id, selected_value: V, options: Vec<(V, &str)>) -> Markup
where
    V: PartialEq,
    V: Serialize,
{
    html! {
        div class="mt-4" {
            label class="block text-sm font-medium text-gray-700" for=(id) {
                (title)
            }
            select #(id) class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md" {
                @for (value, name) in options {
                    option value=(json!(value)) selected[selected_value == value] {
                        (name)
                    }
                }
            }
        }
    }
}
