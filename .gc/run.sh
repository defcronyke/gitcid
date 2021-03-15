#!/usr/bin/env bash
# This file is meant to be run from a git hook,

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
    gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "Running GitCid pipeline defined in config file: ${GITCID_PIPELINE_CONF_FILE}"

    GITCID_YML_ARCH=${GITCID_YML_ARCH:-"$(gitcid_get_architecture $@)"}
    GITCID_YML_DEFAULT_BRANCH="${GITCID_DEFAULT_BRANCH}"
    
    GITCID_YML_COMMIT_BRANCH="${GITCID_YML_COMMIT_BRANCH:-"${GITCID_REF_NAME}"}"
    if [ -z "$GITCID_YML_COMMIT_BRANCH" ]; then
        GITCID_YML_COMMIT_BRANCH="${GITCID_CURRENT_BRANCH}"
    fi

    GITCID_YML_UNPARSED="$(cat ${GITCID_PIPELINE_CONF_FILE})"

    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Unparsed yaml file: ${GITCID_PIPELINE_CONF_FILE}"
    gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "${GITCID_YML_UNPARSED}\n"

    # Set this to "-v" for some really verbose yaml parser output.
    GITCID_YQ_VERBOSE_FLAG=${GITCID_YQ_VERBOSE_FLAG:-""}

    # This is for the terminal output.
    GITCID_YML_PARSED_COLOUR="$(cat ${GITCID_PIPELINE_CONF_FILE} | \
sed "s#\${GITCID_YML_COMMIT_BRANCH}#${GITCID_YML_COMMIT_BRANCH}#g" | \
sed "s#\${GITCID_YML_DEFAULT_BRANCH}#${GITCID_YML_DEFAULT_BRANCH}#g" | \
sed "s#\${GITCID_YML_ARCH}#${GITCID_YML_ARCH}#g" | \
"${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -eC e -)"

    # This is for the logs.
    GITCID_YML_PARSED="$(cat ${GITCID_PIPELINE_CONF_FILE} | \
sed "s#\${GITCID_YML_COMMIT_BRANCH}#${GITCID_YML_COMMIT_BRANCH}#g" | \
sed "s#\${GITCID_YML_DEFAULT_BRANCH}#${GITCID_YML_DEFAULT_BRANCH}#g" | \
sed "s#\${GITCID_YML_ARCH}#${GITCID_YML_ARCH}#g" | \
"${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -e e -)"

    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "Parsed yaml file: ${GITCID_PIPELINE_CONF_FILE}"
    gitcid_log_echo_nosave_verbose "${BASH_SOURCE[0]}" $LINENO "${GITCID_YML_PARSED_COLOUR}"
    gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "${GITCID_YML_PARSED}\n" >/dev/null

    if [ -z "$GITCID_VERBOSE_OUTPUT" ]; then
        exec 2>/dev/null
    else
        exec 2>/dev/tty
    fi

    GITCID_YML_REGISTRY="$(printf '%b' "$GITCID_YML_PARSED" | \
"${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -e e '.registry' - || echo "docker.io")"
    GITCID_YML_REGISTRY="$(printf '%b' "$GITCID_YML_REGISTRY" | sed 's#null##g')"
    gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "docker registry: $GITCID_YML_REGISTRY"

    GITCID_YML_IMAGE="$(printf '%b' "$GITCID_YML_PARSED" | \
"${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -e e '.image' - || echo "debian:stable-slim")"
    GITCID_YML_IMAGE="$(printf '%b' "$GITCID_YML_IMAGE" | sed 's#null##g')"
    gitcid_log_info "${BASH_SOURCE[0]}" $LINENO "docker image: $GITCID_YML_IMAGE"

    GITCID_YML_WORKFLOW_RULES="$(printf '%b' "$GITCID_YML_PARSED" | \
"${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -e e '.workflow.rules' -)"
    GITCID_YML_WORKFLOW_RULES="$(printf '%b' "$GITCID_YML_WORKFLOW_RULES" | sed 's#null##g')"
    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "docker workflow rules:"
    gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "$GITCID_YML_WORKFLOW_RULES"

    GITCID_YML_BEFORE_SCRIPT="$(printf '%b' "$GITCID_YML_PARSED" | \
"${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -e e '.before_script' -)"
    GITCID_YML_BEFORE_SCRIPT="$(printf '%b' "$GITCID_YML_BEFORE_SCRIPT" | \
sed 's#null##g' | \
sed "s#\${GITCID_YML_STAGE_TYPE}#before_script#g" | \
sed "s#\${GITCID_YML_STAGE_NAME}#before_script#g")"
    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "docker before_script:"
    gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "$GITCID_YML_BEFORE_SCRIPT"

    GITCID_YML_STAGES="$(printf '%b' "$GITCID_YML_PARSED" | \
"${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -e e '. | del(.registry) | del(.image) | del(.workflow) | del(.before_script)' -)"
    GITCID_YML_STAGES="$(printf '%b' "$GITCID_YML_STAGES" | \
sed 's#null##g')"

    GITCID_YML_STAGE_TYPES=($(printf '%b' "$GITCID_YML_STAGES" | \
"${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -e e '.[].stage' -))

    GITCID_YML_STAGE_NAMES=($(printf '%b' "$GITCID_YML_STAGES" | \
"${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -e e 'keys | .[]' -))

    GITCID_YML_STAGES_OUT=()

    # Substitute env vars in yaml file: ${GITCID_YML_STAGE_TYPE}
    GITCID_YML_STAGES_T=()
    t_i=0
    for t in ${GITCID_YML_STAGE_TYPES[@]}; do
        GITCID_YML_STAGES_T+=("$(printf '%b\n' "$GITCID_YML_STAGES" | \
stage=${GITCID_YML_STAGE_NAMES[$t_i]} "${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -e e '.[env(stage)] | {env(stage): .} | .' - | \
sed "s#\${GITCID_YML_STAGE_TYPE}#$t#g")")
        t_i=$((t_i + 1))
    done
    GITCID_YML_STAGES_OUT=("${GITCID_YML_STAGES_T[@]}")

    # Substitute env vars in yaml file: ${GITCID_YML_STAGE_NAME}
    GITCID_YML_STAGES_N=()
    n_i=0
    for n in ${GITCID_YML_STAGE_NAMES[@]}; do
        GITCID_YML_STAGES_N+=("$(printf '%b\n' "${GITCID_YML_STAGES_OUT[@]}" | \
stage=${GITCID_YML_STAGE_NAMES[$n_i]} "${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -e e '.[env(stage)] | {env(stage): .} | .' - | \
sed "s#\${GITCID_YML_STAGE_NAME}#$n#g")")
        n_i=$((n_i + 1))
    done
    GITCID_YML_STAGES_OUT=("${GITCID_YML_STAGES_N[@]}")

    GITCID_YML_STAGES_OUT_PARSED_COLOUR=("$(printf '%b\n' "${GITCID_YML_STAGES_OUT[@]}" | \
"${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -eC e '.' -)")
    GITCID_YML_STAGES_OUT_PARSED=("$(printf '%b\n' "${GITCID_YML_STAGES_OUT[@]}" | \
"${GITCID_YQ_CMD}" ${GITCID_YQ_VERBOSE_FLAG} -e e '.' -)")

    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "docker pipeline stages from file: ${GITCID_PIPELINE_CONF_FILE}"
    gitcid_log_echo_nosave_verbose "${BASH_SOURCE[0]}" $LINENO "${GITCID_YML_STAGES_OUT_PARSED_COLOUR[@]}"
    gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "${GITCID_YML_STAGES_OUT_PARSED[@]}\n" >/dev/null

    exec 2>/dev/tty

    res=$res_import_deps

    gitcid_log_info_verbose "${BASH_SOURCE[0]}" $LINENO "GitCid script finished: $0 $input_args"

	if [ $res -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "GitCid script finished with an error.\nexit code:\n$res"
	else
		gitcid_log_echo_verbose "${BASH_SOURCE[0]}" $LINENO "exit code:\n$res"
	fi
}

gitcid_run "$@"
