#!/bin/bash
set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "$0")" && pwd)"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Required command not found: $1" >&2
        exit 1
    fi
}

echo "Updating Gleam dependencies"
require_command gleam

for project in glot_core glot_web glot_backend glot_frontend; do
    echo "  $project"
    (
        cd "$REPOSITORY_ROOT/$project"
        gleam update
    )
done

echo "Updating JavaScript dependencies"
require_command npm
echo "  glot_frontend"
(
    cd "$REPOSITORY_ROOT/glot_frontend"
    npm update
)

echo "All dependencies updated"
