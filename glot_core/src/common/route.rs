use std::fmt;

use crate::language::Language;
use serde::Deserialize;
use serde::Serialize;
use url::Url;

#[derive(Clone, PartialEq, Serialize, Deserialize)]
pub enum RouteName {
    NotFound,
    Home,
    NewSnippet,
    EditSnippet,
}

impl fmt::Display for RouteName {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            RouteName::NotFound => write!(f, "NotFound"),
            RouteName::Home => write!(f, "Home"),
            RouteName::NewSnippet => write!(f, "NewSnippet"),
            RouteName::EditSnippet => write!(f, "EditSnippet"),
        }
    }
}

#[derive(Clone, PartialEq, Serialize, Deserialize)]
pub enum Route {
    NotFound,
    Home,
    NewSnippet(Language),
    EditSnippet(Language, String),
}

impl Default for Route {
    fn default() -> Self {
        Self::Home
    }
}

impl Route {
    pub fn from_path(path: &str) -> Route {
        let parts = path
            .trim_start_matches("/")
            .trim_end_matches("/")
            .split("/")
            .collect::<Vec<&str>>();

        match parts.as_slice() {
            [""] => Route::Home,
            [language] if is_valid_language(language) => {
                Route::NewSnippet(language.parse().unwrap())
            }
            [language, id] if is_valid_language(language) => {
                Route::EditSnippet(language.parse().unwrap(), id.to_string())
            }
            _ => Route::NotFound,
        }
    }

    pub fn to_path(&self) -> String {
        match self {
            Route::NotFound => format!("/not-found"),
            Route::Home => format!("/"),
            Route::NewSnippet(language) => format!("/{}", language),
            Route::EditSnippet(language, id) => format!("/{}/{}", language, id),
        }
    }

    pub fn to_absolute_path(&self, current_url: &Url) -> String {
        let mut url = current_url.clone();
        url.set_path(&self.to_path());
        url.to_string()
    }

    pub fn name(&self) -> RouteName {
        match self {
            Route::NotFound => RouteName::NotFound,
            Route::Home => RouteName::Home,
            Route::NewSnippet(_) => RouteName::NewSnippet,
            Route::EditSnippet(_, _) => RouteName::EditSnippet,
        }
    }
}

fn is_valid_language(input: &str) -> bool {
    input.parse::<Language>().is_ok()
}
