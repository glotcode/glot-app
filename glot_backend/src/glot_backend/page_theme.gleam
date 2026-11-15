pub const cookie_name = "glot_theme"

pub type PageTheme {
  Light
  White
  Dark
}

pub fn parse(value: String) -> Result(PageTheme, Nil) {
  case value {
    "light" -> Ok(Light)
    "white" -> Ok(White)
    "dark" -> Ok(Dark)
    _ -> Error(Nil)
  }
}

pub fn to_string(theme: PageTheme) -> String {
  case theme {
    Light -> "light"
    White -> "white"
    Dark -> "dark"
  }
}
