use glot_core::home_page;
use glot_core::snippet_page;
use polyester::page::Page;
use std::env;

fn main() {
    let args_: Vec<String> = env::args().collect();
    let args: Vec<&str> = args_.iter().map(|s| s.as_ref()).collect();

    match args[1..] {
        ["home_page"] => {
            let page = home_page::HomePage {};
            print_html(page);
        }

        ["snippet_page"] => {
            let page = snippet_page::SnippetPage {};
            print_html(page);
        }

        _ => {
            println!("Invalid command");
        }
    }
}

fn print_html<Model, Msg, AppEffect, Markup>(page: impl Page<Model, Msg, AppEffect, Markup>) {
    let (model, _effects) = page.init();
    let markup = page.view(&model);
    println!("{}", page.render_page(markup));
}
