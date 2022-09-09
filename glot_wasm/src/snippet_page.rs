use glot_core::snippet_page;
use polyester::page::wasm;
use polyester::page::Page;
use polyester_macro::impl_wasm_page;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct SnippetPage(snippet_page::SnippetPage);

impl_wasm_page!(SnippetPage);

#[wasm_bindgen(js_name = snippetPage)]
pub fn new(js_window_size: JsValue, js_current_url: JsValue) -> Result<SnippetPage, JsValue> {
    let window_size = js_window_size
        .into_serde()
        .map_err(|err| format!("Failed to decode window size: {}", err))?;

    let current_url = js_current_url
        .into_serde()
        .map_err(|err| format!("Failed to decode URL: {}", err))?;

    Ok(SnippetPage(snippet_page::SnippetPage {
        window_size: Some(window_size),
        current_url,
    }))
}
