use crate::common::keyboard_shortcut::KeyboardShortcut;
use crate::common::quick_action;
use crate::common::quick_action::LanguageQuickAction;
use crate::components::search_modal;
use crate::snippet::File;
use crate::util::user_agent::UserAgent;
use std::fmt;

#[derive(Clone, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum QuickAction {
    Run,
    EditTitle,
    EditFile,
    EditStdin,
    AddFile,
    Settings,
    Share,
    SelectFile(String),
    GoToFrontPage,
    GoToLanguage(LanguageQuickAction),
}

impl search_modal::EntryExtra for QuickAction {
    fn title(&self) -> String {
        match self {
            QuickAction::Run => "Run code".into(),
            QuickAction::EditTitle => "Edit title".into(),
            QuickAction::EditFile => "Edit file".into(),
            QuickAction::EditStdin => "Edit stdin data".into(),
            QuickAction::AddFile => "Add file".into(),
            QuickAction::Share => "Open sharing dialog".into(),
            QuickAction::Settings => "Open settings".into(),
            QuickAction::SelectFile(name) => format!("Select {}", name),
            QuickAction::GoToFrontPage => "Go to front page".into(),
            QuickAction::GoToLanguage(action) => action.title(),
        }
    }

    fn keywords(&self) -> Vec<String> {
        match self {
            QuickAction::Run => vec!["run".to_string()],
            QuickAction::EditTitle => vec!["edit".into(), "title".into()],
            QuickAction::EditFile => vec!["edit".into(), "file".into()],
            QuickAction::EditStdin => vec!["edit".into(), "stdin".into()],
            QuickAction::AddFile => vec!["add".into(), "file".into()],
            QuickAction::Share => vec!["open".into(), "sharing".into(), "share".into()],
            QuickAction::Settings => vec!["open".into(), "settings".into()],
            QuickAction::SelectFile(name) => vec!["select".into(), name.clone()],
            QuickAction::GoToFrontPage => vec!["home".into(), "frontpage".into()],
            QuickAction::GoToLanguage(action) => action.keywords(),
        }
    }

    fn icon(&self) -> maud::Markup {
        match self {
            QuickAction::Run => heroicons_maud::play_outline(),
            QuickAction::EditTitle => heroicons_maud::pencil_square_outline(),
            QuickAction::EditFile => heroicons_maud::pencil_square_outline(),
            QuickAction::EditStdin => heroicons_maud::pencil_square_outline(),
            QuickAction::AddFile => heroicons_maud::document_plus_outline(),
            QuickAction::Share => heroicons_maud::share_outline(),
            QuickAction::Settings => heroicons_maud::cog_6_tooth_outline(),
            QuickAction::SelectFile(_) => heroicons_maud::document_outline(),
            QuickAction::GoToFrontPage => heroicons_maud::link_outline(),
            QuickAction::GoToLanguage(action) => action.icon(),
        }
    }

    fn extra_text(&self, user_agent: &UserAgent) -> Option<String> {
        match self {
            QuickAction::Run => {
                let key_combo = KeyboardShortcut::RunCode.key_combo(user_agent);
                Some(key_combo.to_string())
            }
            _ => None,
        }
    }
}

impl fmt::Display for QuickAction {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            QuickAction::Run => write!(f, "run"),
            QuickAction::EditTitle => write!(f, "edit-title"),
            QuickAction::EditFile => write!(f, "edit-file"),
            QuickAction::EditStdin => write!(f, "edit-stdin"),
            QuickAction::AddFile => write!(f, "add-file"),
            QuickAction::Share => write!(f, "share"),
            QuickAction::Settings => write!(f, "settings"),
            QuickAction::SelectFile(name) => write!(f, "select-file-{}", name),
            QuickAction::GoToFrontPage => write!(f, "go-to-front-page"),
            QuickAction::GoToLanguage(action) => action.fmt(f),
        }
    }
}

pub fn actions(files: Vec<File>) -> Vec<search_modal::Entry<QuickAction>> {
    let snippet_actions = vec![
        QuickAction::Run,
        QuickAction::EditTitle,
        QuickAction::EditFile,
        QuickAction::EditStdin,
        QuickAction::AddFile,
        QuickAction::Share,
        QuickAction::Settings,
        QuickAction::GoToFrontPage,
    ];

    let file_actions = files
        .iter()
        .map(|file| QuickAction::SelectFile(file.name.clone()))
        .collect();

    let language_actions = quick_action::language_actions()
        .into_iter()
        .map(QuickAction::GoToLanguage)
        .collect();

    [snippet_actions, file_actions, language_actions]
        .concat()
        .into_iter()
        .map(search_modal::Entry::new)
        .collect()
}
