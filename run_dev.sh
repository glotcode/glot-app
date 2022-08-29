#!/bin/bash
set -e

(
    cd dist
    python3 -m http.server 8002
)
