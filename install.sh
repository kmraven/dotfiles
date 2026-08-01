#!/usr/bin/env bash

set -eu

BASEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
had_conflict=0

link_file() {
    local source_file=$1
    local target_file=$2

    if [ -L "$target_file" ]; then
        ln -snfv "$source_file" "$target_file"
    elif [ -e "$target_file" ]; then
        if cmp -s "$source_file" "$target_file"; then
            ln -snfv "$source_file" "$target_file"
        else
            printf 'skip (different file exists): %s\n' "$target_file" >&2
            had_conflict=1
        fi
    else
        ln -snv "$source_file" "$target_file"
    fi
}

link_tree() {
    local source_path=$1
    local target_path=$2
    local child

    if [ -d "$source_path" ] && [ ! -L "$source_path" ]; then
        if [ -L "$target_path" ]; then
            if [ "$(readlink "$target_path")" = "$source_path" ]; then
                printf 'already linked: %s\n' "$target_path"
            else
                printf 'skip (directory symlink exists): %s\n' "$target_path" >&2
                had_conflict=1
            fi
            return
        fi

        if [ -e "$target_path" ] && [ ! -d "$target_path" ]; then
            printf 'skip (non-directory exists): %s\n' "$target_path" >&2
            had_conflict=1
            return
        fi

        mkdir -p "$target_path"

        # Include both normal and hidden entries. Non-matching globs are skipped.
        for child in "$source_path"/* "$source_path"/.[!.]* "$source_path"/..?*; do
            [ -e "$child" ] || [ -L "$child" ] || continue
            link_tree "$child" "$target_path/${child##*/}"
        done
    else
        link_file "$source_path" "$target_path"
    fi
}

for source_path in "$BASEDIR"/.??*; do
    name=${source_path##*/}
    [ "$name" = ".git" ] && continue
    [ "$name" = ".DS_Store" ] && continue

    link_tree "$source_path" "$HOME/$name"
done

if [ "$had_conflict" -ne 0 ]; then
    printf 'Some files were not linked because different files already exist.\n' >&2
    exit 1
fi
