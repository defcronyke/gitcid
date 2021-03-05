#!/usr/bin/env bash

gc_init_git_server_usage() {
    echo "GitCid $0"
    echo "Initialize a new git server, either locally or at an ssh server path."
    echo ""
    echo "Usage: $0 <target-local-or-ssh-path>"
    echo ""
    return 1
}

gc_init_git_server() {
    if [ $# -le 0 ]; then
        gc_init_git_server_usage $@
        return $?
    fi

    echo "$(date -Ins)  info: Running script: $0 $@"

    GITCID_DIR=${GITCID_DIR:-"./.gc/"}

    source "${GITCID_DIR}deps.sh"
    res_import_deps=$?
    if [ $res_import_deps -ne 0 ]; then
        gc_log_err "Failed importing GitCid dependencies. I guess it's not going to work, sorry!"
        return $res_import_deps
    fi

    GITCID_NEW_REPO_PATH=${GITCID_NEW_REPO_PATH:-"$(echo "$1" | rev | cut -d'/' -f2- | rev)"}
    GITCID_NEW_REPO_NAME=${GITCID_NEW_REPO_NAME:-"$(echo "$1" | rev | cut -d'/' -f1 | rev)"}
    GITCID_NEW_REPO_SUFFIX=${GITCID_NEW_REPO_SUFFIX:-".git"}

    echo "$GITCID_NEW_REPO_NAME" | grep -P "^.+\${GITCID_NEW_REPO_SUFFIX}$" >/dev/null
    if [ $? -ne 0 ]; then
        GITCID_NEW_REPO_NAME="${GITCID_NEW_REPO_NAME}${GITCID_NEW_REPO_SUFFIX}"
        gc_log_info "Adding \"${GITCID_NEW_REPO_SUFFIX}\" to the end of the new repo name: ${GITCID_NEW_REPO_NAME}"
    fi
    
    echo "$GITCID_NEW_REPO_PATH" | grep -P ".*@*.+:.+" >/dev/null
    GITCID_IS_SSH_PATH=$?

    if [ $GITCID_IS_SSH_PATH -eq 0 ]; then
        gc_log_info "Initializing new git repo at ssh destination: ${GITCID_NEW_REPO_PATH}/${GITCID_NEW_REPO_NAME}"

        GITCID_NEW_REPO_PATH_HOST=$(echo "$GITCID_NEW_REPO_PATH" | cut -d':' -f1)
        GITCID_NEW_REPO_PATH_DIR=$(echo "$GITCID_NEW_REPO_PATH" | cut -d':' -f2)

        ssh "$GITCID_NEW_REPO_PATH_HOST" "git init --bare \"${GITCID_NEW_REPO_PATH_DIR}/${GITCID_NEW_REPO_NAME}\""
        res_git_init=$?
        if [ $res_git_init -ne 0 ]; then
            gc_log_err "Failed initializing new remote git repo: ${GITCID_NEW_REPO_PATH}/${GITCID_NEW_REPO_NAME}"
            return $res_git_init
        fi

        gc_log_info "New git repo initialized at remote destination: ${GITCID_NEW_REPO_PATH_HOST}:${GITCID_NEW_REPO_PATH_DIR}/${GITCID_NEW_REPO_NAME}"
    else
        gc_log_info "Initializing new git repo at local destination: ${GITCID_NEW_REPO_PATH}/${GITCID_NEW_REPO_NAME}"

        git init --bare "${GITCID_NEW_REPO_PATH}/${GITCID_NEW_REPO_NAME}"
        res_git_init=$?
        if [ $res_git_init -ne 0 ]; then
            gc_log_err "Failed initializing new local git repo: ${GITCID_NEW_REPO_PATH}/${GITCID_NEW_REPO_NAME}"
            return $res_git_init
        fi

        gc_log_info "New git repo initialized at local destination: ${GITCID_NEW_REPO_PATH}/${GITCID_NEW_REPO_NAME}"
    fi
}

gc_init_git_server $@
