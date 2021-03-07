# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

[[ "$-" == *i* ]] || return 0

# User specific aliases and functions
alias ll='ls -lh --color=auto --group-directories-first' 2>/dev/null
alias l.='ls -dh .* --color=auto --group-directories-first' 2>/dev/null
alias ls='ls -h --color=auto --group-directories-first' 2>/dev/null

if [[ -x "$(command -v colordiff)" ]]; then
	bindiff() { colordiff <(xxd -g 1 "$1") <(xxd -g 1 "$2") "${@:3}"; }
else
	bindiff() { diff <(xxd -g 1 "$1") <(xxd -g 1 "$2") "${@:3}"; }
fi

alias ssh='TERM="xterm-256color" ssh -x'

if [[ -x "$(command -v vimx)" && -n $DISPLAY ]]; then
	alias vi='vimx'
	alias vim='vimx'
	export EDITOR='vimx'
else
	alias vi='vim'
	export EDITOR='vim'
fi
export VIMRUNTIME="$($EDITOR --version | awk ' /f-b/ { gsub(/["]/,"",$NF); print $NF }')"

shopt -s histappend

get_git_branch() {
	# If no powerline fonts use ⎇ instead of 
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/'
}

get_venv() {
	if [ -n "$VIRTUAL_ENV" ]; then
		echo -n " 🐍${VIRTUAL_ENV##*/}"
	else
		echo -n ""
	fi
}

long_venv_prompt() {
	if [ -n "$VIRTUAL_ENV" ]; then
		printf "\n$ "
	else
		printf "$ "
	fi
}

export PS1="[${USER//[[:alnum:]]*+/}@\h \W\[\033[01m\]\$(get_git_branch)\$(get_venv)\[\033[00m\]]\$(long_venv_prompt)"
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Prevent annoying PackageKit-command-not-found messages
unset -f command_not_found_handle

