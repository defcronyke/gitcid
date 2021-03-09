#!/usr/bin/env bash

gitcid_detect_sudo() {
	SUDO_GROUPS=${SUDO_GROUPS:-"sudo|wheel"}
	SUDO_CMD=${SUDO_CMD:-""}
	GROUP_FILE_PATH=${GROUP_FILE_PATH:-"/etc/group"}
	WHOAMI_CMD=${WHOAMI_CMD:-"whoami"}

	cat "$GROUP_FILE_PATH" | grep -P "$SUDO_GROUPS" | grep "$("$WHOAMI_CMD")" >/dev/null
	if [ $? -eq 0 ]; then
		gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "You seem to have sudo privileges. Enabling the sudo command."
		SUDO_CMD=$(if [ -z "$SUDO_CMD" ]; then echo "sudo"; fi)
	fi
}

gitcid_detect_os() {
	gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Attempting to find any missing GitCid dependencies and install them."
	
	ARCH_PKG_CMD=${ARCH_PKG_CMD:-"pacman"}
	ARCH_PKG_CMD_INSTALL_ARGS=${ARCH_PKG_CMD_INSTALL_ARGS:-"--noconfirm -Syy"}

	DEBIAN_PKG_CMD=${DEBIAN_PKG_CMD:-"apt-get"}
	DEBIAN_PKG_CMD_UPDATE_ARGS=${DEBIAN_PKG_CMD_UPDATE_ARGS:-"update"}
	DEBIAN_PKG_CMD_INSTALL_ARGS=${DEBIAN_PKG_CMD_INSTALL_ARGS:-"install --no-install-recommends -y"}

	FEDORA_PKG_CMD=${FEDORA_PKG_CMD:-"dnf"}
	FEDORA_PKG_CMD_UPDATE_ARGS=${FEDORA_PKG_CMD_UPDATE_ARGS:-"-y update"}
	FEDORA_PKG_CMD_INSTALL_ARGS=${FEDORA_PKG_CMD_INSTALL_ARGS:-"-y install"}

	FEDORA_OLD_PKG_CMD=${FEDORA_OLD_PKG_CMD:-"yum"}
	FEDORA_OLD_PKG_CMD_UPDATE_ARGS=${FEDORA_OLD_PKG_CMD_UPDATE_ARGS:-"-y update"}
	FEDORA_OLD_PKG_CMD_INSTALL_ARGS=${FEDORA_OLD_PKG_CMD_INSTALL_ARGS:-"-y install"}

	which $ARCH_PKG_CMD >/dev/null 2>&1
	IS_ARCH=$?

	which $DEBIAN_PKG_CMD >/dev/null 2>&1
	IS_DEBIAN=$?

	which $FEDORA_PKG_CMD >/dev/null 2>&1
	IS_FEDORA=$?

	which $FEDORA_OLD_PKG_CMD >/dev/null 2>&1
	IS_FEDORA_OLD=$?

	SUPPORTED_DISTRO=0

	if [ $IS_ARCH -eq 0 ]; then
		source "${GITCID_DEPS_DIR}arch-deps.env"
	elif [ $IS_DEBIAN -eq 0 ]; then
		source "${GITCID_DEPS_DIR}debian-deps.env"
	elif [ $IS_FEDORA -eq 0 ]; then
		source "${GITCID_DEPS_DIR}fedora-deps.env"
	elif [ $IS_FEDORA_OLD -eq 0 ]; then
		source "${GITCID_DEPS_DIR}fedora-old-deps.env"
	else
		SUPPORTED_DISTRO=1
		source "${GITCID_DEPS_DIR}unsupported-deps.env"
		gitcid_log_warn "${BASH_SOURCE[0]}" $LINENO "Your OS isn't supported. This still might work if you have the following \
dependencies installed:"
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "${GITCID_DEPS[@]}"
	fi
}

gitcid_enable_verbose() {
	for arg in "${@:1}"; do
		echo "$arg" | grep -P "\-.*v.*|\-\-verbose" >/dev/null
		if [ $? -eq 0 ]; then
			reason="$arg"
			
			if [ "$reason" != "--verbose" ]; then
				reason="-v"
			fi
			
			export GITCID_VERBOSE_OUTPUT="y"
			export GITCID_LOG_TIMESTAMP_CMD="date -Ins"
		fi
	done
}

gitcid_update() {
	last_update_check=$(cat "${GITCID_DIR}.gc-last-update-check.txt" || echo 0)
	current_time=$(date +%s)
	
	# Check for GitCid updates if at least 24 hours have passed since last update check.
	GITCID_UPDATE_FREQUENCY=${GITCID_UPDATE_FREQUENCY:-$(( 24 * 60 * 60 * 1 ))}
	
	update_diff=$(( $current_time - $last_update_check ))

	if [ $update_diff -lt $GITCID_UPDATE_FREQUENCY ]; then
		gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "No need to check for GitCid updates yet because we checked recently (next update check after $(( $GITCID_UPDATE_FREQUENCY - $update_diff )) more seconds)."
		return 0
	fi

	( 
		git fetch >/dev/null

		# if [ $(git rev-parse HEAD) != $(git rev-parse @{u}) ]; then
		if [ ! -z "$(git log HEAD..origin/master --oneline)" ]; then
			touch "${GITCID_DIR}.gc-update-available"
			return 0
		fi

		rm "${GITCID_DIR}.gc-update-available" 2>/dev/null

		gitcid_log_background_verbose "${BASH_SOURCE[0]}" $LINENO "GitCid is up-to-date."
	) &

	GITCID_BACKGROUND_JOBS+=($!)

	gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Checking for GitCid updates in the background..."

	date +%s > "${GITCID_DIR}.gc-last-update-check.txt"
}

gitcid_deps() {
	GITCID_BACKGROUND_JOBS=()

	gitcid_enable_verbose $@

	GITCID_DIR=${GITCID_DIR:-".gc/"}
	GITCID_DEPS_DIR=${GITCID_DEPS_DIR:-"${GITCID_DIR}.gc-deps/"}
	GITCID_GIT_HOOKS_CLIENT_DIR=${GITCID_GIT_HOOKS_CLIENT_DIR:-"${GITCID_DIR}.gc-git-hooks-client"}
	GITCID_UTIL_DIR=${GITCID_UTIL_DIR:-"${GITCID_DIR}.gc-util/"}
	GITCID_UTIL_LOG=${GITCID_UTIL_LOG:-"${GITCID_UTIL_DIR}log.env"}
	GITCID_IMPORT_DIR=${GITCID_IMPORT_DIR:-"${GITCID_DIR}.gc-import/"}
	GITCID_IMPORT_UTIL_LOG=${GITCID_IMPORT_UTIL_LOG:-"${GITCID_IMPORT_DIR}util-log.env"}

	source "${GITCID_IMPORT_UTIL_LOG}"

	gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Running script: ${BASH_SOURCE[0]} $@"

	gitcid_update

	gitcid_detect_sudo $@
	res_detect_sudo=$?
	if [ $res_detect_sudo -ne 0 ]; then
		gitcid_log_warn "${BASH_SOURCE[0]}" $LINENO "GitCid failed detecting if you have sudo privileges. We will assume you don't, \
so you'll need to run this script as root. It will probably fail now if you aren't root already."
	fi

	gitcid_detect_os $@
	res_detect_os=$?
	if [ $res_detect_os -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "GitCid failed detecting your OS. I guess it's not going to work, sorry!"
		return $res_detect_os
	fi

	HAS_DEPS=0
	for i in ${GITCID_DEPS_CMDS[@]}; do
		which $i >/dev/null 2>&1
		HAS_DEPS=$?
	done

	if [ $HAS_DEPS -ne 0 ]; then
		gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "You are missing at least one of these dependencies:"
		echo "${GITCID_DEPS[@]}"
		
		if [ $SUPPORTED_DISTRO -eq 0 ]; then
			gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "We will try to install them now, using the following command:"
			echo "${GITCID_DEPS_INSTALL_CMD[@]} ${GITCID_DEPS[@]}"

			eval "${GITCID_DEPS_INSTALL_CMD[@]} ${GITCID_DEPS[@]}"
			res=$?

			if [ $res -ne 0 ]; then
				gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed installing dependencies. You'll need to install them manually then I guess."
				return 81
			fi
		else
			gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "You are missing some dependencies and your OS isn't supported. \
Please install them yourself and try again afterwards. Maybe it'll work if you do that."
			gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "You can also try setting the following environment variables to \
please our system, if you know the correct values for your unsupported OS:"
			echo "GITCID_DEPS_INSTALL_CMD=${GITCID_DEPS_INSTALL_CMD[@]}"
			echo "GITCID_DEPS=${GITCID_DEPS[@]}"
			echo "GITCID_DEPS_CMDS=${GITCID_DEPS_CMDS[@]}"
			return 80
		fi
	fi

	gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Setting \"$GITCID_GIT_HOOKS_CLIENT_DIR\" as this git repo's \"core.hooksPath\""
	
	git config core.hooksPath "$GITCID_GIT_HOOKS_CLIENT_DIR"
	git_config_res=$?
	if [ $git_config_res -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed setting this git repo's \"core.hooksPath\". I guess this isn't going to work, sorry!"
		return $git_config_res
	fi

	gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "All GitCid dependencies are installed.\n\
----------\n"
}

gitcid_deps $@
