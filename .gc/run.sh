#!/usr/bin/env bash

gitcid_run() {
    GITCID_DIR=${GITCID_DIR:-".gc/"}
    GITCID_UTIL_DIR=${GITCID_UTIL_DIR:-"${GITCID_DIR}.gc-util/"}
    GITCID_PIPELINE_CONF_FILE=${GITCID_PIPELINE_CONF_FILE:-"${GITCID_DIR}.gitcid.yml"}

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
    GITCID_CURRENT_BRANCH=${GITCID_CURRENT_BRANCH:-"$(gitcid_get_current_branch)"}
    GITCID_DEFAULT_REMOTE=${GITCID_DEFAULT_REMOTE:-"$(gitcid_get_default_remote)"}
    GITCID_DEFAULT_REMOTE_PATH=${GITCID_DEFAULT_REMOTE_PATH:-"$(gitcid_get_default_remote_path)"}

    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "This git repo's default branch is: ${GITCID_DEFAULT_BRANCH}"
    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "This git repo's current branch is: ${GITCID_CURRENT_BRANCH}"
    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "This git repo's default remote is: ${GITCID_DEFAULT_REMOTE}"
    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "This git repo's default remote path is: ${GITCID_DEFAULT_REMOTE_PATH}"
    gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "Running GitCid pipeline defined in config file: ${GITCID_PIPELINE_CONF_FILE}"

    GITCID_YML_ARCH=${GITCID_YML_ARCH:-"$(gitcid_get_architecture $@)"}
    GITCID_YML_DEFAULT_BRANCH="${GITCID_DEFAULT_BRANCH}"
    
    GITCID_YML_COMMIT_BRANCH="${GITCID_YML_COMMIT_BRANCH:-"${GITCID_REF_NAME}"}"
    if [ -z "$GITCID_YML_COMMIT_BRANCH" ]; then
        GITCID_YML_COMMIT_BRANCH="${GITCID_CURRENT_BRANCH}"
    fi

    GITCID_YML_UNPARSED="$(cat ${GITCID_PIPELINE_CONF_FILE})"
    # GITCID_YML_UNPARSED="${GITCID_YML_UNPARSEDX%x}"

    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Unparsed ${GITCID_PIPELINE_CONF_FILE}:"
    gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "${GITCID_YML_UNPARSED}\n"

#     GITCID_YML_PARSEDX="$(cat ${GITCID_PIPELINE_CONF_FILE} | \
# sed "s#\${GITCID_YML_COMMIT_BRANCH}#${GITCID_YML_COMMIT_BRANCH}#g" | \
# sed "s#\${GITCID_YML_DEFAULT_BRANCH}#${GITCID_YML_DEFAULT_BRANCH}#g" | \
# sed "s#\${GITCID_YML_ARCH}#${GITCID_YML_ARCH}#g" | \
# "${GITCID_YQ_CMD}" e -; echo x)"
#     GITCID_YML_PARSED="${GITCID_YML_PARSEDX%x}"

    # This one is for the terminal output.
    GITCID_YML_PARSED="$(cat ${GITCID_PIPELINE_CONF_FILE} | \
sed "s#\${GITCID_YML_COMMIT_BRANCH}#${GITCID_YML_COMMIT_BRANCH}#g" | \
sed "s#\${GITCID_YML_DEFAULT_BRANCH}#${GITCID_YML_DEFAULT_BRANCH}#g" | \
sed "s#\${GITCID_YML_ARCH}#${GITCID_YML_ARCH}#g" | \
"${GITCID_YQ_CMD}" -C e -)"

    # This one is for the logs.
    GITCID_YML_PARSED_PLAIN="$(cat ${GITCID_PIPELINE_CONF_FILE} | \
sed "s#\${GITCID_YML_COMMIT_BRANCH}#${GITCID_YML_COMMIT_BRANCH}#g" | \
sed "s#\${GITCID_YML_DEFAULT_BRANCH}#${GITCID_YML_DEFAULT_BRANCH}#g" | \
sed "s#\${GITCID_YML_ARCH}#${GITCID_YML_ARCH}#g" | \
"${GITCID_YQ_CMD}" e -)"

    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Parsed ${GITCID_PIPELINE_CONF_FILE}:"
    printf '%b\n' "${GITCID_YML_PARSED}"
    gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "${GITCID_YML_PARSED_PLAIN}\n" >/dev/null

#     gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "$(cat ${GITCID_PIPELINE_CONF_FILE} | \
# sed "s#\${GITCID_YML_COMMIT_BRANCH}#${GITCID_YML_COMMIT_BRANCH}#g" | \
# sed "s#\${GITCID_YML_DEFAULT_BRANCH}#${GITCID_YML_DEFAULT_BRANCH}#g" | \
# sed "s#\${GITCID_YML_ARCH}#${GITCID_YML_ARCH}#g" | \
# "${GITCID_YQ_CMD}" -C e -)"

    res=$res_import_deps

    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "GitCid script finished: $0 $input_args"

	if [ $res -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "GitCid script finished with an error.\nexit code:\n$res"
	else
		gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "exit code:\n$res"
	fi
}

gitcid_run "$@"
