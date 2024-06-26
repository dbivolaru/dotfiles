# .bashrc
# .zshrc
# This file can be parsed by both succesfully: ln -s .zshrc .bashrc

# Set to 1 to time the script
# :nnoremap Q klyiWlllljciW<C-r>=printf('%.6f', <C-r>"-<C-r>0)<CR><C-c>kl
_BENCHMARK=0

if [[ $_BENCHMARK -ne 0 ]]; then
	if [[ -n "${BASH_VERSION-}" ]]; then
		PS4="+ \$EPOCHREALTIME\011 "
		exec 3>&2 2>/tmp/bash.benchmark.$$.log
	elif [[ -n "${ZSH_VERSION-}" ]]; then
		PS4=$'+ %D{%s.%6.}\011 '
		exec 3>&2 2>/tmp/zsh.benchmark.$$.log
	fi
	set -x
fi

# Source global definitions
if [[ -n "${BASH_VERSION-}" && -f /etc/bashrc ]]; then
	. /etc/bashrc
elif [[ -n "${ZSH_VERSION-}" && -f /etc/zshrc ]]; then
	. /etc/zshrc
fi

# User specific environment and startup programs
export GOPATH="$HOME/go"
export PATH="${PATH:+${PATH}:}$HOME/.local/bin:$HOME/bin:$HOME/scripts:$GOPATH/bin"

# Kubernetes environments
[[ -n "${ZSH_VERSION-}" ]] && unsetopt nomatch
[[ -d ~/.kube ]] || mkdir -p ~/.kube
for k in ~/.kube/*; do
	[[ -f $k ]] || continue
	export KUBECONFIG="${KUBECONFIG+${KUBECONFIG}:}$k"
done

# Setup podman in place of docker (including rootless detection)
if [[ -x "$(command -v podman)" ]]; then
	alias docker=podman
	alias docker-compose=podman-compose
	if [[ -S "$XDG_RUNTIME_DIR/podman/podman.sock" ]]; then
		export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
		export BUILDAH_ISOLATION=rootless
	else
		if [[ -S "/run/podman/podman.sock" ]]; then
			export DOCKER_HOST="unix:///run/podman/podman.sock"
		fi
		export BUILDAH_ISOLATION=oci
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
if [[ "$EUID" -eq 0 ]]; then
	umask 022
else
	umask 027
fi

# User specific aliases and functions
alias ll='ls -lhN --color=auto --group-directories-first' 2>/dev/null
alias l.='ls -dhN .* --color=auto --group-directories-first' 2>/dev/null
alias ll.='ls -dlhN .* --color=auto --group-directories-first' 2>/dev/null
alias ls='ls -hN --color=auto --group-directories-first' 2>/dev/null
alias diff='diff --color=auto -ud'

kubectx() { if [[ "$#" -eq 1 ]]; then kubectl config use-context $1; else kubectl config get-contexts; fi; }
kubelb() { if [[ "$#" -ge 1 ]]; then KUBELB_OPT=("$@"); else KUBELB_OPT=-A; fi; kubectl get service "${KUBELB_OPT[@]}" -o jsonpath='NAMESPACE{"\t"}NAME{"\t"}EXTERNAL-IP{"\n"}{range .items[?(@.status.loadBalancer.ingress[0])]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}{"\n"}{end}' | column -t ; }
kubeevents() { kubectl get events --all-namespaces  --sort-by='.metadata.creationTimestamp'; }

lll() { stat --printf="%A %#03a %h %4U %4G %s %.19y %n (%C)\n" * | numfmt --to=iec-i --field=6 --padding=5; }
lll.() { stat --printf="%A %#03a %h %4U %4G %s %.19y %n (%C)\n" .* | numfmt --to=iec-i --field=6 --padding=5; }

bindiff() { diff --color=auto -ud <(xxd -g 1 "$1") <(xxd -g 1 "$2") "${@:3}"; }

if [[ -x "$(command -v vimx)" && -n "$DISPLAY" ]]; then
	alias vi='vimx'
	alias vim='vimx'
	alias vim-safe='vimx -u NONE -U NONE -i NONE -N'
	export EDITOR='vimx'
else
	if [[ -x "$(command -v vim)" ]]; then
		alias vi='vim'
		alias vim-safe='vim -u NONE -U NONE -i NONE -N'
		export EDITOR='vim'
	else
		export EDITOR='vi'
	fi
fi

if [[ -f /usr/share/vim/vim91/defaults.vim ]]; then
	# Fast guess
	export VIMRUNTIME="/usr/share/vim/vim91"
else
	# This is very slow
	VIMRUNTIME="$($EDITOR --version | awk ' /fall-back/ { gsub(/["]/,"",$NF); print $NF }')"
	VIMRUNTIME="$(find $VIMRUNTIME -name defaults.vim)"
	export VIMRUNTIME="${VIMRUNTIME%/*}"
	echo "VIMRUNTIME not found. Searched and found $VIMRUNTIME. Please update .bashrc accordingly."
fi
export MERGE="vimdiff"
export VIRTUAL_ENV_DISABLE_PROMPT=1

if [[ -x "$(command -v uname)" ]]; then
	export HOSTNAME="$(uname -n)"
fi

# TODO Kitty integration ... but ours is so much better
# if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
# 	KITTY_SHELL_INTEGRATION="enabled"
# 	source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"
# fi

# Enable early enough for VTE handling
[[ -n "${BASH_VERSION-}" ]] && export SHELL="$(command -v bash)"
if [[ -n "${ZSH_VERSION-}" ]]; then
	export SHELL="$(command -v zsh)"
	zmodload zsh/datetime
	setopt prompt_subst
	autoload -Uz add-zsh-hook
fi

# Turn on parallel history, de-duplicate last command, ignore commands starting with space
export HISTFILE=~/.bash_history
if [[ -n "${BASH_VERSION-}" ]]; then
	shopt -s histappend
	export HISTFILESIZE=100000
	export HISTCONTROL=ignoreboth
	export HISTIGNORE="?:??:ls *:pwd:bash:zsh:history:history *:exit:logout:df *:du *:ps *:man *:sudo su -:su -"
	export HISTSIZE=100000
fi
if [[ -n "${ZSH_VERSION-}" ]]; then
	setopt appendhistory
	unsetopt extended_history
	export SAVEHIST=100000
	setopt histignorealldups
	setopt histignorespace
	setopt histnofunctions
	setopt histnostore
	export HISTORY_IGNORE="(?|??|ls *|pwd|bash|zsh|exit|logout|df *|du *|ps *|man *|sudo su -|su -)"
	export HISTSIZE=100000
	export PROMPT_EOL_MARK=""
fi

# Turn on window resize checking
[[ -n "${BASH_VERSION-}" ]] && shopt -s checkwinsize

# Jobs running when exiting
[[ -n "${BASH_VERSION-}" ]] && shopt -s checkjobs
[[ -n "${ZSH_VERSION-}" ]] && setopt check_jobs
[[ -n "${BASH_VERSION-}" ]] && shopt -s huponexit
[[ -n "${ZSH_VERSION-}" ]] && setopt hup

get_time() {
	local last_ec=$?
	local t="$(date +%H:%M)"
	printf 'EC %s | %s' "$last_ec" "$t"
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
	if [[ -n "${BASH_VERSION-}" ]]; then
		local j='\j'
		local jj="${j@P}"
		if [[ "$jj" -gt 0 ]]; then
			printf ' ⏳%s' "$jj"
		fi
	elif [[ -n "${ZSH_VERSION-}" ]]; then
		printf '%%(1j. ⏳%%j.)'
	fi
}

get_ssh() {
	if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
		printf ' 💻'
	fi
}

red_if_root() {
	if [[ "$EUID" -eq 0 ]]; then
		if [[ -n "${BASH_VERSION-}" ]]; then
			printf '\e[1;31m'
		elif [[ -n "${ZSH_VERSION-}" ]]; then
			printf '%%B%%F{red}'
		fi
	fi
}

[[ -n "${BASH_VERSION-}" ]] && PS1="\[\$(red_if_root)\][\u@\h\$(get_ssh) \W\[\e[01m\]\$(get_jobs)\$(get_git_branch)\$(get_venv)\[\e[00m\$(red_if_root)\]]\$(long_venv_prompt)\\$\[\e[00m\] "
[[ -n "${ZSH_VERSION-}" ]] && PS1='$(red_if_root)[%n@%m$(get_ssh) %2~%B$(get_jobs)$(get_git_branch)$(get_venv)%b%f$(red_if_root)]%(!.#.$)%b%f '
# Only show right side when in the base shell
[[ -n "${ZSH_VERSION-}" && -r /proc/$PPID/comm ]] && grep -Fxq -e kitty -e zsh -e make /proc/$PPID/comm && RPS1='$(get_time)'

PS2='  '
[[ -n "${ZSH_VERSION-}" ]] && RPS2='%^'

__vte_preexec() {
	STARTTIME=$EPOCHSECONDS
}

__vte_precmd() {
	# Workaround: we use history as preexec runs inside a subshell in bash and STARTTIME is not available
	if [[ -n "${BASH_VERSION-}" ]]; then
		local st=$(HISTTIMEFORMAT='%s ' history 1 | awk '{print $2}')
		if [[ -z "$STARTTIME" || (-n "$STARTTIME" && "$STARTTIME" -ne "$st") ]]; then
			ENDTIME=$EPOCHSECONDS
			STARTTIME=$st
		else
			ENDTIME=0
		fi
	elif [[ -n "${ZSH_VERSION-}" ]]; then
		ENDTIME=$EPOCHSECONDS
		[[ -z "$STARTTIME" ]] && STARTTIME=$ENDTIME && ENDTIME=0
	fi
}

# Notify OS of local folder URL
__vte_osc7() {
	if [[ -n "${BASH_VERSION-}" ]]; then
		local hostname='\h'
		hostname="${hostname@P}"
	elif [[ -n "${ZSH_VERSION-}" ]]; then
		local hostname="%m"
		hostname="${(%%)hostname}"
	fi
	printf '\e]7;file://%s%s\e\\' "${hostname}" "$(/usr/libexec/vte-urlencode-cwd)"
}

# Notify kitty when command completes (similar styling as OSC 777 on gnome-terminal)
__vte_osc99() {
	if [[ -n "${BASH_VERSION-}" ]]; then
		local command=$(HISTTIMEFORMAT= history 1 | sed 's/^ *[0-9]\+ *//')
	elif [[ -n "${ZSH_VERSION-}" ]]; then
		local command=$(fc -l -t '' -1 -1 2>/dev/null | sed 's/^ *[0-9]\+ *//')
	fi
	[[ \
		"${command%% *}" == vim || \
		"${command%% *}" == mc || \
		"${command%% *}" == sudo || \
		"${command%% *}" == bash || \
		"${command%% *}" == zsh \
	]] && STARTTIME=$EPOCHSECONDS && return 0

	__vte_precmd
	if ((ENDTIME - STARTTIME >= 300)); then
		printf '\e]99;d=0:p=title;Command completed\e\\'
		printf '\e]99;d=1:p=body;%s\e\\' "${command//[[:cntrl:]]}"
	fi
	[[ -n "${ZSH_VERSION-}" ]] && STARTTIME=
}

# For timing how long a command took to run
__vte_osc99pre() {
	__vte_preexec
}

# Notify urxvt and gnome-terminal (for non-kitty usage)
__vte_osc777() {
	if [[ -n "${BASH_VERSION-}" ]]; then
		local command=$(HISTTIMEFORMAT= history 1 | sed 's/^ *[0-9]\+ *//')
	elif [[ -n "${ZSH_VERSION-}" ]]; then
		local command=$(fc -l -t '' -1 -1 2>/dev/null | sed 's/^ *[0-9]\+ *//')
	fi
	printf '\e]777;notify;Command completed;%s\e\\' "${command//;/ }"
	printf '\e]777;precmd\e\\'
}

# For timing how long a command took to run
__vte_osc777pre() {
	printf '\e]777;preexec\e\\'
}

# Set title using OSC 0
__vte_osc0() {
	local last_ec=$?
	local ttydev=
	if [[ -x "$(command -v tty)" ]]; then
		local ttydev=$(tty | sed -e s,^/dev/,,)
		local sty=
		local stytty=
		[[ -n "$STY" ]] && sty="${STY%.*}" stytty="${sty#*.}" ttydev="$ttydev screen:${sty%.*} ${stytty//-/\/}"
		[[ -n "$TMUX" ]] && ttydev="$ttydev tmux:$(tmux display-message -p '#S') $(tmux display-message -p '#{client_tty}' | sed -e s,^/dev/,,)"
	fi

	local ttyspeed
	if [[ -x "$(command -v stty)" ]]; then
		ttyspeed=$(stty speed)
		ttyspeed="$ttyspeed$(stty -a | awk 'BEGIN{RS=" ";FS="cs";e=0;o=0;c=0;n=0;b=1}/^parenb/{++e}/^parodd/{++o}/^cmspar/{++c}/^cs[0-9]/{n=$2}/^cstopb/{b=2}END{if(o && c)print "M";else if(e && c) print "S";else if(!e && !o && !c)print "N";else if(e)print "E";else if (o) print "O";else print "?";print n "." b}')"
	fi

	local lc
	if [[ -x "$(command -v localectl)" ]]; then
		lc="$(localectl | awk 'BEGIN{ORS=" "}/X11/{print $3}')"
	fi

	local uhp="$ttydev $ttyspeed | $LANG $lc"
	if [[ -n "${BASH_VERSION-}" ]]; then
		uhp="$uhp | \s v\v | EC $last_ec | \u@\h:\w"
		uhp="${uhp@P}"
	elif [[ -n "${ZSH_VERSION-}" ]]; then
		local uhp0="%n@%m:%2~"
		uhp="$uhp | zsh v"${ZSH_VERSION-}" | EC $last_ec | ${(%%)uhp0}"
	fi
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

		[[ -n "${BASH_VERSION-}" ]] && PS0=$(__vte_osc99pre)
		[[ -n "${ZSH_VERSION-}" ]] && add-zsh-hook preexec __vte_osc99pre
		[[ -n "${BASH_VERSION-}" ]] && PROMPT_COMMAND=__vte_prompt_command
		[[ -n "${ZSH_VERSION-}" ]] && add-zsh-hook precmd __vte_prompt_command
		;;

	xterm*|vte*|gnome*)
		alias ssh='ssh -ax -o ServerAliveInterval=5 -o ServerAliveCountMax=1'

		__vte_prompt_command() {
			__vte_osc0
			__vte_osc777
			__vte_osc7
		}

		[[ -n "${BASH_VERSION-}" ]] && PS0=$(__vte_osc777pre)
		[[ -n "${ZSH_VERSION-}" ]] && add-zsh-hook preexec __vte_osc777pre
		[[ -n "${BASH_VERSION-}" ]] && PROMPT_COMMAND=__vte_prompt_command
		[[ -n "${ZSH_VERSION-}" ]] && add-zsh-hook precmd __vte_prompt_command
		;;

	screen*)
		alias ssh='ssh -ax -o ServerAliveInterval=5 -o ServerAliveCountMax=1'

		[[ -n "${BASH_VERSION-}" ]] && PS0=
		[[ -n "${BASH_VERSION-}" ]] && PROMPT_COMMAND=__vte_osc0
		[[ -n "${ZSH_VERSION-}" ]] && add-zsh-hook precmd __vte_osc0
		;;

	*)
		;;
esac

# Prevent annoying PackageKit-command-not-found messages
unset -f command_not_found_handle
[[ -n "${ZSH_VERSION-}" ]] && unset -f command_not_found_handler

# bash specific
if [[ -n "${BASH_VERSION-}" ]]; then
	# Completion
	[[ -d ~/.bash_completion ]] || mkdir -p ~/.bash_completion

	# Completions for kubectl
	if [[ -x $(command -v kubectl) ]]; then
		[[ -f ~/.bash_completion/kubectl ]] || kubectl completion bash >~/.bash_completion/kubectl
		[[ -f ~/.bash_completion/kubectl ]] && source ~/.bash_completion/kubectl
	fi

	# Completions for helm
	if [[ -x $(command -v helm) ]]; then
		[[ -f ~/.bash_completion/helm ]] || helm completion bash >~/.bash_completion/helm
		[[ -f ~/.bash_completion/helm ]] && source ~/.bash_completion/helm
	fi
fi

# zsh specific
if [[ -n "${ZSH_VERSION-}" ]]; then
	# Beep on error
	setopt beep

	# Show error when unable to complete
	setopt nomatch

	# Do not enter directory if specified on command line
	unsetopt auto_cd

	# Do not glob in strange places
	unsetopt extendedglob

	# Job updates only when prompt is there
	unsetopt notify

	# Keybindings including Meta
	stty pass8
	bindkey -em 2>/dev/null

	# Configure autocompletion
	autoload -Uz compinit && compinit

	# Re-use any existing bash command completions
	autoload -Uz bashcompinit && bashcompinit

	# Completion
	zstyle ':completion:*' completer _complete _approximate _ignored
	zstyle ':completion:*' menu select
	[[ -d ~/.zsh_completion ]] || mkdir -p ~/.zsh_completion

	# Completions for kubectl
	if [[ $commands[kubectl] ]]; then
		[[ -f ~/.zsh_completion/kubectl ]] || kubectl completion zsh >~/.zsh_completion/kubectl
		[[ -f ~/.zsh_completion/kubectl ]] && source ~/.zsh_completion/kubectl
	fi

	# Completions for helm
	if [[ $commands[helm] ]]; then
		[[ -f ~/.zsh_completion/helm ]] || helm completion zsh >~/.zsh_completion/helm
		[[ -f ~/.zsh_completion/helm ]] && source ~/.zsh_completion/helm
	fi

	# Group by description
	zstyle ':completion:*' group-name ''
	zstyle ':completion:*:descriptions' format '--- %d ---%f'

	zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
	zstyle ':completion:*:*:-command-:*:*' group-order alias builtins functions commands

	# Also do history expansion on space
	bindkey ' ' magic-space

	# Input processing for Line Editor (equivalent to .inputrc)
	export KEYTIMEOUT=1
	function skip-csi-sequence() {
		# Ref: bash/lib/readline/text.c: rl_skip_csi_sequence()
		local key
		read -sk key
		while (( $((#key)) >= 0x20 && $((#key)) < 0x40 )); do
			read -sk key
		done
	}
	zle -N skip-csi-sequence
	bindkey -s "\e\e" ""
	bindkey "\e[" skip-csi-sequence
	bindkey "\eO" skip-csi-sequence
	bindkey "\e\e[" skip-csi-sequence
	bindkey "\e\eO" skip-csi-sequence

	# Nav Cluster
	## Home moves to the beginning of line
	### freebsd and vte
	bindkey "\e[H" beginning-of-line
	### non-RH/Debian xterm and vte in keypad app mode
	bindkey "\eOH" beginning-of-line
	### linux console and RH/Debian xterm
	bindkey "\e[1~" beginning-of-line
	### rxvt
	bindkey "\e[7~" beginning-of-line

	## End moves to the end of line
	### freebsd and vte
	bindkey "\e[F" end-of-line
	### non-RH/Debian xterm and vte in keypad app mode
	bindkey "\eOF" end-of-line
	### linux console and RH/Debian xterm
	bindkey "\e[4~" end-of-line
	### rxvt
	bindkey "\e[8~" end-of-line

	## PgUp and PgDn search backward and forward
	bindkey "\e[5~" history-search-backward
	bindkey "\e[6~" history-search-forward

	## Insert key switches to overwrite mode
	bindkey "\e[2~" overwrite-mode

	## Delete key actually deletes
	bindkey "\e[3~" delete-char

	## M-RightArrow has legacy functionality
	### freebsd and vte
	bindkey "\e[1;3C" forward-word
	### MacOS
	bindkey "\e[3C" forward-word

	## C-RightArrow has legacy functionality
	### freebsd and vte
	bindkey "\e[1;5C" forward-word
	### rxvt
	bindkey "\eOc" forward-word
	### MacOS
	bindkey "\e[5C" forward-word

	## M-LeftArrow has legacy functionality
	### freebsd and vte
	bindkey "\e[1;3D" backward-word
	### MacOS
	bindkey "\e[3D" backward-word

	## C-LeftArrow has legacy functionality
	### freebsd and vte
	bindkey "\e[1;5D" backward-word
	### rxvt
	bindkey "\eOd" backward-word
	### MacOS
	bindkey "\e[5D" backward-word

	# Keypad
	## KP Enter works as expected
	bindkey "\eOM" accept-line

	## KP keys in Sun mode work as expected
	bindkey -s "\eOo" "/"
	bindkey -s "\eOj" "*"
	bindkey -s "\eOm" "-"

	## KP keys , and + are inter-changed in Sun mode
	bindkey -s "\eOk" "+"
	### XTerm compatibility for VT220 comma key
	bindkey -s "\eO5k" ","
	bindkey -s "\eO5m" "-"
	bindkey -s "\eOl" ","
	bindkey -s "\eOn" "."

	## KP numbers in Sun mode
	bindkey -s "\eOp" "0"
	bindkey -s "\eOq" "1"
	bindkey -s "\eOr" "2"
	bindkey -s "\eOs" "3"
	bindkey -s "\eOt" "4"
	bindkey -s "\eOu" "5"
	bindkey -s "\eOv" "6"
	bindkey -s "\eOw" "7"
	bindkey -s "\eOx" "8"
	bindkey -s "\eOy" "9"

	## KP = key on Sun and on Realforce 23U/UB (Alt+{KP6,KP1} as a Windows Alt code)
	bindkey -s "\eOX" "="
	bindkey -s "\e[1;3C\e[1;3F" "="

	# Navigation
	## M-b and M-f move to whitespace instead of /
	bindkey "\eb" backward-word
	bindkey "\ef" forward-word

	# Kill Ring
	## M-d and M-Rubout kills to whitespace instead of /
	bindkey "\ed" kill-word
	bindkey "\e\C-?" backward-kill-word

	## Ctrl-Delete has legacy functionality
	bindkey "\e[3;5~" kill-word

	## M-C-h has legacy functionality
	bindkey "\e\C-h" backward-kill-word

	# Transpose
	## M-t transposes unix bounded words instead of /
	bindkey "\et" transpose-words

	## C-x t has legacy functionality
	bindkey "\C-xt" transpose-words

	# Quoting
	## M-' quotes text; use marks to prevent issues with existing quotes
	bindkey -s "\e\'" "\C-w\'\C-y\' "

	## M-" quotes text
	bindkey -s "\e\"" "\C-w\"\C-y\" "

	# History
	## M-s does forward search as default C-s is used for flow control
	bindkey "\es" history-incremental-search-forward
fi

if [[ $_BENCHMARK -ne 0 ]]; then
	set +x
	exec 2>&3 3>&-
	unset $_BENCHMARK
fi
