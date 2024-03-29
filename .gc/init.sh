#!/usr/bin/env bash

gitcid_get_project_version() {
	GITCID_VERSION_DEFAULT=${GITCID_VERSION_DEFAULT:-"v0.1.0"}
	GITCID_VERSION="${GITCID_VERSION:-$(cat "${GITCID_DIR}.gc-version.txt" | xargs)}"
	if [ $? -ne 0 ]; then
		GITCID_VERSION="$GITCID_VERSION_DEFAULT"
	fi

	echo "$GITCID_VERSION"
}

gitcid_get_project_link() {
	echo "https://gitlab.com/defcronyke/gitcid"
}

gitcid_get_project_author() {
	echo "Copyright (c) 2021 Jeremy Carter <jeremy@jeremycarter.ca>"
}

gitcid_get_project_license() {
	echo "MIT License: https://gitlab.com/defcronyke/gitcid/-/blob/master/LICENSE"
}

gitcid_get_init_info() {
	echo "GitCid $(gitcid_get_project_version) ${BASH_SOURCE[0]}"
}

gitcid_get_init_header() {
	echo "$(gitcid_get_init_info)"
	echo "------"
	echo "$(gitcid_get_project_author)"
	echo "$(gitcid_get_project_license)"
	echo "Website: $(gitcid_get_project_link)"
	echo "------"
	echo ""
	echo "Description: ${BASH_SOURCE[0]} - Initialize a new git repository (or several), either locally or at an ssh server path."
	echo ""
	echo "Summary: ${BASH_SOURCE[0]} [-h | --help | -b | --bare | -i | -V] [-v|--verbose] [./repo[.git] ...] [[user@]remote:~/repo[.git] ...]"
	echo ""
	echo "You can override the following environment variables if you want:"
	echo "GITCID_NEW_REPO_PERMISSIONS=\"${GITCID_NEW_REPO_PERMISSIONS}\""
	echo "GITCID_NEW_REPO_PATH_DEFAULT=\"./repo\""
	echo "GITCID_DIR=\"${GITCID_DIR}\""
	echo "GITCID_LOG_DIR=\"${GITCID_LOG_DIR}\""
	echo ""
	echo "------"
}

gitcid_get_init_usage() {
	echo "$(gitcid_get_init_header)"
	echo ""
	echo "Usage: ${BASH_SOURCE[0]} [OPTION] [-v | --verbose] [-b | --bare] [ARGUMENT ...]"
	echo ""
	echo "Example: ${BASH_SOURCE[0]} -v ./new-local-repo user@some-ssh-server:~/new-remote-repo"
	echo ""
	echo "With no arguments provided, it defaults to this command: ${BASH_SOURCE[0]} ${GITCID_NEW_REPO_PATH_DEFAULT}"
	echo ""
	echo "OPTIONS"
	echo "-------"
	echo "[ -h | --help ]		- Print this help message, and exit."
	echo "[ -i | --info ]		- Print the name and some other info about this command, and exit."
	echo "[ -b | --bare ]		- Make bare git repositories, suitable for hosting git remotes."
	echo "[ -V | --version ]	- Print the version of this command, and exit."
	echo "[ -v | --verbose ]	- Activate a more verbose style of output."
	echo ""
	echo "ARGUMENT EXAMPLES"
	echo "-----------------"
	echo "[ repo[.git] ... ]"
	echo "[ ./rel/path/to/new/local/repo[.git] ... ]"
	echo "[ /abs/path/to/new/local/repo[.git] ... ]"
	echo "[ user@host:~/rel/ssh/path/to/new/remote/repo[.git] ... ]"
	echo "[ user@host:/abs/ssh/path/to/new/remote/repo[.git] ... ]"
}

gitcid_handle_args() {
	GITCID_NEW_REPO_NON_BARE="y"
	GITCID_NEW_REPO_BARE=""

	if [[ $# -ge 1 && ("$1" == "-h" || "$1" == "--help") ]]; then
		shift
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "$(gitcid_get_init_usage $@)"
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "$(gitcid_begin_logs)" >/dev/null
		HANDLED_ARGS=("$@")
		gitcid_return_now="y"

		return 0

	elif [[ $# -ge 1 && ("$1" == "-i" || "$1" == "--info") ]]; then
		shift
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "$(gitcid_get_init_info $@)"
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "$(gitcid_begin_logs)" >/dev/null
		HANDLED_ARGS=("$@")
		gitcid_return_now="y"

		return 0

	elif [[ $# -ge 1 && ("$1" == "-V" || "$1" == "--version") ]]; then
		shift
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "$(gitcid_get_project_version $@)"
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "$(gitcid_begin_logs)" >/dev/null
		HANDLED_ARGS=("$@")
		gitcid_return_now="y"

		return 0
	
	elif [[ $# -ge 1 && ("$1" == "-b" || "$1" == "--bare") ]]; then
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "$(gitcid_get_init_header)"
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "$(gitcid_begin_logs)"

		unset GITCID_NEW_REPO_NON_BARE
		GITCID_NEW_REPO_BARE="--bare"
		gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "Making bare git repositories because of the command line option: \"$1\""
		shift
		HANDLED_ARGS=("$@")

		return 0

	elif [[ $# -ge 1 && "${1:0:1}" == "-" ]]; then
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "$(gitcid_get_init_header)"
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "$(gitcid_begin_logs)"

		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Invalid option: \"$1\""
		shift
		HANDLED_ARGS=("$@")

		return 1

	else
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "$(gitcid_get_init_header)"
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "$(gitcid_begin_logs)"

		HANDLED_ARGS=("$@")

		return 0
	fi
}

gitcid_wait_for_background_jobs() {
	for job_pid in ${GITCID_BACKGROUND_JOBS[@]}; do
		any_jobs="y"
		gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "Waiting for GitCid background job to finish: $job_pid"
		wait $job_pid
	done

	GITCID_BACKGROUND_JOBS=()

	if [ ! -z ${any_jobs+x} ]; then
		unset any_jobs
		gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "All GitCid background jobs are finished."
	fi
}

gitcid_mention_update() {
	if [ -f "${GITCID_DIR}.gc-update-available" ]; then
		gitcid_log_update "${BASH_SOURCE[0]}" $LINENO "An updated version of your git repository is available. \
Please run the following command at your earliest opportunity:\n\
git pull" 1>&2
		return 0
	fi

	if [ ! -z ${GITCID_CHECKED_FOR_UPDATES+x} ]; then
		gitcid_log_update_verbose "${BASH_SOURCE[0]}" $LINENO "GitCid is up-to-date." 1>&2
	fi
}

gitcid_init_exit() {
	res=$1
	shift

	gitcid_wait_for_background_jobs

	gitcid_mention_update

	gitcid_log_notice_verbose "${BASH_SOURCE[0]}" $LINENO "GitCid script finished: $0 $@"

	if [ $res -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "GitCid script finished with an error.\nexit code:\n$res"
	else
		gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "exit code:\n$res"
	fi

	return $res
}

gitcid_make_new_git_repo() {
	GITCID_NEW_REPO_PATH=${1:-"${GITCID_NEW_REPO_PATH_DEFAULT}"}
	GITCID_NEW_REPO_PATHS=("${GITCID_NEW_REPO_PATH}")
	GITCID_GIT_INIT_SHARED_DOCS_URL="https://git-scm.com/docs/git-init#Documentation/git-init.txt---sharedfalsetrueumaskgroupallworldeverybody0xxx"
	GITCID_INIT_TEMPLATE_DIR=${GITCID_INIT_TEMPLATE_DIR:-"${GITCID_DIR}.gc-init-template/"}

	if [ $# -le 0 ]; then
		gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "No path argument provided for the new git repo. Using default local path: \"$GITCID_NEW_REPO_PATH\""
	
	else
		GITCID_NEW_REPO_PATHS=("$@")
	fi
	
	gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "GITCID_NEW_REPO_PATHS=(${GITCID_NEW_REPO_PATHS[@]})"

	for new_repo_in_path in "${GITCID_NEW_REPO_PATHS[@]}"; do
		GITCID_NEW_REPO_PATH="$(echo "${new_repo_in_path}" | rev | cut -d'/' -f2- | rev)"
		GITCID_NEW_REPO_NAME="$(echo "${new_repo_in_path}" | rev | cut -d'/' -f1 | rev)"

		echo "${new_repo_in_path}" | grep "/" >/dev/null
		if [ $? -ne 0 ]; then
			gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "The new repo name has no path, it just has a name. Assuming we want to make it in the current working directory."
			GITCID_NEW_REPO_PATH="."
		fi

		GITCID_NEW_REPO_SUFFIX=${GITCID_NEW_REPO_SUFFIX:-".git"}

		echo "$GITCID_NEW_REPO_NAME" | grep -P "^.+\\${GITCID_NEW_REPO_SUFFIX}$" >/dev/null
		if [ $? -ne 0 ] && [ -z ${GITCID_NEW_REPO_NON_BARE+x} ]; then
			GITCID_NEW_REPO_NAME="${GITCID_NEW_REPO_NAME}${GITCID_NEW_REPO_SUFFIX}"
			gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "Adding \"${GITCID_NEW_REPO_SUFFIX}\" to the end of the new repo name: ${GITCID_NEW_REPO_NAME}"
		fi
		
		gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "New git repo permissions (for the \"git init --shared\" option): ${GITCID_NEW_REPO_PERMISSIONS}"
		gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "See the docs for \"git init --shared\" for more possible settings:"
		gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "${GITCID_GIT_INIT_SHARED_DOCS_URL}"

		echo "$GITCID_NEW_REPO_PATH" | grep -P ".*@*.+:.+" >/dev/null
		GITCID_IS_SSH_PATH=$?

		GITCID_NEW_REPO_PATH_DIR=$(echo "$GITCID_NEW_REPO_PATH" | cut -d':' -f2)

		if [ -z ${GITCID_NEW_REPO_NON_BARE+x} ]; then
			GITCID_NEW_EXCLUDE_FILE="info/exclude"
		else
			GITCID_NEW_EXCLUDE_FILE=".git/info/exclude"
		fi

		if [ ! -z "${GITCID_VERBOSE_OUTPUT}" ]; then
			GITCID_RSYNC_VERBOSE_FLAG="-v --progress"
		else
			GITCID_RSYNC_VERBOSE_FLAG=""
		fi

		if [ $GITCID_IS_SSH_PATH -eq 0 ]; then
			gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "Initializing new git repo at ssh destination: ${GITCID_NEW_REPO_PATH}/${GITCID_NEW_REPO_NAME}"

			GITCID_NEW_REPO_PATH_HOST=$(echo "$GITCID_NEW_REPO_PATH" | cut -d':' -f1)

			ssh "$GITCID_NEW_REPO_PATH_HOST" "mkdir -p ${GITCID_NEW_REPO_PATH_DIR}/${GITCID_NEW_REPO_NAME}"

			rsync ${GITCID_RSYNC_VERBOSE_FLAG} -Ra "${GITCID_DIR}" ${GITCID_NEW_REPO_PATH_HOST}:"${GITCID_NEW_REPO_PATH_DIR}/${GITCID_NEW_REPO_NAME}" \
				--exclude "${GITCID_LOG_DIR}"
			
			scp "${GITCID_DIR}../README.md" $GITCID_NEW_REPO_PATH_HOST:${GITCID_NEW_REPO_PATH_DIR}/"${GITCID_NEW_REPO_NAME}/README-gitcid.md" >/dev/null 2>&1 || \
			scp "${GITCID_DIR}../README-gitcid.md" $GITCID_NEW_REPO_PATH_HOST:${GITCID_NEW_REPO_PATH_DIR}/"${GITCID_NEW_REPO_NAME}/README-gitcid.md" >/dev/null 2>&1
			
			output_git_init="Running ssh... $(ssh "$GITCID_NEW_REPO_PATH_HOST" \
"git init --shared=${GITCID_NEW_REPO_PERMISSIONS} ${GITCID_NEW_REPO_BARE} ${GITCID_NEW_REPO_PATH_DIR}/${GITCID_NEW_REPO_NAME}")"
			
			res_git_init=$?
			if [ $res_git_init -ne 0 ]; then
				gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "$output_git_init"
				gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed initializing new remote git repo: ${GITCID_NEW_REPO_PATH}/${GITCID_NEW_REPO_NAME}"
				
				return $res_git_init
			
			else
				gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "$output_git_init"

				ssh "$GITCID_NEW_REPO_PATH_HOST" \
"cd ${GITCID_NEW_REPO_PATH_DIR}/${GITCID_NEW_REPO_NAME} && \
git config core.hooksPath \"${GITCID_GIT_HOOKS_CLIENT_DIR}\" && \
cp \"${GITCID_DIR}.gc-git-exclude\" \"${GITCID_NEW_EXCLUDE_FILE}\" && \
git config receive.advertisePushOptions true"
			fi

			gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "New git repo initialized at remote destination: ${GITCID_NEW_REPO_PATH_HOST}:${GITCID_NEW_REPO_PATH_DIR}/${GITCID_NEW_REPO_NAME}"
		
		else
			gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "Initializing new git repo at local destination: ${GITCID_NEW_REPO_PATH}/${GITCID_NEW_REPO_NAME}"

			mkdir -p ${GITCID_NEW_REPO_PATH_DIR}/${GITCID_NEW_REPO_NAME}

			rsync ${GITCID_RSYNC_VERBOSE_FLAG} -Ra "${GITCID_DIR}" "${GITCID_NEW_REPO_PATH_DIR}/${GITCID_NEW_REPO_NAME}" \
				--exclude "${GITCID_LOG_DIR}"

			cp "${GITCID_DIR}../README.md" ${GITCID_NEW_REPO_PATH_DIR}/"${GITCID_NEW_REPO_NAME}/README-gitcid.md" 2>/dev/null || \
			cp "${GITCID_DIR}../README-gitcid.md" ${GITCID_NEW_REPO_PATH_DIR}/"${GITCID_NEW_REPO_NAME}/README-gitcid.md" 2>/dev/null

			output_git_init="$(git init --shared=${GITCID_NEW_REPO_PERMISSIONS} ${GITCID_NEW_REPO_BARE} "${GITCID_NEW_REPO_PATH}/${GITCID_NEW_REPO_NAME}" 2>&1)"
			res_git_init=$?
			if [ $res_git_init -ne 0 ]; then
				gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "$output_git_init"
				gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed initializing new local git repo: ${GITCID_NEW_REPO_PATH}/${GITCID_NEW_REPO_NAME}"
				
				return $res_git_init
			
			else
				gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "$output_git_init"
				
				pwd="$PWD"
				cd "${GITCID_NEW_REPO_PATH_DIR}/${GITCID_NEW_REPO_NAME}"
				git config core.hooksPath "${GITCID_GIT_HOOKS_CLIENT_DIR}"
				cp "${GITCID_DIR}.gc-git-exclude" "${GITCID_NEW_EXCLUDE_FILE}"
				git config receive.advertisePushOptions true
				cd "$pwd"
			fi

			gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "New git repo initialized at local destination: ${GITCID_NEW_REPO_PATH}/${GITCID_NEW_REPO_NAME}"
		fi

	done
}

gitcid_init() {
	GITCID_DIR=${GITCID_DIR:-".gc/"}
	GITCID_NEW_REPO_PERMISSIONS=${GITCID_NEW_REPO_PERMISSIONS:-"0640"}

  # ----------
  # Do some minimal git config setup to make some annoying yellow warning text stop 
  # showing on newer versions of git.

  # When doing "git pull", merge by default instead of rebase.
  git config --global pull.rebase >/dev/null 2>&1 || \
  git config --global pull.rebase false >/dev/null 2>&1

  # When doing "git init", use "master" for the default branch name.
  git config --global init.defaultBranch >/dev/null 2>&1 || \
  git config --global init.defaultBranch master >/dev/null 2>&1
  # ----------

	source "${GITCID_DIR}deps.sh" $@
	res_import_deps=$?
	if [ $res_import_deps -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed importing GitCid dependencies. I guess it's not going to work, sorry!"
		return $res_import_deps
	fi

	# Remove verbose flag from options, if present,
	# because it's handled in .gc/deps.sh.
	source <(source "${GITCID_UTIL_DIR}verbose.env" $@)
	res_import_deps=$?
	if [ $res_import_deps -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed importing GitCid verbose utils. I guess it's not going to work, sorry!"
		return $res_import_deps
	fi

	gitcid_handle_args $@
	res_gitcid_handle_args=$?
	if [ $res_gitcid_handle_args -ne 0 ]; then
		return $res_gitcid_handle_args
	fi
	set -- "${HANDLED_ARGS[@]}"

	if [ ! -z ${gitcid_return_now+x} ]; then
		return 0
	fi

	GITCID_NEW_REPO_BARE=${GITCID_NEW_REPO_BARE:-$(if [ -z ${GITCID_NEW_REPO_NON_BARE+x} ]; then echo "--bare"; else echo ""; fi)}
	GITCID_NEW_REPO_NAME_DEFAULT=${GITCID_NEW_REPO_NAME_DEFAULT:-$(if [ -z ${GITCID_NEW_REPO_NON_BARE+x} ]; then echo "repo.git"; else echo "repo"; fi)}
	GITCID_NEW_REPO_PATH_DEFAULT=${GITCID_NEW_REPO_PATH_DEFAULT:-"./${GITCID_NEW_REPO_NAME_DEFAULT}"}

	gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "Running script: ${BASH_SOURCE[0]} $@"

	gitcid_make_new_git_repo $@
	res_make_new_git_repo=$?
	if [ $res_make_new_git_repo -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed making new git repo. I guess it's not going to work, sorry!"
		
		return $res_make_new_git_repo
	fi
}

gitcid_init $@

gitcid_init_exit $? $@
