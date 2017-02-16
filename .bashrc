# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

alias lsl='ls -l'

alias gs='git status'
alias gl='git log'

export HISTFILESIZE=20000
export HISTSIZE=10000
shopt -s histappend

# Combine multiline commands into one in history
shopt -s cmdhist

# Ignore duplicates, ls without options and builtin commands
HISTCONTROL=ignoredups
export HISTIGNORE="&:ls:[bf]g:exit"

export PS1="[\t \u@\h \W \$?]\[$(tput sgr0)\]\\$ "
