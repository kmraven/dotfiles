#!/usr/bin/env bash

set -u

BASEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MANIFEST="$BASEDIR/manifest.txt"
errors=0
warnings=0

ok() {
    printf '[ OK ] %s\n' "$1"
}

warn() {
    printf '[WARN] %s\n' "$1"
    warnings=$((warnings + 1))
}

fail() {
    printf '[FAIL] %s\n' "$1"
    errors=$((errors + 1))
}

printf 'Platform: %s %s (%s)\n' "$(uname -s)" "$(uname -r)" "$(uname -m)"

case ${HOME:-} in
    /*) ;;
    *)
        fail 'HOME must be set to an absolute path'
        printf '\nResult: %s error(s), %s warning(s)\n' "$errors" "$warnings"
        exit 1
        ;;
esac

for command_name in git zsh vim; do
    if command -v "$command_name" >/dev/null 2>&1; then
        ok "$command_name: $(command -v "$command_name")"
    else
        fail "$command_name is required but not installed"
    fi
done

for command_name in starship yazi ya micromamba pwgen docker g++ git-lfs latexmk; do
    if command -v "$command_name" >/dev/null 2>&1; then
        ok "$command_name: $(command -v "$command_name")"
    else
        warn "$command_name is optional and not installed"
    fi
done

if command -v zsh >/dev/null 2>&1; then
    if zsh -n "$BASEDIR/.zshenv" "$BASEDIR/.zshrc"; then
        ok 'zsh configuration parses successfully'
    else
        fail 'zsh configuration has a syntax error'
    fi
fi

if command -v git >/dev/null 2>&1; then
    ssl_verify=$(git config --file "$BASEDIR/.gitconfig" --get http.sslverify 2>/dev/null || true)
    if [ "$ssl_verify" = false ]; then
        fail 'Git TLS certificate verification is disabled'
    else
        ok 'Git TLS certificate verification is enabled by default'
    fi

    excludes_file=$(git config --file "$BASEDIR/.gitconfig" --get core.excludesfile 2>/dev/null || true)
    if [ "$excludes_file" = '~/.gitignore' ]; then
        ok 'Git global excludes path is portable'
    else
        fail "unexpected Git global excludes path: $excludes_file"
    fi
fi

linked=0
missing=0
conflicting=0
if [ ! -r "$MANIFEST" ]; then
    fail "manifest not found: $MANIFEST"
else
    while IFS= read -r relative_path || [ -n "$relative_path" ]; do
        case "$relative_path" in
            ''|'#'*)
                continue
                ;;
            /*|../*|*/../*|*/..|.|./*|*/./*)
                fail "invalid manifest entry: $relative_path"
                continue
                ;;
        esac

        source_file="$BASEDIR/$relative_path"
        target_file="$HOME/$relative_path"

        if [ ! -f "$source_file" ] && [ ! -L "$source_file" ]; then
            fail "manifest source is missing: $relative_path"
        elif [ -e "$target_file" ] && [ "$source_file" -ef "$target_file" ]; then
            linked=$((linked + 1))
        elif [ -e "$target_file" ] || [ -L "$target_file" ]; then
            conflicting=$((conflicting + 1))
        else
            missing=$((missing + 1))
        fi
    done < "$MANIFEST"
fi

if [ "$missing" -eq 0 ] && [ "$conflicting" -eq 0 ]; then
    ok "$linked managed files are linked"
else
    [ "$missing" -eq 0 ] || warn "$missing managed files are not installed"
    [ "$conflicting" -eq 0 ] || warn "$conflicting managed files differ from this clone"
    printf '       linked=%s missing=%s conflicting=%s\n' "$linked" "$missing" "$conflicting"
fi

if command -v yazi >/dev/null 2>&1 && [ ! -d "$HOME/.config/yazi/plugins/sshfs.yazi" ]; then
    warn 'Yazi SSHFS plugin is missing; run: ya pkg install'
fi

case ${SHELL:-} in
    */zsh)
        ok "login shell: $SHELL"
        ;;
    '')
        warn 'SHELL is not set; start zsh manually after login'
        ;;
    *)
        warn "login shell is ${SHELL}; use chsh or run 'exec zsh -l'"
        ;;
esac

printf '\nResult: %s error(s), %s warning(s)\n' "$errors" "$warnings"
[ "$errors" -eq 0 ]
