# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
alias ll='ls -lh --color=auto --group-directories-first' 2>/dev/null
alias l.='ls -dh .* --color=auto --group-directories-first' 2>/dev/null
alias ls='ls -h --color=auto --group-directories-first' 2>/dev/null
if [[ -x "$(command -v vimx)" && -n $DISPLAY ]]; then alias vim='vimx'; fi

stty -ixon
shopt -s histappend

export EDITOR='vim'

get_git_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

export PS1="[${USER//[[:alnum:]]*+/}@\h \W\[\033[01m\]\$(get_git_branch)\[\033[00m\]]$ "

