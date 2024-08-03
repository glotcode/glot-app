use crate::common::route::Route;
use crate::components::search_modal;
use crate::language::Language;
use poly::browser::effect::{navigation, Effect};
use std::fmt;
use url::Url;

#[derive(Clone, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub struct LanguageQuickAction(Language);

impl LanguageQuickAction {
    pub fn language(self) -> Language {
        self.0
    }

    pub fn perform_action<Msg, AppEffect>(self, current_url: &Url) -> Effect<Msg, AppEffect> {
        let route = Route::NewSnippet(self.language());
        let url = route.to_absolute_path(current_url);
        navigation::set_location(&url)
    }
}

impl search_modal::EntryExtra for LanguageQuickAction {
    fn title(&self) -> String {
        match self {
            LanguageQuickAction(language) => {
                format!("Go to {}", language.config().name)
            }
        }
    }

    fn keywords(&self) -> Vec<String> {
        match self {
            LanguageQuickAction(language) => {
                vec![language.to_string(), language.config().name.clone()]
            }
        }
    }

    fn icon(&self) -> maud::Markup {
        heroicons_maud::link_outline()
    }
}

impl fmt::Display for LanguageQuickAction {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            LanguageQuickAction(language) => write!(f, "goto-{}", language),
        }
    }
}

pub fn language_actions() -> Vec<LanguageQuickAction> {
    Language::list()
        .into_iter()
        .map(|language| LanguageQuickAction(language))
        .collect()
}

pub fn language_entries() -> Vec<search_modal::Entry<LanguageQuickAction>> {
    language_actions()
        .into_iter()
        .map(search_modal::Entry::new)
        .collect()
}
