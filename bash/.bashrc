# .bashrc

# Source global definitions
if [[ -f /etc/bashrc ]]; then
	. /etc/bashrc
fi

# Not an interactive shell?
[[ "$-" == *i* ]] || return 0

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Set umask
umask 027

# User specific aliases and functions
alias ll='ls -lh --color=auto --group-directories-first' 2>/dev/null
alias l.='ls -dh .* --color=auto --group-directories-first' 2>/dev/null
alias ll.='ls -dlh .* --color=auto --group-directories-first' 2>/dev/null
alias ls='ls -h --color=auto --group-directories-first' 2>/dev/null
alias diff='diff --color=auto -ud'

# Prevent expensive mistakes
if [[ "$EUID" -eq 0 ]]; then
	alias rm='rm -i'
	alias cp='cp -i'
	alias mv='mv -i'
fi

lll() { stat --printf="%A %#03a %h %4U %4G %s %.19y %n (%C)\n" * | numfmt --to=iec-i --field=6 --padding=5; }
lll.() { stat --printf="%A %#03a %h %4U %4G %s %.19y %n (%C)\n" .* | numfmt --to=iec-i --field=6 --padding=5; }

bindiff() { diff --color=auto -ud <(xxd -g 1 "$1") <(xxd -g 1 "$2") "${@:3}"; }

if [[ -x "$(command -v vimx)" && -n "$DISPLAY" ]]; then
	alias vi='vimx'
	alias vim='vimx'
	export EDITOR='vimx'
else
	alias vi='vim'
	export EDITOR='vim'
fi
export VIMRUNTIME="$($EDITOR --version | awk ' /f-b/ { gsub(/["]/,"",$NF); print $NF }')"
export MERGE="vimdiff"

if [[ -x "$(command -v uname)" ]]; then
	export HOSTNAME=$(uname -n)
fi

shopt -s histappend
shopt -s checkwinsize

get_git_branch() {
	# If no powerline fonts use ⎇ instead of 
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/'
}

get_venv() {
	if [[ -n "$VIRTUAL_ENV" ]]; then
		# Alternate symbols: 🐍
		printf ' 🐍%s' "${VIRTUAL_ENV##*/}"
	fi
}

long_venv_prompt() {
	if [[ -n "$VIRTUAL_ENV" ]]; then
		printf '\n'
	fi
}

get_jobs() {
	local j='\j'
	local jj="${j@P}"
	if [[ "$jj" -gt 0 ]]; then
		printf ' ⏳%s' "$jj"
	fi
}

get_ssh() {
	if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
		printf ' 💻'
	fi
}

red_if_root() {
	if [[ "$EUID" -eq 0 ]]; then
		printf '\e[1;31m'
	fi
}

export PS1="\[\$(red_if_root)\][\u@\h\$(get_ssh) \W\[\e[01m\]\$(get_jobs)\$(get_git_branch)\$(get_venv)\[\e[00m\$(red_if_root)\]]\$(long_venv_prompt)\\$\[\e[00m\] "
export VIRTUAL_ENV_DISABLE_PROMPT=1
export GOPATH=$HOME/go

preexec() {
	STARTTIME=$EPOCHSECONDS
}

postexec() {
	STARTTIME=$(HISTTIMEFORMAT='%s ' history 1 | awk '{print $2}')
}

precmd() {
	local st=$(HISTTIMEFORMAT='%s ' history 1 | awk '{print $2}')
	if [[ -z "$STARTTIME" || (-n "$STARTTIME" && "$STARTTIME" -ne "$st") ]]; then
		ENDTIME=$EPOCHSECONDS
		STARTTIME=$st
	else
		ENDTIME=0
	fi
}

# Notify OS of local folder URL
__vte_osc7() {
	printf '\e]7;file://%s%s\e\\' "${HOSTNAME}" "$(/usr/libexec/vte-urlencode-cwd)"
}

# Notify kitty when command completes (similar styling as OSC 777 on gnome-terminal)
# Parameters: $1 = command
# Workaround: we use postexec as preexec runs inside a subshell
__vte_osc99() {
	precmd
	# postexec
	if ((ENDTIME - STARTTIME >= 300)); then
		printf '\e]99;d=0:p=title;Command completed\e\\'
		printf '\e]99;d=1:p=body;%s\e\\' "$1"
	fi
}

# For timing how long a command took to run
__vte_osc99pre() {
	preexec
}

# Notify urxvt and gnome-terminal (for non-kitty usage)
# Parameters: $1 = command
__vte_osc777() {
	printf '\e]777;notify;Command completed;%s\e\\' "$1"
	printf '\e]777;precmd\e\\'
}

# For timing how long a command took to run
__vte_osc777pre() {
	printf '\e]777;preexec\e\\'
}

# Set title using OSC 0
# Parameters: $1 = user, $2 = hostname, $3 = pwd
__vte_osc0() {
	if [[ -x "$(command -v tty)" ]]; then
		local ttydev=$(tty | sed -e s,^/dev/,,)
	fi
	printf '\e]0;%s@%s:%s [%s]\e\\' "$1" "$2" "$3" "$ttydev"
}

case "$TERM" in
	*kitty)
		alias ssh='TERM="xterm-256color" ssh -ax'

		__vte_prompt_command() {
			local command=$(HISTTIMEFORMAT= history 1 | sed 's/^ *[0-9]\+ *//')
			local pwd='~'
			[[ "$PWD" != "$HOME" ]] && pwd=${PWD/#$HOME\//\~\/}
			pwd="${pwd//[[:cntrl:]]}"
			__vte_osc0 "${USER}" "${HOSTNAME%%.*}" "${pwd}"
			__vte_osc99 "${command//[[:cntrl:]]}"
		}

		export PS0=$(__vte_osc99pre)
		export PROMPT_COMMAND=__vte_prompt_command
		;;

	xterm*|vte*)
		alias ssh='ssh -ax'

		__vte_prompt_command() {
			local command=$(HISTTIMEFORMAT= history 1 | sed 's/^ *[0-9]\+ *//')
			local pwd='~'
			[[ "$PWD" != "$HOME" ]] && pwd=${PWD/#$HOME\//\~\/}
			pwd="${pwd//[[:cntrl:]]}"
			__vte_osc0 "${USER}" "${HOSTNAME%%.*}" "${pwd}"
			__vte_osc777 "${command//;/ }"
			__vte_osc7
		}

		export PS0=$(__vte_osc777pre)
		export PROMPT_COMMAND=__vte_prompt_command
		;;

	screen*)
		alias ssh='ssh -ax'

		export PS0=
		export PROMPT_COMMAND=
		;;

	*)
		;;
esac

# Prevent annoying PackageKit-command-not-found messages
unset -f command_not_found_handle

