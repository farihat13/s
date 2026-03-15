# ~/.bashrc - Works on both macOS & Ubuntu

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    export OS_TYPE="macOS"
    alias ls='ls -G'
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export OS_TYPE="Linux"
    alias ls='ls --color=auto'
    # Auto-install xclip if not installed
    if ! command -v xclip &> /dev/null; then
        echo "Install xclip (required for clipboard support in tmux)..."
    fi
fi

# History settings
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=10000    # Number of commands in history
export HISTFILESIZE=20000
shopt -s histappend     # Append to history instead of overwriting

# Function to get the current Git branch
git_branch() {
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    [ -n "$branch" ] && echo " ($branch)"
}

# Prompt customization (Time, Directory, Git Branch)
export PS1='\[\e[1m\]\[\e[32m\]\D{%I:%M%p} \[\e[34m\]\W\[\e[31m\]$(git_branch)\[\e[m\] -> '
export PS1='\[\e[1m\]\[\e[32m\]@\h \[\e[34m\]\W\[\e[31m\]$(git_branch)\[\e[m\] -> '

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Path setup
export PATH="$HOME/bin:$PATH"

# Default editor
export EDITOR=vim

# Enable programmable completion (if available)
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# Auto-activate venv if .venv/ exists in directory
#function cd() {
#    builtin cd "$@" || return
#    if [ -d "venv" ] && [ -f "venv/bin/activate" ]; then
#        source venv/bin/activate
#        # echo "🌀 Auto-activated venv inside $(pwd)"
#    fi
#}

# Enable Vim keybindings in Bash
set -o vi

# Load Rust Environment (if installed)
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# Apply changes
alias reload="source ~/.bashrc"
