use glot_core::page::login_page;
use poly::page::wasm;
use poly::page::Page;
use poly_macro::impl_wasm_page;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct LoginPage(login_page::LoginPage);

impl_wasm_page!(LoginPage);

#[wasm_bindgen(js_name = "loginPage")]
pub fn new(js_current_url: JsValue) -> Result<LoginPage, JsValue> {
    let current_url = wasm::decode_js_value(js_current_url)
        .map_err(|err| format!("Failed to decode URL: {}", err))?;

    Ok(LoginPage(login_page::LoginPage { current_url }))
}
