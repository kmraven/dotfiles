#!/usr/bin/env bash

set -eu

BASEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

unlink_tree() {
    local source_path=$1
    local target_path=$2
    local child

    if [ -d "$source_path" ] && [ ! -L "$source_path" ]; then
        if [ -L "$target_path" ]; then
            if [ "$(readlink "$target_path")" = "$source_path" ]; then
                rm -v "$target_path"
            fi
            return
        fi

        [ -d "$target_path" ] || return

        for child in "$source_path"/* "$source_path"/.[!.]* "$source_path"/..?*; do
            [ -e "$child" ] || [ -L "$child" ] || continue
            unlink_tree "$child" "$target_path/${child##*/}"
        done
    elif [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
        rm -v "$target_path"
    fi
}

for source_path in "$BASEDIR"/.??*; do
    name=${source_path##*/}
    [ "$name" = ".git" ] && continue
    [ "$name" = ".DS_Store" ] && continue

    unlink_tree "$source_path" "$HOME/$name"
done
