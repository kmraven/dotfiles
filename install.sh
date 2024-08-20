#!/usr/bin/env bash

set -u
BASEDIR=$(dirname "$0")
cd "$BASEDIR"

for f in .??*; do
    [ "$f" = ".git" ] && continue

    if [ -d "$f" ]; then
        mkdir -p ~/"$f"
        for sub_file in "$f"/*; do
            ln -snfv "${PWD}/$sub_file" ~/"$f"/
        done
    else
        ln -snfv "${PWD}/$f" ~/
    fi
done
