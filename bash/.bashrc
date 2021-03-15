# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Not an interactive shell?
[[ "$-" == *i* ]] || return 0

# User specific aliases and functions
alias ll='ls -lh --color=auto --group-directories-first' 2>/dev/null
alias l.='ls -dh .* --color=auto --group-directories-first' 2>/dev/null
alias ls='ls -h --color=auto --group-directories-first' 2>/dev/null
alias diff='diff --color=auto -ud'

bindiff() { diff --color=auto -ud <(xxd -g 1 "$1") <(xxd -g 1 "$2") "${@:3}"; }

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
shopt -s checkwinsize

get_git_branch() {
	# If no powerline fonts use ⎇ instead of 
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/'
}

get_venv() {
	if [ -n "$VIRTUAL_ENV" ]; then
		# Alternate symbols: 🐍
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

export PS1="[\u@\h:\j \W\[\e[01m\]\$(get_git_branch)\$(get_venv)\[\e[00m\]]\$(long_venv_prompt)"
export VIRTUAL_ENV_DISABLE_PROMPT=1

case "$TERM" in
	*kitty)
		alias ssh='TERM="xterm-256color" ssh -x'

		preexec() {
			STARTTIME=$EPOCHSECONDS
		}

		postexec() {
			STARTTIME=$(HISTTIMEFORMAT='%s ' history 1 | awk '{print $2}');
		}

		precmd() {
			local st=$(HISTTIMEFORMAT='%s ' history 1 | awk '{print $2}');
			printf 'st=%d STARTTIME=%d\n' "$st" "$STARTTIME";
			if [[ -z "$STARTTIME" || (-n "$STARTTIME" && "$STARTTIME" -ne "$st") ]]; then
				ENDTIME=$EPOCHSECONDS
				STARTTIME=$st
			else
				ENDTIME=0
			fi
		}

		# Notify OS of local folder URL
		__vte_osc7() {
			printf '\e]7;file://%s%s\e\\' "${HOSTNAME}" "$(/usr/libexec/vte-urlencode-cwd)";
		}

		# Notify kitty when command completes (similar styling as OSC 777 on gnome-terminal)
		# Parameters: $1 = command
		# Workaround: we use postexec as preexec runs inside a subshell
		__vte_osc99() {
			precmd;
			# postexec;
			if ((ENDTIME - STARTTIME >= 5)); then
				printf '\e]99;d=0:p=title;Command completed\e\\';
				printf '\e]99;d=1:p=body;%s\e\\' "$1";
			fi
		}

		# For timing how long a command took to run
		__vte_osc99pre() {
			preexec;
		}

		# Notify urxvt and gnome-terminal (for non-kitty usage)
		# Parameters: $1 = command
		__vte_osc777() {
			printf '\e]777;notify;Command completed;%s\e\\' "$1";
			printf '\e]777;precmd\e\\';
		}

		# For timing how long a command took to run
		__vte_osc777pre() {
			printf '\e]777;preexec\e\\';
		}

		# Set title using OSC 0
		# Parameters: $1 = user, $2 = hostname, $3 = pwd
		__vte_osc0() {
			printf '\e]0;%s@%s:%s\e\\' "$1" "$2" "$3";
		}

		__vte_prompt_command() {
			local command=$(HISTTIMEFORMAT= history 1 | sed 's/^ *[0-9]\+ *//');
			local pwd='~';
			[ "$PWD" != "$HOME" ] && pwd=${PWD/#$HOME\//\~\/};
			pwd="${pwd//[[:cntrl:]]}";
			__vte_osc0 "${USER}" "${HOSTNAME%%.*}" "${pwd}";
			__vte_osc777 "${command//;/ }";
			__vte_osc99 "${command//[[:cntrl:]]}";
			__vte_osc7;
		}

		export PS0=$(__vte_osc777pre;__vte_osc99pre)
		export PROMPT_COMMAND=__vte_prompt_command
		;;

	xterm*|vte*)
		alias ssh='ssh -x'
		;;

	screen*)
		;;

	*)
		;;
esac

# Prevent annoying PackageKit-command-not-found messages
unset -f command_not_found_handle

