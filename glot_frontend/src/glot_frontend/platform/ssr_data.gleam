import glot_web/page/ssr_data as ssr_data_contract

@external(javascript, "./ssr_data_ffi.mjs", "take")
fn take_element(_element_id: String) -> String {
  ""
}

pub fn take() -> String {
  take_element(ssr_data_contract.element_id)
}
