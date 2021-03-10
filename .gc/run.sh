#!/usr/bin/env bash

gitcid_run() {
    GITCID_DIR=${GITCID_DIR:-".gc/"}
    GITCID_UTIL_DIR=${GITCID_UTIL_DIR:-"${GITCID_DIR}.gc-util/"}

    input_args=$@
    
    source "${GITCID_DIR}deps.sh" $@
	res_import_deps=$?
	if [ $res_import_deps -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed importing GitCid dependencies. I guess it's not going to work, sorry!"
		return $res_import_deps
	fi

    gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "$(gitcid_begin_logs)"

	source <(source "${GITCID_UTIL_DIR}verbose.env" $@)
	res_import_deps=$?
	if [ $res_import_deps -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed importing GitCid verbose utils. I guess it's not going to work, sorry!"
		return $res_import_deps
	fi

    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Running script: ${BASH_SOURCE[0]} $@"

    source "${GITCID_UTIL_DIR}git.env" $@
	res_import_deps=$?
	if [ $res_import_deps -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed importing GitCid git utils. I guess it's not going to work, sorry!"
		return $res_import_deps
	fi

    GITCID_DEFAULT_BRANCH=${GITCID_DEFAULT_BRANCH:-"$(gitcid_get_default_branch)"}
    GITCID_CURRENT_BRANCH="$(gitcid_get_current_branch)"

    gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "This git repo's default branch is: ${GITCID_DEFAULT_BRANCH}"
    gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "This git repo's current branch is: ${GITCID_CURRENT_BRANCH}"

    res=$res_import_deps

    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "GitCid script finished: $0 $input_args"

	if [ $res -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "GitCid script finished with an error.\nexit code:\n$res"
	else
		gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "exit code:\n$res"
	fi
}

gitcid_run "$@"
