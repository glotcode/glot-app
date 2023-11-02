use glot_core::page::snippet_page;
use poly::browser;
use poly::page::wasm;
use poly::page::Page;
use poly_macro::impl_wasm_page;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct SnippetPage(snippet_page::SnippetPage);

impl_wasm_page!(SnippetPage);

#[wasm_bindgen(js_name = "snippetPage")]
pub fn new(js_window_size: JsValue, js_current_url: JsValue) -> Result<SnippetPage, JsValue> {
    let window_size: Option<browser::WindowSize> = wasm::decode_js_value(js_window_size)
        .map_err(|err| format!("Failed to decode window size: {}", err))?;

    let current_url = wasm::decode_js_value(js_current_url)
        .map_err(|err| format!("Failed to decode URL: {}", err))?;

    Ok(SnippetPage(snippet_page::SnippetPage {
        window_size,
        current_url,
    }))
}
