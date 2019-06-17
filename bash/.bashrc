if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

alias ll='ls -l --color=auto --group-directories-first' 2>/dev/null
alias l.='ls -d .* --color=auto --group-directories-first' 2>/dev/null
alias ls='ls --color=auto --group-directories-first' 2>/dev/null

stty -ixon

get_git_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

export PS1="[${USER//[[:alnum:]]*+/}@\h \W\[\033[01m\]\$(get_git_branch)\[\033[00m\]]$ "

