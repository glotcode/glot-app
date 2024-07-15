use glot_core::page::home_page;
use glot_core::page::snippet_page;
use poly::page::Page;
use std::env;
use url::Url;

fn main() {
    let args_: Vec<String> = env::args().collect();
    let mut args: Vec<&str> = args_.iter().map(|s| s.as_ref()).collect();

    if let Some(url_path) = args.pop() {
        let url = Url::parse(&format!("http://localhost{}", url_path)).unwrap();
        handle_url(url)
    } else {
        println!("Expected path as first argument")
    }
}

fn handle_url(current_url: Url) {
    let parts: Vec<&str> = current_url.path().split("/").collect();

    match parts[1..] {
        [""] => {
            let page = home_page::HomePage { current_url };
            print_html(page);
        }

        ["new", _language] => {
            let page = snippet_page::SnippetPage {
                snippet: None,
                window_size: None,
                current_url,
            };

            print_html(page);
        }

        _ => {
            println!("Invalid path: {}", current_url.path());
        }
    }
}

fn print_html<Model, Msg, AppEffect, Markup>(page: impl Page<Model, Msg, AppEffect, Markup>) {
    let (model, _effects) = page.init().expect("Failed to init page");
    let markup = page.view(&model);
    println!("{}", page.render_page(markup));
}
