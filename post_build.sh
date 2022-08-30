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
    cp glot_web/vendor/ace/worker-html.js dist/vendor/ace
    cp glot_web/vendor/ace/ace.js dist/vendor/ace
    cp glot_web/vendor/ace/mode-html.js dist/vendor/ace
    cp glot_web/vendor/ace/keybinding-vim.js dist/vendor/ace
    cp glot_web/vendor/ace/keybinding-emacs.js dist/vendor/ace
fi

if [[ "$event" == "after_asset_hash" || "$env" == "dev" ]]; then
    mkdir -p dist/snippet

    # Generate html
    ./target/$target/glot_cli home_page > dist/index.html
    ./target/$target/glot_cli snippet_page > dist/snippet/index.html
fi
