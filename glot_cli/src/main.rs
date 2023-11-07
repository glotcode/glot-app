use glot_core::page::home_page;
use glot_core::page::snippet_page;
use poly::page::Page;
use std::env;

fn main() {
    let args_: Vec<String> = env::args().collect();
    let args: Vec<&str> = args_.iter().map(|s| s.as_ref()).collect();

    match args[1..] {
        ["home_page"] => {
            let current_url = url::Url::parse("http://localhost/").unwrap();
            let page = home_page::HomePage { current_url };
            print_html(page);
        }

        ["new_python_snippet"] => {
            let current_url = url::Url::parse("http://localhost/new/python").unwrap();

            let page = snippet_page::SnippetPage {
                snippet: None,
                window_size: None,
                current_url,
            };

            print_html(page);
        }

        _ => {
            println!("Invalid command");
        }
    }
}

fn print_html<Model, Msg, AppEffect, Markup>(page: impl Page<Model, Msg, AppEffect, Markup>) {
    let (model, _effects) = page.init().expect("Failed to init page");
    let markup = page.view(&model);
    println!("{}", page.render_page(markup));
}
