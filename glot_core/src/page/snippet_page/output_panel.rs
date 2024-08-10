use crate::run::FailedRunResult;
use crate::run::RunResult;
use crate::util::remote_data::RemoteData;
use maud::html;
use maud::Markup;

const LOADING_TEXT: &str = r#"
LOAD"*",8,1

SEARCHING FOR *
LOADING
"#;

pub struct ViewModel<'a> {
    pub run_result: &'a RemoteData<FailedRunResult, RunResult>,
    pub version_result: &'a RemoteData<FailedRunResult, RunResult>,
}

pub fn view(model: ViewModel) -> Markup {
    let ready_info = extract_language_version(&model)
        .map(|version| format!("{}\nREADY.", version))
        .unwrap_or_default();

    html! {
        div class="h-full border-b border-x border-gray-400 shadow-lg" {
            dl {
                @match &model.run_result {
                    RemoteData::NotAsked => {
                        (view_info(&ready_info))
                    }

                    RemoteData::Loading => {
                        (view_info(LOADING_TEXT))
                    }

                    RemoteData::Success(run_result) => {
                        @if run_result.is_empty() {
                            (view_info("EMPTY OUTPUT"))
                        } @else {
                            (view_run_result(run_result))
                        }
                    }

                    RemoteData::Failure(err) => {
                        (view_info(&format!("ERROR: {}", err.message)))
                    }
                }
            }
        }
    }
}

fn view_info(text: &str) -> Markup {
    html! {
        dt class="px-4 py-1 border-t border-b border-gray-400 text-sm text-slate-700 font-bold bg-blue-400" {
            pre { "INFO" }
        }
        dd class="px-4 py-2 overflow-y-auto" {
            pre { (text) }
        }
    }
}

fn view_run_result(run_result: &RunResult) -> Markup {
    html! {
        @if !run_result.stdout.is_empty() {
            dt class="px-4 py-1 border-t border-b border-gray-400 text-sm text-slate-700 font-bold bg-green-400" {
                pre { "STDOUT" }
            }
            dd class="px-4 py-2 overflow-y-auto" {
                pre {
                    (run_result.stdout)
                }
            }
        }

        @if !run_result.stderr.is_empty() {
            dt class="px-4 py-1 border-t border-b border-gray-400 text-sm text-slate-700 font-bold bg-yellow-400" {
                pre { "STDERR" }
            }
            dd class="px-4 py-2 overflow-y-auto" {
                pre {
                    (run_result.stderr)
                }
            }
        }

        @if !run_result.error.is_empty() {
            dt class="px-4 py-1 border-t border-b border-gray-400 text-sm text-slate-700 font-bold bg-red-400" {
                pre { "ERROR" }
            }
            dd class="px-4 py-2 overflow-y-auto" {
                pre {
                    (run_result.error)
                }
            }
        }
    }
}

fn extract_language_version(model: &ViewModel) -> Option<String> {
    if let RemoteData::Success(run_result) = model.version_result {
        if run_result.stdout.is_empty() {
            None
        } else {
            Some(run_result.stdout.clone())
        }
    } else {
        None
    }
}
