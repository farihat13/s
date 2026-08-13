# ~/.bashrc - Works on both macOS & Ubuntu

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    export OS_TYPE="macOS"
    alias ls='ls -G'
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export OS_TYPE="Linux"
    alias ls='ls --color=auto'
fi

# History settings
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=10000    # Number of commands in history
export HISTFILESIZE=20000
export HISTTIMEFORMAT='%F %T '   # show date+time in `history` output
shopt -s histappend     # Append to history instead of overwriting
shopt -s checkwinsize   # keep $LINES/$COLUMNS correct after a resize

# Function to get the current Git branch, with a '*' when there are
# uncommitted changes. Dirty check is tracked-only (skips the slow untracked
# /LFS scan) and ignores submodules, so it stays fast in this big repo.
git_branch() {
    local branch dirty=""
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
    [ -z "$branch" ] && return
    if ! git diff --quiet --ignore-submodules 2>/dev/null \
       || ! git diff --cached --quiet --ignore-submodules 2>/dev/null; then
        dirty="*"
    fi
    echo " ($branch$dirty)"
}

# --- Command timer + last-exit status (shown in the prompt) ---
# DEBUG fires before every command -> record a start time (once per command line).
# PROMPT_COMMAND fires before each prompt -> compute how long the command ran,
# grab its exit code, and append this shell's new history (shared across panes).
# Uses $SECONDS (1s granularity) so it works on macOS bash 3.2 too.
__timer_start() { __cmd_start=${__cmd_start:-$SECONDS}; }
__fmt_dur() {                                  # 92 -> "1m 32s"; 3720 -> "1h 2m 0s"
    local s=$1 out=""
    (( s >= 3600 )) && { out+="$(( s/3600 ))h "; s=$(( s%3600 )); }
    (( s >= 60 ))   && { out+="$(( s/60 ))m ";   s=$(( s%60 )); }
    out+="${s}s"; printf '%s' "$out"
}
__prompt() {
    local ec=$?
    local secs=$(( SECONDS - ${__cmd_start:-$SECONDS} ))
    # only show a duration for commands that took a noticeable time (>= 2s).
    # leading space each, so a clean prompt has no trailing double-space.
    (( secs >= 2 )) && __cmd_time=" $(__fmt_dur "$secs")" || __cmd_time=""
    (( ec != 0 ))   && __exit_str=" [$ec]"                || __exit_str=""
    # prompt arrow: green on success, red on failure (real ESC, not \e, so it
    # expands correctly when substituted into PS1)
    (( ec == 0 )) && __psym_color=$'\e[1;32m' || __psym_color=$'\e[1;31m'
    history -a                 # persist new history now (so tmux panes share it)
    unset __cmd_start          # MUST stay the last statement (see note above)
}
trap '__timer_start' DEBUG
PROMPT_COMMAND=__prompt

# Prompt:  host  dir (branch*) [exit] dur ❯
#   host = bold green, dir = blue, branch = red, [exit] = red, duration = yellow,
#   arrow = green on success / red on failure
__psym_color=$'\e[1;32m'   # default (green) until the first command completes
PS1='\[\e[1;32m\]\h  \[\e[34m\]\W\[\e[31m\]$(git_branch)\[\e[31m\]${__exit_str}\[\e[33m\]${__cmd_time}\[\e[0m\] \[${__psym_color}\]❯\[\e[0m\] '

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
