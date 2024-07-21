#!/bin/bash
set -e

env="$1"
event="$2"
target="debug"

static_base="dist/static"


if [[ "$env" == "release" ]]; then
    target="release"
fi


if [[ "$event" == "before_asset_hash" ]]; then
    mkdir -p "$static_base"

    # Copy static assets
    mkdir -p "$static_base/assets"
    cp -rf glot_web/static/* "$static_base/"
fi

# Copy Cloudflare SPA routing config
cp glot_cloudflare/_routes.json dist/

# Copy Cloudflare redirects config
cp glot_cloudflare/_redirects dist/