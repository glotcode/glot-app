#!/bin/bash
set -e

env="$1"
event="$2"
target="debug"


if [[ "$env" == "release" ]]; then
    target="release"
fi


if [[ "$event" == "before_asset_hash" ]]; then
    # Copy vendor assets
    mkdir -p dist/vendor/ace
    cp glot_web/vendor/ace/*.js dist/vendor/ace/

    # Copy assets
    mkdir -p dist/assets
    cp -rf glot_web/assets/* dist/assets/

fi

if [[ "$event" == "after_asset_hash" || "$env" == "dev" ]]; then
    #mkdir -p dist/new/rust

    ## Generate html
    #./target/$target/glot_cli home_page > dist/index.html
    #./target/$target/glot_cli new_rust_snippet > dist/new/rust/index.html

    # Disable cloudflare SPA mode
    echo "Not found" > dist/404.html
fi
