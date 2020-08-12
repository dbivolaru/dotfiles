# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

[[ "$-" == *i* ]] || return 0

# User specific aliases and functions
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -lh --color=auto --group-directories-first' 2>/dev/null
alias l.='ls -dh .* --color=auto --group-directories-first' 2>/dev/null
alias ls='ls -h --color=auto --group-directories-first' 2>/dev/null
if [[ -x "$(command -v vimx)" && -n $DISPLAY ]]; then alias vim='vimx'; fi

stty -ixon

export EDITOR='vim'

PS1='\[\e[1;31m\][\u@\h \W]\$\[\e[0m\] '

