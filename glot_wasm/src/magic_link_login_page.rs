use glot_core::magic_link_login_page;
use poly::page::wasm;
use poly::page::Page;
use poly_macro::impl_wasm_page;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct MagicLinkLoginPage(magic_link_login_page::MagicLinkLoginPage);

impl_wasm_page!(MagicLinkLoginPage);

#[wasm_bindgen(js_name = "magicLinkLoginPage")]
pub fn new(js_current_url: JsValue) -> Result<MagicLinkLoginPage, JsValue> {
    let current_url = wasm::decode_js_value(js_current_url)
        .map_err(|err| format!("Failed to decode URL: {}", err))?;

    Ok(MagicLinkLoginPage(magic_link_login_page::MagicLinkLoginPage { current_url }))
}
