#!/usr/bin/env bash
# This file is meant to be run from a git hook,

gitcid_run_pipeline_stages() {
    if [ $# -lt 2 ]; then
        echo "Not running any pipeline stages because none were provided."
        return 0
    fi

    GITCID_YML_PARSED="$1"

    gitcid_util_yml_get_docker_registry "$GITCID_YML_PARSED"
    gitcid_util_yml_get_docker_image "$GITCID_YML_PARSED"
    gitcid_util_yml_get_workflow_rules "$GITCID_YML_PARSED"
    gitcid_util_yml_get_before_script "$GITCID_YML_PARSED"

    GITCID_RUN_PIPELINE_STAGES="$2"

    if [ $# -ge 3 ]; then
        GITCID_RUN_PIPELINE_STAGES_OUTPUT="$3"
    else
        GITCID_RUN_PIPELINE_STAGES_OUTPUT="$GITCID_RUN_PIPELINE_STAGES"
    fi

    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "running pipeline stages:"
    gitcid_log_echo_escape_verbose "${BASH_SOURCE[0]}" $LINENO "$GITCID_RUN_PIPELINE_STAGES_OUTPUT"

    first_line="y"

    printf '%s\n' "$GITCID_RUN_PIPELINE_STAGES" | \
"${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -e e '.[] | .script' - | \
    while read stage_script; do
        if [ ! -z "$first_line" ]; then
            unset first_line
            gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "Running pipeline stage script..."
            gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "\n\n---------- begin ----------\n"
        fi

        if [ ! -z "$stage_script" ]; then
            gitcid_log_echo_escape "${BASH_SOURCE[0]}" $LINENO "$(eval $stage_script)"
        fi

        if [ -z "$stage_script" ]; then
            first_line="y"
            gitcid_log_echo "${BASH_SOURCE[0]}" $LINENO "\n----------- end -----------\n\n"
        fi
    done
}

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

    GITCID_CURRENT_BRANCH=${GITCID_CURRENT_BRANCH:-"$(gitcid_get_current_branch)"}
    GITCID_DEFAULT_BRANCH=${GITCID_DEFAULT_BRANCH:-"$(gitcid_get_default_branch)"}
    GITCID_DEFAULT_REMOTE=${GITCID_DEFAULT_REMOTE:-"$(gitcid_get_default_remote)"}
    GITCID_DEFAULT_REMOTE_PATH=${GITCID_DEFAULT_REMOTE_PATH:-"$(gitcid_get_default_remote_path)"}

    gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "current git branch is: ${GITCID_CURRENT_BRANCH}"
    gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "default git branch is: ${GITCID_DEFAULT_BRANCH}"
    gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "default git remote is: ${GITCID_DEFAULT_REMOTE}"
    
    source "${GITCID_UTIL_DIR}yml.env" $@
	res_import_deps=$?
	if [ $res_import_deps -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed importing GitCid yml utils. I guess it's not going to work, sorry!"
		return $res_import_deps
	fi
    
    gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "Running GitCid pipeline defined in config file: ${GITCID_PIPELINE_CONF_FILE}"

    gitcid_util_yml_get_unparsed_yml $@

    if [ -z "$GITCID_VERBOSE_OUTPUT" ]; then
        exec 2>/dev/null
    else
        exec 2>/dev/tty
    fi

    gitcid_util_yml_get_parsed_yml "$GITCID_PIPELINE_CONF_FILE"

    # gitcid_util_yml_get_docker_registry "$GITCID_YML_PARSED"

    # gitcid_util_yml_get_docker_image "$GITCID_YML_PARSED"

    # gitcid_util_yml_get_workflow_rules "$GITCID_YML_PARSED"

    # gitcid_util_yml_get_before_script "$GITCID_YML_PARSED"

    gitcid_util_yml_get_pipeline_stages "$GITCID_YML_PARSED" gitcid_run_pipeline_stages

    if [ -z "$GITCID_VERBOSE_OUTPUT" ]; then
        exec 2>/dev/tty
    fi

    res=$res_import_deps

    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "GitCid script finished: $0 $input_args"

	if [ $res -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "GitCid script finished with an error.\nexit code:\n$res"
	else
		gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "exit code:\n$res"
	fi
}

gitcid_run "$@"
