use std::process::Command;

fn main() {
    let commit_hash = get_commit_hash().unwrap_or_else(|| "unknown".to_string());
    println!("cargo:rustc-env=GIT_HASH={}", commit_hash);
}

fn get_commit_hash() -> Option<String> {
    let output = Command::new("git")
        .args(&["rev-parse", "HEAD"])
        .output()
        .ok()?;

    String::from_utf8(output.stdout).ok()
}
