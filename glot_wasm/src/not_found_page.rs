use glot_core::page::not_found_page;
use glot_core::util::user_agent::UserAgent;
use poly::page::wasm;
use poly::page::Page;
use poly_macro::impl_wasm_page;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct NotFoundPage(not_found_page::NotFoundPage);

impl_wasm_page!(NotFoundPage);

#[wasm_bindgen(js_name = notFoundPage)]
pub fn new(js_user_agent: JsValue, js_current_url: JsValue) -> Result<NotFoundPage, JsValue> {
    let ua_string: String = wasm::decode_js_value(js_user_agent)
        .map_err(|err| format!("Failed to decode user agent string: {}", err))?;

    let current_url = wasm::decode_js_value(js_current_url)
        .map_err(|err| format!("Failed to decode URL: {}", err))?;

    Ok(NotFoundPage(not_found_page::NotFoundPage {
        current_url,
        user_agent: UserAgent::parse(&ua_string),
    }))
}
