# Cross-platform interactive zsh configuration.

if command ls --color=auto -d . >/dev/null 2>&1; then
    alias ls='ls --color=auto -F'
else
    alias ls='ls -GF'
fi

alias ll='ls -al'
alias la='ls -a'
alias g='git'
alias vzsh='vim ~/.zshrc'
alias szsh='source ~/.zshrc'
alias dc='docker compose'
alias dps='docker ps -a'
alias gpp='g++ -std=c++17 -g -Wall'

if (( $+commands[pwgen] )); then
    alias pwgen='pwgen -c -n -y -B -1 12'
fi

# Do not overwrite DISPLAY supplied by SSH forwarding. Use :0 only when a local
# X server is actually available (for example, a Linux remote desktop session).
if [[ -z ${DISPLAY:-} && -S /tmp/.X11-unix/X0 ]]; then
    export DISPLAY=:0
fi

if (( $+commands[vim] )); then
    export EDITOR=vim
else
    export EDITOR=vi
fi
export VISUAL="$EDITOR"

# Preserve an explicitly configured JAVA_HOME. Otherwise discover a local JDK.
if [[ -z ${JAVA_HOME:-} ]]; then
    if [[ -d /Library/Java/JavaVirtualMachines/openjdk8-zulu/Contents/Home ]]; then
        export JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk8-zulu/Contents/Home
    elif [[ -x /usr/libexec/java_home ]]; then
        java_home=$(/usr/libexec/java_home 2>/dev/null)
        [[ -n "$java_home" ]] && export JAVA_HOME="$java_home"
        unset java_home
    elif (( $+commands[java] )); then
        java_bin=${commands[java]:A}
        export JAVA_HOME=${java_bin:h:h}
        unset java_bin
    fi
fi

unalias run-help 2>/dev/null
autoload -Uz run-help

function chpwd() {
    ls
}

# Edit the current command line with $VISUAL/$EDITOR using Ctrl-X Ctrl-E.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

autoload -Uz compinit
zsh_cache_dir=${XDG_CACHE_HOME:-"$HOME/.cache"}/zsh
if mkdir -p "$zsh_cache_dir" 2>/dev/null; then
    compinit -d "$zsh_cache_dir/zcompdump"
else
    compinit
fi
unset zsh_cache_dir

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*default' menu select=1

fignore=(.o \~ .aux .log .bbl .blg .dvi .lof .lot .toc .synctex.gz .fdb_latexmk .fls)
WORDCHARS=${WORDCHARS:s/\//}

setopt IGNORE_EOF
unsetopt CORRECT
setopt EXTENDED_HISTORY
setopt AUTO_CD
setopt AUTO_PUSHD
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_NO_STORE
unsetopt EXTENDED_GLOB

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^P' history-beginning-search-backward-end
bindkey '^N' history-beginning-search-forward-end

# Initialize optional tools only when they are installed.
if (( $+commands[micromamba] )); then
    export MAMBA_EXE=${commands[micromamba]}
    export MAMBA_ROOT_PREFIX=${MAMBA_ROOT_PREFIX:-"$HOME/micromamba"}
    __mamba_setup="$($MAMBA_EXE shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2>/dev/null)"
    if [[ $? -eq 0 ]]; then
        eval "$__mamba_setup"
        alias conda='micromamba'
    fi
    unset __mamba_setup
fi

if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
fi

function y() {
    if (( ! $+commands[yazi] )); then
        print -u2 'yazi is not installed'
        return 127
    fi

    local tmp_dir=${TMPDIR:-/tmp}
    local tmp cwd status
    tmp=$(mktemp "${tmp_dir%/}/yazi-cwd.XXXXXX") || return 1

    command yazi "$@" --cwd-file="$tmp"
    status=$?
    IFS= read -r -d '' cwd < "$tmp"
    command rm -f -- "$tmp"

    if [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]]; then
        builtin cd -- "$cwd"
    fi
    return $status
}

# Per-machine secrets and overrides belong here, outside this repository.
if [[ -r "$HOME/.zshrc.local" ]]; then
    source "$HOME/.zshrc.local"
fi
