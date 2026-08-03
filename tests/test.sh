#!/usr/bin/env bash

set -eu

BASEDIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_PARENT=${TMPDIR:-/tmp}
TEST_PARENT=${TEST_PARENT%/}
TEST_ROOT=$(mktemp -d "$TEST_PARENT/dotfiles-test.XXXXXX")

cleanup() {
    case "$TEST_ROOT" in
        "$TEST_PARENT"/dotfiles-test.*)
            rm -rf -- "$TEST_ROOT"
            ;;
        *)
            printf 'refusing to remove unexpected test directory: %s\n' "$TEST_ROOT" >&2
            ;;
    esac
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

home_clean="$TEST_ROOT/home-clean"
home_conflict="$TEST_ROOT/home-conflict"
home_legacy="$TEST_ROOT/home-legacy"
mkdir -p "$home_clean" "$home_conflict" "$home_legacy/.config"

bash -n "$BASEDIR/install.sh" "$BASEDIR/uninstall.sh" "$BASEDIR/doctor.sh"
zsh -n "$BASEDIR/.zshenv" "$BASEDIR/.zshrc"

# Fresh install, diagnostic check, shell startup without optional commands, and
# idempotent re-install.
HOME="$home_clean" SHELL=/bin/zsh "$BASEDIR/install.sh"
HOME="$home_clean" SHELL=/bin/zsh PATH=/usr/bin:/bin "$BASEDIR/doctor.sh"
HOME="$home_clean" ZDOTDIR="$home_clean" PATH=/usr/bin:/bin TERM=xterm-256color \
    zsh -dic '[[ $HISTFILE == $HOME/.zsh_history ]] && typeset -f y >/dev/null'
HOME="$home_clean" "$BASEDIR/install.sh"
HOME="$home_clean" "$BASEDIR/uninstall.sh"
test ! -L "$home_clean/.zshrc"
test ! -L "$home_clean/.config/yazi/init.lua"

# A different symlink must survive a normal install and be preserved by a
# --backup install.
touch "$home_conflict/original-zshrc"
ln -s "$home_conflict/original-zshrc" "$home_conflict/.zshrc"
if HOME="$home_conflict" "$BASEDIR/install.sh"; then
    printf 'install unexpectedly replaced a conflicting symlink\n' >&2
    exit 1
fi
test "$(readlink "$home_conflict/.zshrc")" = "$home_conflict/original-zshrc"

HOME="$home_conflict" DOTFILES_BACKUP_DIR="$home_conflict/backup" \
    "$BASEDIR/install.sh" --backup
test "$(readlink "$home_conflict/.zshrc")" = "$BASEDIR/.zshrc"
test -L "$home_conflict/backup/.zshrc"
test "$(readlink "$home_conflict/backup/.zshrc")" = "$home_conflict/original-zshrc"

# Directory symlinks made by the old installer are accepted without touching
# their contents and are removed safely by uninstall.sh.
ln -s "$BASEDIR/.config/ghostty" "$home_legacy/.config/ghostty"
HOME="$home_legacy" "$BASEDIR/install.sh"
test -f "$BASEDIR/.config/ghostty/config.ghostty"
HOME="$home_legacy" "$BASEDIR/uninstall.sh"
test ! -L "$home_legacy/.config/ghostty"
test -f "$BASEDIR/.config/ghostty/config.ghostty"

printf 'All dotfiles tests passed.\n'
