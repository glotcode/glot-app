use glot_core::home_page;
use poly::page::wasm;
use poly::page::Page;
use poly_macro::impl_wasm_page;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct HomePage(home_page::HomePage);

impl_wasm_page!(HomePage);

#[wasm_bindgen(js_name = homePage)]
pub fn new(js_current_url: JsValue) -> Result<HomePage, JsValue> {
    let current_url = wasm::decode_js_value(js_current_url)
        .map_err(|err| format!("Failed to decode URL: {}", err))?;

    Ok(HomePage(home_page::HomePage { current_url }))
}
