#!/usr/bin/env bash

set -u

BASEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MANIFEST="$BASEDIR/manifest.txt"
BACKUP=0
had_conflict=0
backup_used=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [--backup]

Link the files in manifest.txt into $HOME.

  --backup  Move conflicting files to ~/.dotfiles-backup/<timestamp>/ first.
  -h, --help
            Show this help.

Without --backup, conflicting files and symlinks are left untouched.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --backup)
            BACKUP=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

case ${HOME:-} in
    /*) ;;
    *)
        printf 'HOME must be set to an absolute path.\n' >&2
        exit 2
        ;;
esac

if [ "$HOME" = / ]; then
    printf 'Refusing to install with HOME=/.\n' >&2
    exit 2
fi

if [ ! -r "$MANIFEST" ]; then
    printf 'manifest not found: %s\n' "$MANIFEST" >&2
    exit 2
fi

BACKUP_ROOT=${DOTFILES_BACKUP_DIR:-"$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"}

backup_item() {
    local target_file=$1
    local relative_path=${target_file#"$HOME"/}
    local backup_file="$BACKUP_ROOT/$relative_path"

    if [ -e "$backup_file" ] || [ -L "$backup_file" ]; then
        printf 'skip (backup destination exists): %s\n' "$backup_file" >&2
        return 1
    fi

    mkdir -p "$(dirname -- "$backup_file")" || return 1
    mv -- "$target_file" "$backup_file" || return 1
    printf 'backed up: %s -> %s\n' "$target_file" "$backup_file"
    backup_used=1
}

link_file() {
    local source_file=$1
    local target_file=$2
    local target_parent

    target_parent=$(dirname -- "$target_file")
    if ! mkdir -p "$target_parent"; then
        printf 'skip (cannot create parent directory): %s\n' "$target_parent" >&2
        had_conflict=1
        return
    fi

    # Older versions linked some whole directories. In that case the target is
    # already the source file through a parent symlink and must not be removed.
    if [ -e "$target_file" ] && [ "$source_file" -ef "$target_file" ]; then
        printf 'already linked: %s\n' "$target_file"
        return
    fi

    if [ -L "$target_file" ]; then
        if [ "$(readlink "$target_file")" = "$source_file" ]; then
            printf 'already linked: %s\n' "$target_file"
            return
        fi

        if [ "$BACKUP" -eq 1 ] && backup_item "$target_file"; then
            :
        else
            printf 'skip (different symlink exists): %s\n' "$target_file" >&2
            had_conflict=1
            return
        fi
    elif [ -e "$target_file" ]; then
        if [ -f "$target_file" ] && cmp -s "$source_file" "$target_file"; then
            if ! rm -- "$target_file"; then
                printf 'skip (cannot replace identical file): %s\n' "$target_file" >&2
                had_conflict=1
                return
            fi
        elif [ "$BACKUP" -eq 1 ] && backup_item "$target_file"; then
            :
        else
            printf 'skip (different file exists): %s\n' "$target_file" >&2
            had_conflict=1
            return
        fi
    fi

    if ! ln -snv "$source_file" "$target_file"; then
        printf 'failed to link: %s\n' "$target_file" >&2
        had_conflict=1
    fi
}

while IFS= read -r relative_path || [ -n "$relative_path" ]; do
    case "$relative_path" in
        ''|'#'*)
            continue
            ;;
        /*|../*|*/../*|*/..|.|./*|*/./*)
            printf 'invalid manifest entry: %s\n' "$relative_path" >&2
            had_conflict=1
            continue
            ;;
    esac

    source_file="$BASEDIR/$relative_path"
    target_file="$HOME/$relative_path"

    if [ ! -f "$source_file" ] && [ ! -L "$source_file" ]; then
        printf 'missing source listed in manifest: %s\n' "$source_file" >&2
        had_conflict=1
        continue
    fi

    link_file "$source_file" "$target_file"
done < "$MANIFEST"

if [ "$backup_used" -eq 1 ]; then
    printf 'Backup directory: %s\n' "$BACKUP_ROOT"
fi

if [ "$had_conflict" -ne 0 ]; then
    printf 'Some files were not linked. Re-run with --backup to preserve and replace conflicts.\n' >&2
    exit 1
fi
