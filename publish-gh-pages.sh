#!/usr/bin/env bash

# Create orphan branch "gh-pages"
# git checkout --orphan gh-pages
# git rm -rf .
# git commit --allow-empty -m "Init empty branch"
# git push origin gh-pages -u

# Requires to have configured worktree with
# git worktree add gh-pages-static/ gh-pages

set -e
zola build --base-url https://handongchoi.com
cd gh-pages-static
git reset --hard c6fd049
cp -rH ../public/* .
git add . --force
git commit -m "Publish"
git push --force