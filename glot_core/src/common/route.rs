use crate::language::Language;
use serde::Deserialize;
use serde::Serialize;
use url::Url;

#[derive(Clone, PartialEq, Serialize, Deserialize)]
pub enum RouteName {
    Home,
    NewSnippet,
    EditSnippet,
}

#[derive(Clone, PartialEq, Serialize, Deserialize)]
pub enum Route {
    Home,
    NewSnippet(Language),
    EditSnippet(String),
}

impl Default for Route {
    fn default() -> Self {
        Self::Home
    }
}

fn is_language(input: &str) -> bool {
    input.parse::<Language>().is_ok()
}

impl Route {
    pub fn from_path(path: &str) -> Option<Route> {
        let parts = path
            .trim_start_matches("/")
            .trim_end_matches("/")
            .split("/")
            .collect::<Vec<&str>>();

        match parts.as_slice() {
            [] => Some(Route::Home),
            ["new", language] if is_language(language) => {
                Some(Route::NewSnippet(language.parse().unwrap()))
            }
            ["snippets", id] => Some(Route::EditSnippet(id.to_string())),
            _ => None,
        }
    }

    pub fn to_path(&self) -> String {
        match self {
            Route::Home => format!("/"),
            Route::NewSnippet(language) => format!("/new/{}", language),
            Route::EditSnippet(id) => format!("/snippets/{}", id),
        }
    }

    pub fn to_absolute_path(&self, current_url: &Url) -> String {
        let mut url = current_url.clone();
        url.set_path(&self.to_path());
        url.to_string()
    }

    pub fn name(&self) -> RouteName {
        match self {
            Route::Home => RouteName::Home,
            Route::NewSnippet(_) => RouteName::NewSnippet,
            Route::EditSnippet(_) => RouteName::EditSnippet,
        }
    }
}
