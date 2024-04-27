alias emacs="/Applications/MacPorts/Emacs.app/Contents/MacOS/Emacs -nw"
alias e='emacs'
alias ls='ls -GF'
alias ll='ls -al'
alias la='ls -a'
alias g='git'
alias vzsh='vim ~/.zshrc'
alias szsh='source ~/.zshrc'
alias dc='docker-compose'
alias dps='docker ps -a'
alias del='mv $* ~/.Trash/'
alias gpp='g++ -std=c++17 -g -Wall'

[ -n "`alias run-help`" ] && unalias run-help
autoload run-help

chpwd() {
	ls;
}

fignore=(.o \~ .aux .log .bbl .blg .dvi .lof .lot .toc .synctex.gz .fdb_latexmk .fls)
WORDCHARS=$WORDCHARS:s/\//

export JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk8-zulu/Contents/Home
export EDITOR='vim'
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

autoload -U compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*default' menu select=1

setopt IGNORE_EOF
unsetopt CORRECT
setopt EXTENDED_HISTORY
setopt AUTO_CD
setopt AUTO_PUSHD
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_NO_STORE
unsetopt EXTENDED_GLOB

export LSCOLORS=gxfxcxdxbxegedabagacad
zstyle ':completion:*' list-colors di=36 ln=35 ex=31 '=*.c=33' '=*.py=33'

export SAVEHIST=100000
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# remote desktopのために設定
export DISPLAY=:0

eval "$(starship init zsh)"
starship preset nerd-font-symbols -o ~/.config/starship.toml
