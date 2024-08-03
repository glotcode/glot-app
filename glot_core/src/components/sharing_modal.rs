use crate::common::route::Route;
use crate::language::Language;
use crate::snippet::Snippet;
use crate::util::remote_data::RemoteData;
use crate::view::modal;
use maud::html;
use poly::browser::dom_id::DomId;
use poly::browser::effect;
use poly::browser::effect::browser;
use poly::browser::effect::clipboard;
use poly::browser::effect::Effect;
use poly::browser::subscription;
use poly::browser::subscription::event_listener;
use poly::browser::subscription::Subscription;
use poly::browser::value::Capture;
use serde::{Deserialize, Serialize};
use std::fmt;
use std::time::Duration;
use url::Url;

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct State {
    is_open: bool,
    snippet_url: Option<String>,
    copy_state: RemoteData<String, ()>,
}

#[derive(strum_macros::Display, poly_macro::DomId)]
#[strum(serialize_all = "kebab-case")]
enum Id {
    SnippetUrl,
    CopyUrl,
    SharingModalCloseButton,
    SharingModalBackdrop,
    SharingModalClose,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub enum Msg {
    EncodeSnippetUrl,
    ClearCopyStateTimeout,
    CopyUrlClicked,
    GotCopyUrlResult(Capture<clipboard::WriteTextResult>),
    Close,
}

pub fn subscriptions<ToParentMsg, ParentMsg, AppEffect>(
    _state: &State,
    to_parent_msg: ToParentMsg,
) -> Subscription<ParentMsg, AppEffect>
where
    ParentMsg: Clone,
    ToParentMsg: Fn(Msg) -> ParentMsg,
{
    let modal_config = modal::Config {
        backdrop_id: Id::SharingModalBackdrop,
        close_button_id: Id::SharingModalClose,
    };

    subscription::batch(vec![
        event_listener::on_click_closest(Id::CopyUrl, to_parent_msg(Msg::CopyUrlClicked)),
        event_listener::on_click(Id::SharingModalCloseButton, to_parent_msg(Msg::Close)),
        modal::subscriptions(&modal_config, to_parent_msg(Msg::Close)),
    ])
}

pub struct Context {
    pub snippet: Snippet,
    pub language: Language,
    pub current_url: Url,
}

pub fn update<ToParentMsg, ParentMsg, AppEffect>(
    msg: &Msg,
    state: &mut State,
    context: Context,
    to_parent_msg: ToParentMsg,
) -> Result<Effect<ParentMsg, AppEffect>, String>
where
    ToParentMsg: Fn(Msg) -> ParentMsg,
{
    match msg {
        Msg::EncodeSnippetUrl => {
            let snippet_url = get_snippet_url(context)?;
            state.snippet_url = Some(snippet_url);

            Ok(effect::none())
        }

        Msg::CopyUrlClicked => {
            if let Some(snippet_url) = &state.snippet_url {
                Ok(clipboard::write_text(snippet_url, |captured| {
                    to_parent_msg(Msg::GotCopyUrlResult(captured))
                }))
            } else {
                Ok(effect::none())
            }
        }

        Msg::GotCopyUrlResult(captured) => {
            let result = captured.value();

            if result.success {
                state.copy_state = RemoteData::Success(());
                Ok(browser::set_timeout(
                    Duration::from_secs(3),
                    to_parent_msg(Msg::ClearCopyStateTimeout),
                ))
            } else {
                state.copy_state = RemoteData::Failure(result.error.unwrap_or_default());
                Ok(browser::set_timeout(
                    Duration::from_secs(5),
                    to_parent_msg(Msg::ClearCopyStateTimeout),
                ))
            }
        }

        Msg::ClearCopyStateTimeout => {
            state.copy_state = RemoteData::NotAsked;

            Ok(effect::none())
        }

        Msg::Close => {
            *state = State::default();
            Ok(effect::none())
        }
    }
}

pub fn open<ToParentMsg, ParentMsg, AppEffect>(
    state: &mut State,
    to_parent_msg: ToParentMsg,
) -> Effect<ParentMsg, AppEffect>
where
    ToParentMsg: Fn(Msg) -> ParentMsg,
{
    *state = State {
        is_open: true,
        ..State::default()
    };

    browser::set_timeout(
        Duration::from_millis(500),
        to_parent_msg(Msg::EncodeSnippetUrl),
    )
}

pub fn view(state: &State) -> maud::Markup {
    if state.is_open {
        modal::view(
            view_modal(state),
            &modal::Config {
                backdrop_id: Id::SharingModalBackdrop,
                close_button_id: Id::SharingModalClose,
            },
        )
    } else {
        html! {}
    }
}

fn view_modal(state: &State) -> maud::Markup {
    let url_max_length = 16000;
    let maybe_overlay = SnippetUrlOverlay::from_state(state);
    let snippet_url_value = state.snippet_url.clone().unwrap_or_default();
    let url_length = snippet_url_value.len();

    html! {
        div class="text-center" {
            h3 class="text-lg leading-6 font-medium text-gray-900" {
                "Share snippet"
            }
        }

        div class="mt-4" {
            label class="block text-sm font-medium leading-6 text-gray-900" for=(Id::SnippetUrl) {
                "Snippet url"
            }
            div class="mt-2 flex rounded-md shadow-sm" {
                div class="relative flex flex-grow items-stretch focus-within:z-10" {
                    input id=(Id::SnippetUrl) value=(snippet_url_value) readonly class="block w-full rounded-none rounded-l-md border-0 py-1.5 px-2 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6";

                    @if let Some(overlay) = maybe_overlay {
                        div class="absolute flex justify-center items-center w-full h-full rounded-none rounded-l-md border-0 bg-white ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 text-grey-900" {
                            (overlay)
                        }
                    }
                }
                button id=(Id::CopyUrl) disabled[state.snippet_url.is_none()] class="relative -ml-px inline-flex items-center gap-x-1.5 rounded-r-md px-3 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50" type="button" {
                    span class="w-4 h-4" {
                        (heroicons_maud::clipboard_outline())
                    }
                    "Copy"
                }
            }
            p class="mt-2 text-sm text-gray-500" {
                "The snippet is embedded in the url using brotli compression and base62 encoding."
            }

            @if url_length > url_max_length {
                p class="mt-2 text-sm text-red-500" {
                    (format!("{} / {}", url_length, url_max_length))
                }
            } @else {
                p class="mt-2 text-sm text-gray-500" {
                    (format!("{} / {}", url_length, url_max_length))
                }
            }
        }

        div class="flex mt-6" {
            button id=(Id::SharingModalCloseButton) class="flex-1 w-full inline-flex justify-center items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" type="button" {
                "Close"
            }
        }
    }
}

enum SnippetUrlOverlay {
    Encoding,
    Copied,
    Failure,
}

impl SnippetUrlOverlay {
    fn from_state(state: &State) -> Option<Self> {
        match state.copy_state {
            RemoteData::Success(_) => Some(Self::Copied),
            RemoteData::Failure(_) => Some(Self::Failure),
            RemoteData::NotAsked => {
                if state.snippet_url.is_none() {
                    Some(Self::Encoding)
                } else {
                    None
                }
            }
            _ => None,
        }
    }
}

impl fmt::Display for SnippetUrlOverlay {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Self::Encoding => write!(f, "Encoding snippet..."),
            Self::Copied => write!(f, "Copied to clipboard!"),
            Self::Failure => write!(f, "Failed to copy url"),
        }
    }
}

fn get_snippet_url(context: Context) -> Result<String, String> {
    let encoded_snippet = context
        .snippet
        .to_encoded_string()
        .map_err(|err| format!("Failed to encode snippet: {}", err))?;

    let route = Route::EditSnippet(context.language.clone(), encoded_snippet.clone());
    Ok(route.to_absolute_path(&context.current_url))
}