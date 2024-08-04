use glot_core::page::snippet_page;
use poly::page::wasm;
use poly::page::Page;
use poly_macro::impl_wasm_page;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct SnippetPage(snippet_page::SnippetPage);

impl_wasm_page!(SnippetPage);

#[wasm_bindgen(js_name = "snippetPage")]
pub fn new(js_browser_ctx: JsValue) -> Result<SnippetPage, JsValue> {
    let browser_ctx = wasm::decode_js_value(js_browser_ctx)
        .map_err(|err| format!("Failed to decode browser context: {}", err))?;

    Ok(SnippetPage(snippet_page::SnippetPage { browser_ctx }))
}
