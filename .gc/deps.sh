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
	ARCH_PKG_CMD=${ARCH_PKG_CMD:-"pacman"}
	ARCH_PKG_CMD_INSTALL_ARGS=${ARCH_PKG_CMD_INSTALL_ARGS:-"--noconfirm --needed -Syy"}

	DEBIAN_PKG_CMD=${DEBIAN_PKG_CMD:-"apt-get"}
	DEBIAN_PKG_CMD_UPDATE_ARGS=${DEBIAN_PKG_CMD_UPDATE_ARGS:-"update"}
	DEBIAN_PKG_CMD_INSTALL_ARGS=${DEBIAN_PKG_CMD_INSTALL_ARGS:-"install -y"}

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
	gitcid_verbose_requested=1
	for arg in "${@:1}"; do
		echo "$arg" | grep -P "\-.*v.*|\-\-verbose" >/dev/null
		if [ $? -eq 0 ]; then
			reason="$arg"
			
			if [ "$reason" != "--verbose" ]; then
				reason="-v"
			fi
			
			gitcid_verbose_requested=0
			break
		fi
	done
	
	if [ $gitcid_verbose_requested -eq 0 ]; then
		GITCID_VERBOSE_OUTPUT="y"
	else
		unset GITCID_VERBOSE_OUTPUT
	fi

	if [ ! -z ${GITCID_VERBOSE_OUTPUT+x} ]; then
		GITCID_LOG_TIMESTAMP_CMD="date -Ins"
	else
		GITCID_LOG_TIMESTAMP_CMD="date -Iseconds"
	fi
}

gitcid_update() {
	last_update_check=$(cat "${GITCID_DIR}.gc-last-update-check.txt" 2>/dev/null || echo 0)
	current_time=$(date +%s)
	
	# Check for GitCid updates if at least 24 hours have passed since last update check.
	GITCID_UPDATE_FREQUENCY=${GITCID_UPDATE_FREQUENCY:-$(( 24 * 60 * 60 * 1 ))}
	
	update_diff=$(( $current_time - $last_update_check ))

	if [ $update_diff -lt $GITCID_UPDATE_FREQUENCY ]; then
		gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "No need to check for GitCid updates yet because we checked recently (next update check after $(( $GITCID_UPDATE_FREQUENCY - $update_diff )) more seconds)." 1>&2
		return 0
	fi

	( 
		gitcid_log_background_verbose "${BASH_SOURCE[0]}" $LINENO "Checking for GitCid updates in the background..." 1>&2

		gitcid_log_background_verbose "${BASH_SOURCE[0]}" $LINENO "Performing git fetch... $(git fetch origin 2>&1)" 1>&2

		if [ ! -z "$(git log HEAD..origin/master --oneline)" ]; then
			touch "${GITCID_DIR}.gc-update-available"
			return 0
		fi

		rm "${GITCID_DIR}.gc-update-available" 2>/dev/null
	) &

	GITCID_BACKGROUND_JOBS+=($!)

	GITCID_CHECKED_FOR_UPDATES="y"

	date +%s > "${GITCID_DIR}.gc-last-update-check.txt"
}

gitcid_deps() {
	GITCID_BACKGROUND_JOBS=()

	gitcid_enable_verbose $@

	GITCID_DIR=${GITCID_DIR:-".gc/"}
	GITCID_DEPS_DIR=${GITCID_DEPS_DIR:-"${GITCID_DIR}.gc-deps/"}
	GITCID_GIT_HOOKS_CLIENT_DIR=${GITCID_GIT_HOOKS_CLIENT_DIR:-"${GITCID_DIR}.gc-git-hooks"}
	GITCID_UTIL_DIR=${GITCID_UTIL_DIR:-"${GITCID_DIR}.gc-util/"}
	GITCID_UTIL_LOG=${GITCID_UTIL_LOG:-"${GITCID_UTIL_DIR}log.env"}
	GITCID_IMPORT_DIR=${GITCID_IMPORT_DIR:-"${GITCID_DIR}.gc-import/"}
	GITCID_IMPORT_UTIL_LOG=${GITCID_IMPORT_UTIL_LOG:-"${GITCID_IMPORT_DIR}util-log.env"}

	source "${GITCID_IMPORT_UTIL_LOG}"

	gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Running script: ${BASH_SOURCE[0]} $@"

	gitcid_update

	gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Attempting to find any missing GitCid dependencies and install them."

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
	HAS_DOCKER=0
	HAS_DOCKER_COMPOSE=0
	for i in "${GITCID_DEPS_CMDS[@]}"; do
		which $i >/dev/null 2>&1
		HAS_DEPS=$?

		if [ "$i" == "docker" ]; then
			HAS_DOCKER=${HAS_DEPS}
		fi

		if [ "$i" == "docker-compose" ]; then
			HAS_DOCKER_COMPOSE=${HAS_DEPS}
		fi

    if [ $HAS_DEPS -ne 0 ]; then
      break
    fi
	done

	uname -a | grep "x86_64" >/dev/null
	IS_X64=$?

	uname -a | grep "aarch64" >/dev/null
	IS_ARM64=$?

	uname -a | grep "arm" >/dev/null
	IS_ARMHF=$?

	if [ $HAS_DEPS -ne 0 ]; then
		gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "You are missing at least one of these dependencies:"
		gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "${GITCID_DEPS_CMDS[@]}"
		
		if [ $SUPPORTED_DISTRO -eq 0 ]; then
			gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "We will try to install them now, using the following command:"
			gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "${GITCID_DEPS_INSTALL_CMD[@]} ${GITCID_DEPS[@]}"

			gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "$(eval "${GITCID_DEPS_INSTALL_CMD[@]} ${GITCID_DEPS[@]}")"
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
			gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "GITCID_DEPS_INSTALL_CMD=${GITCID_DEPS_INSTALL_CMD[@]}"
			gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "GITCID_DEPS=${GITCID_DEPS[@]}"
			gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "GITCID_DEPS_CMDS=${GITCID_DEPS_CMDS[@]}"
			return 80
		fi


		if [ $HAS_DOCKER -ne 0 ]; then
			if [ $IS_DEBIAN -eq 0 ]; then
				#curl -fsSL https://download.docker.com/linux/debian/gpg | $SUDO_CMD gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

        # Install docker-ce official gpg keyring.
        curl -fsSL https://download.docker.com/linux/debian/gpg > tmp-key.txt && \
        cat tmp-key.txt | \
        yes | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; \
        rm tmp-key.txt
				
				if [ $IS_X64 -eq 0 ]; then
					echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
				elif [ $IS_ARM64 -eq 0 ]; then
					echo "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
				elif [ $IS_ARMHF -eq 0 ]; then
					echo "deb [arch=armhf signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
				else
					gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "You don't have Docker installed, and you're running on a CPU architecture which \
doesn't have official Docker builds for it. You will have to try installing Docker from source yourself if you want this to work."
					return 82
				fi
				
				eval "${GITCID_DEPS_INSTALL_CMD[@]} docker-ce docker-ce-cli containerd.io"

			elif [ $IS_ARCH -eq 0 ]; then
				eval "${GITCID_DEPS_INSTALL_CMD[@]} docker"
				$SUDO_CMD systemctl enable docker
				$SUDO_CMD systemctl start docker
			fi
		fi

		if [ $HAS_DOCKER_COMPOSE -ne 0 ]; then
			if [ $IS_ARM64 -eq 0 ]; then
				curl -L "https://github.com/linuxserver/docker-docker-compose/releases/latest/download/docker-compose-arm64" -o docker-compose && \
				chmod 755 docker-compose && \
				sudo mv docker-compose /usr/local/bin/
			elif [ $IS_ARMHF -eq 0 ]; then
				curl -L "https://github.com/linuxserver/docker-docker-compose/releases/latest/download/docker-compose-armhf" -o docker-compose && \
				chmod 755 docker-compose && \
				sudo mv docker-compose /usr/local/bin/
			else
				curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o docker-compose && \
				chmod 755 docker-compose && \
				sudo mv docker-compose /usr/local/bin/
			fi
		fi

	fi

	docker ps >/dev/null
	if [ $? -ne 0 ]; then
		gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Adding user \"$USER\" to the \"docker\" group."
		$SUDO_CMD gpasswd -a $USER docker

		docker ps >/dev/null
		if [ $? -ne 0 ]; then
			gitcid_log_notice "${BASH_SOURCE[0]}" $LINENO "Your user account \"$USER\" doesn't have permission to use Docker. \
Logging out and back in should fix the issue."
			return 83
		fi
	fi

	gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Attempting to find any missing GitCid python dependencies and install them."

	GITCID_SHELL_PROFILE_FILE=${GITCID_SHELL_PROFILE_FILE:-"$HOME/.bashrc"}
	GITCID_PYTHON_DEFAULT_PATH=${GITCID_PYTHON_DEFAULT_PATH:-'$HOME/.local/bin'}

	HAS_PYTHON_DEPS=0
	for i in "${GITCID_PYTHON_DEPS_CMDS[@]}"; do
		which "$i" >/dev/null 2>&1
		HAS_PYTHON_DEPS=$?
	done

	if [ $HAS_PYTHON_DEPS -ne 0 ]; then
		gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "You are missing at least one of these python dependencies:"
		gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "${GITCID_PYTHON_DEPS_CMDS[@]}"

		gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "We will try to install them now, using the following command:"
		gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "${GITCID_PYTHON_DEPS_INSTALL_CMD[@]} ${GITCID_PYTHON_DEPS[@]}"

		gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "$(eval "${GITCID_PYTHON_DEPS_INSTALL_CMD[@]} ${GITCID_PYTHON_DEPS[@]}")"
		res=$?

		if [ $res -ne 0 ]; then
			gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed installing python dependencies. You'll need to install them manually then I guess."
			return 81
		fi
	fi

	cat "$GITCID_SHELL_PROFILE_FILE" | grep "${GITCID_PYTHON_DEFAULT_PATH}" >/dev/null
	if [ $? -ne 0 ]; then
		gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Python path not found in your \$PATH. Adding it in: $GITCID_SHELL_PROFILE_FILE"
		echo "export PATH=\"${GITCID_PYTHON_DEFAULT_PATH}:\$PATH\"" | tee -a "${GITCID_SHELL_PROFILE_FILE}"
		gitcid_log_notice_verbose "${BASH_SOURCE[0]}" $LINENO "Running this script again: ${BASH_SOURCE[0]} $@"
		pwd="$PWD"
		source "$GITCID_SHELL_PROFILE_FILE"
		cd "$pwd"
		source "${BASH_SOURCE[0]}" $@
		return 0
	fi

	GITCID_YQ_CMD="${GITCID_YQ_CMD:-"yq"}"

	which "${GITCID_YQ_CMD}" >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		if [ $IS_X64 -eq 0 ]; then
			GITCID_YQ_DOWNLOAD_BINARY=${GITCID_YQ_DOWNLOAD_BINARY:-"yq_linux_amd64"}
		elif [ $IS_ARM64 -eq 0 ]; then
			GITCID_YQ_DOWNLOAD_BINARY=${GITCID_YQ_DOWNLOAD_BINARY:-"yq_linux_arm64"}
		elif [ $IS_ARMHF -eq 0 ]; then
			GITCID_YQ_DOWNLOAD_BINARY=${GITCID_YQ_DOWNLOAD_BINARY:-"yq_linux_arm"}
		else
			GITCID_YQ_DOWNLOAD_BINARY=${GITCID_YQ_DOWNLOAD_BINARY:-"yq_linux_amd64"}
		fi

		GITCID_YQ_DOWNLOAD_URL="${GITCID_YQ_DOWNLOAD_URL:-"https://github.com/mikefarah/yq/releases/latest/download/${GITCID_YQ_DOWNLOAD_BINARY}"}"
		GITCID_YQ_DOWNLOAD_CMD="${GITCID_YQ_DOWNLOAD_CMD:-"curl -sL $GITCID_YQ_DOWNLOAD_URL"}"
		GITCID_YQ_CMD_INSTALL_PATH="${GITCID_YQ_CMD_INSTALL_PATH:-"/usr/local/bin/"}"
		
		gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "The command \"${GITCID_YQ_CMD}\" wasn't found in your \$PATH. \
Attempting to download it by running the following command:\n\
${GITCID_YQ_DOWNLOAD_CMD} > \"${GITCID_DIR}${GITCID_YQ_CMD}\""

		eval $GITCID_YQ_DOWNLOAD_CMD > "${GITCID_DIR}${GITCID_YQ_CMD}"

		gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Attempting to install \"${GITCID_YQ_CMD}\" by running the following command:\n\
chmod 755 \"${GITCID_DIR}${GITCID_YQ_CMD}\" && ${SUDO_CMD} mv \"${GITCID_DIR}${GITCID_YQ_CMD}\" \"${GITCID_YQ_CMD_INSTALL_PATH}\""
		
		chmod 755 "${GITCID_DIR}${GITCID_YQ_CMD}" && ${SUDO_CMD} mv "${GITCID_DIR}${GITCID_YQ_CMD}" "${GITCID_YQ_CMD_INSTALL_PATH}"
		if [ $? -ne 0 ]; then
			gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed installing the \"${GITCID_YQ_CMD}\" command. You'll need to install it manually then I guess."
			return 81
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
