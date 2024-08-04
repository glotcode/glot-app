use glot_core::page::home_page;
use poly::page::wasm;
use poly::page::Page;
use poly_macro::impl_wasm_page;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct HomePage(home_page::HomePage);

impl_wasm_page!(HomePage);

#[wasm_bindgen(js_name = homePage)]
pub fn new(js_browser_ctx: JsValue) -> Result<HomePage, JsValue> {
    let browser_ctx = wasm::decode_js_value(js_browser_ctx)
        .map_err(|err| format!("Failed to decode browser context: {}", err))?;

    Ok(HomePage(home_page::HomePage { browser_ctx }))
}
