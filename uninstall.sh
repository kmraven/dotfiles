#!/usr/bin/env bash

set -u
BASEDIR=$(dirname "$0")
cd "$BASEDIR"

for f in .??*; do
    [ "$f" = ".git" ] && continue

    if [ -d "$f" ]; then
        for sub_file in "$f"/*; do
            target_file=~/"$sub_file"
            if [ -L "$target_file" ]; then
                echo "Removing symlink: $target_file"
                rm -v "$target_file"
            fi
        done
    else
        target_file=~/"$f"
        if [ -L "$target_file" ]; then
            echo "Removing symlink: $target_file"
            rm -v "$target_file"
        fi
    fi
done
