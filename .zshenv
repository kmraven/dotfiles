# Keep non-interactive shells portable and fast.
export GOPATH="${GOPATH:-$HOME/go}"

typeset -U path PATH
path=(
    "$HOME/.local/bin"
    "$HOME/bin"
    "$GOPATH/bin"
    /usr/local/bin
    /usr/local/sbin
    $path
)

# MacPorts is only present on macOS. GNU utilities take precedence when installed.
if [[ "$OSTYPE" == darwin* ]]; then
    path=(
        /opt/local/libexec/gnubin
        /opt/local/bin
        /opt/local/sbin
        $path
    )
fi

export PATH

# Use one stable path for per-session forwarded SSH agents. Reconnecting with
# `ssh -A` refreshes the symlink, so long-lived tmux shells keep working.
_ssh_agent_link="$HOME/.ssh-agent.sock"
if [[ -n "${SSH_AUTH_SOCK:-}" && -S "$SSH_AUTH_SOCK" && "$SSH_AUTH_SOCK" != "$_ssh_agent_link" ]]; then
    if [[ ! -e "$_ssh_agent_link" || -L "$_ssh_agent_link" ]]; then
        command ln -sfn "$SSH_AUTH_SOCK" "$_ssh_agent_link" 2>/dev/null
    fi
fi
if [[ -S "$_ssh_agent_link" ]]; then
    export SSH_AUTH_SOCK="$_ssh_agent_link"
fi
unset _ssh_agent_link
