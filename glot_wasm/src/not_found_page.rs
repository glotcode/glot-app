use glot_core::page::not_found_page;
use poly::page::wasm;
use poly::page::Page;
use poly_macro::impl_wasm_page;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct NotFoundPage(not_found_page::NotFoundPage);

impl_wasm_page!(NotFoundPage);

#[wasm_bindgen(js_name = notFoundPage)]
pub fn new(js_current_url: JsValue) -> Result<NotFoundPage, JsValue> {
    let current_url = wasm::decode_js_value(js_current_url)
        .map_err(|err| format!("Failed to decode URL: {}", err))?;

    Ok(NotFoundPage(not_found_page::NotFoundPage { current_url }))
}
