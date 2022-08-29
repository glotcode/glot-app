use glot_core::home_page;
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

        _ => {
            println!("Invalid command");
        }
    }
}

fn print_html<Model, Msg, AppEffect>(page: impl Page<Model, Msg, AppEffect>) {
    let (model, _effects) = page.init();
    let page = page.view(&model);
    println!("{}", page.to_markup().into_string());
}
