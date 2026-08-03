#!/usr/bin/env bash

set -eu

BASEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MANIFEST="$BASEDIR/manifest.txt"

case ${HOME:-} in
    /*) ;;
    *)
        printf 'HOME must be set to an absolute path.\n' >&2
        exit 2
        ;;
esac

if [ "$HOME" = / ]; then
    printf 'Refusing to uninstall with HOME=/.\n' >&2
    exit 2
fi

if [ ! -r "$MANIFEST" ]; then
    printf 'manifest not found: %s\n' "$MANIFEST" >&2
    exit 2
fi

is_managed_symlink() {
    local source_path=$1
    local target_path=$2

    [ -L "$target_path" ] || return 1
    [ "$(readlink "$target_path")" = "$source_path" ] && return 0
    [ -e "$source_path" ] && [ -e "$target_path" ] && [ "$source_path" -ef "$target_path" ]
}

# Remove directory-level links created by older versions of install.sh. Only a
# symlink that resolves to the corresponding directory in this clone is ours.
while IFS= read -r relative_path || [ -n "$relative_path" ]; do
    case "$relative_path" in
        ''|'#'*)
            continue
            ;;
        /*|../*|*/../*|*/..|.|./*|*/./*)
            printf 'invalid manifest entry: %s\n' "$relative_path" >&2
            exit 2
            ;;
    esac

    relative_dir=$(dirname -- "$relative_path")
    while [ "$relative_dir" != . ]; do
        source_dir="$BASEDIR/$relative_dir"
        target_dir="$HOME/$relative_dir"
        if is_managed_symlink "$source_dir" "$target_dir"; then
            rm -v -- "$target_dir"
            break
        fi
        relative_dir=$(dirname -- "$relative_dir")
    done
done < "$MANIFEST"

while IFS= read -r relative_path || [ -n "$relative_path" ]; do
    case "$relative_path" in
        ''|'#'*)
            continue
            ;;
        /*|../*|*/../*|*/..|.|./*|*/./*)
            printf 'invalid manifest entry: %s\n' "$relative_path" >&2
            exit 2
            ;;
    esac

    source_file="$BASEDIR/$relative_path"
    target_file="$HOME/$relative_path"

    if is_managed_symlink "$source_file" "$target_file"; then
        rm -v -- "$target_file"
    fi
done < "$MANIFEST"
