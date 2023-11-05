#!/bin/bash
set -e

git checkout release
git merge --ff-only main
git checkout main
git push origin release
