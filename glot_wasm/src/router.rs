use glot_core::common::route::Route;
use poly::page::wasm;
use url::Url;
use wasm_bindgen::prelude::*;

#[wasm_bindgen(js_name = getRouteName)]
pub fn get_route_name(js_current_url: JsValue) -> Result<String, JsValue> {
    let url: Url = wasm::decode_js_value(js_current_url)
        .map_err(|err| format!("Failed to decode URL: {}", err))?;

    let route = Route::from_path(url.path());

    Ok(route.name().to_string())
}
