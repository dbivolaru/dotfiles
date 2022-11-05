# .bashrc

# Source global definitions
if [[ -f /etc/bashrc ]]; then
	. /etc/bashrc
fi

# User specific environment and startup programs
GOPATH=$HOME/go
PATH=$PATH:$HOME/.local/bin:$HOME/bin:$HOME/scripts:$GOPATH/bin

# Setup podman in place of docker (including rootless detection)
if [[ -x "$(command -v podman)" ]]; then
	alias docker=podman
	if [[ -x "$(command -v systemctl)" ]]; then
		systemctl --user is-active podman.socket >/dev/null 2>&1; podman_rootless=$?
		if [[ -S "/run/user/$UID/podman/podman.sock" && $podman_rootless -eq 0 ]]; then
			DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock
		fi
	fi
fi

# Prevent expensive mistakes
if [[ "$EUID" -eq 0 ]]; then
	alias rm='rm -i'
	alias cp='cp -i'
	alias mv='mv -i'
fi

# Not an interactive shell?
[[ "$-" == *i* ]] || return 0

# Set umask
umask 027

# User specific aliases and functions
alias ll='ls -lh --color=auto --group-directories-first' 2>/dev/null
alias l.='ls -dh .* --color=auto --group-directories-first' 2>/dev/null
alias ll.='ls -dlh .* --color=auto --group-directories-first' 2>/dev/null
alias ls='ls -h --color=auto --group-directories-first' 2>/dev/null
alias diff='diff --color=auto -ud'

lll() { stat --printf="%A %#03a %h %4U %4G %s %.19y %n (%C)\n" * | numfmt --to=iec-i --field=6 --padding=5; }
lll.() { stat --printf="%A %#03a %h %4U %4G %s %.19y %n (%C)\n" .* | numfmt --to=iec-i --field=6 --padding=5; }

bindiff() { diff --color=auto -ud <(xxd -g 1 "$1") <(xxd -g 1 "$2") "${@:3}"; }

if [[ -x "$(command -v vimx)" && -n "$DISPLAY" ]]; then
	alias vi='vimx'
	alias vim='vimx'
	EDITOR='vimx'
else
	alias vi='vim'
	EDITOR='vim'
fi
VIMRUNTIME="$($EDITOR --version | awk ' /f-b/ { gsub(/["]/,"",$NF); print $NF }')"
MERGE="vimdiff"
VIRTUAL_ENV_DISABLE_PROMPT=1

if [[ -x "$(command -v uname)" ]]; then
	HOSTNAME=$(uname -n)
fi

# TODO Kitty integration ... but ours is so much better
# if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
# 	KITTY_SHELL_INTEGRATION="enabled"
# 	source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"
# fi

# Turn on parallel history, de-duplicate last command, ignore commands starting with space
shopt -s histappend
HISTFILESIZE=100000
HISTSIZE=100000
HISTCONTROL=ignoreboth
HISTIGNORE="?:??:ls *:pwd:history:history *:exit:logout:df *:du *:ps *:man *:sudo su -:su -"

# Turn on window resize checking
shopt -s checkwinsize

# Jobs running when exiting
shopt -s checkjobs
shopt -s huponexit

get_time() {
	local t=$(date +%H:%M)
	printf '[%s]' "$t"
}

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

PS1="\[\$(red_if_root)\][\u@\h\$(get_ssh) \W\[\e[01m\]\$(get_jobs)\$(get_git_branch)\$(get_venv)\[\e[00m\$(red_if_root)\]]\$(long_venv_prompt)\\$\[\e[00m\] "
PS2=

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
	local hostname='\h'
	hostname="${hostname@P}"
	printf '\e]7;file://%s%s\e\\' "${hostname}" "$(/usr/libexec/vte-urlencode-cwd)"
}

# Notify kitty when command completes (similar styling as OSC 777 on gnome-terminal)
# Parameters: $1 = command
# Workaround: we use postexec as preexec runs inside a subshell
__vte_osc99() {
	local command=$(HISTTIMEFORMAT= history 1 | sed 's/^ *[0-9]\+ *//')
	precmd
	# postexec
	if ((ENDTIME - STARTTIME >= 300)); then
		printf '\e]99;d=0:p=title;Command completed\e\\'
		printf '\e]99;d=1:p=body;%s\e\\' "${command//[[:cntrl:]]}"
	fi
}

# For timing how long a command took to run
__vte_osc99pre() {
	preexec
}

# Notify urxvt and gnome-terminal (for non-kitty usage)
# Parameters: $1 = command
__vte_osc777() {
	printf '\e]777;notify;Command completed;%s\e\\' "${command//;/ }"
	printf '\e]777;precmd\e\\'
}

# For timing how long a command took to run
__vte_osc777pre() {
	printf '\e]777;preexec\e\\'
}

# Set title using OSC 0
__vte_osc0() {
	if [[ -x "$(command -v tty)" ]]; then
		local ttydev=$(tty | sed -e s,^/dev/,,)
		local sty=
		local stytty=
		[[ -n "$STY" ]] && sty="${STY%.*}" stytty="${sty#*.}" ttydev="$ttydev screen:${sty%.*} ${stytty//-/\/}"
		[[ -n "$TMUX" ]] && ttydev="$ttydev tmux:$(tmux display-message -p '#S') $(tmux display-message -p '#{client_tty}' | sed -e s,^/dev/,,)"
	fi

	local uhp='\s-\v ($ttydev) \u@\h:\w'
	uhp="${uhp@P}"
	uhp="${uhp//[[:cntrl:]]}"

	printf '\e]0;%s\e\\' "$uhp"
}

case "$TERM" in
	*kitty)
		alias ssh='TERM="xterm-256color" ssh -ax -o ServerAliveInterval=5 -o ServerAliveCountMax=1'

		__vte_prompt_command() {
			__vte_osc0
			__vte_osc99
		}

		PS0=$(__vte_osc99pre)
		PROMPT_COMMAND=__vte_prompt_command
		;;

	xterm*|vte*)
		alias ssh='ssh -ax -o ServerAliveInterval=5 -o ServerAliveCountMax=1'

		__vte_prompt_command() {
			__vte_osc0
			__vte_osc777
			__vte_osc7
		}

		PS0=$(__vte_osc777pre)
		PROMPT_COMMAND=__vte_prompt_command
		;;

	screen*)
		alias ssh='ssh -ax -o ServerAliveInterval=5 -o ServerAliveCountMax=1'

		PS0=
		PROMPT_COMMAND=__vte_osc0
		;;

	*)
		;;
esac

# Prevent annoying PackageKit-command-not-found messages
unset -f command_not_found_handle

