use std::process::Command;

fn main() {
    let result = Command::new("git").args(&["rev-parse", "HEAD"]).output();

    let v = match result {
        Ok(output) => String::from_utf8(output.stdout).unwrap(),

        Err(_) => "unknown".to_string(),
    };
    println!("cargo:rustc-env=GIT_HASH={}", v);
}
