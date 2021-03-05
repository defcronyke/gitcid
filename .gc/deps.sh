#!/usr/bin/env bash

gitcid_detect_sudo() {
    SUDO_GROUPS=${SUDO_GROUPS:-"sudo|wheel"}
    SUDO_CMD=${SUDO_CMD:-""}
    GROUP_FILE_PATH=${GROUP_FILE_PATH:-"/etc/group"}
    WHOAMI_CMD=${WHOAMI_CMD:-"whoami"}

    cat "$GROUP_FILE_PATH" | grep -P "$SUDO_GROUPS" | grep "$("$WHOAMI_CMD")" >/dev/null
    if [ $? -eq 0 ]; then
        gc_log_info "You seem to have sudo privileges. Enabling the sudo command."
        SUDO_CMD=$(if [ -z "$SUDO_CMD" ]; then echo "sudo"; fi)
    fi
}

gitcid_detect_os() {
    gc_log_info "Attempting to find any missing GitCid dependencies and install them."
    
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
        gc_log_warn "Your OS isn't supported. This still might work if you have the following \
dependencies installed:"
        echo "${GITCID_DEPS[@]}"
    fi
}

gitcid_deps() {
    GITCID_DIR=${GITCID_DIR:-"./.gc/"}
    GITCID_DEPS_DIR=${GITCID_DEPS_DIR:-"${GITCID_DIR}.gc-deps/"}
    GITCID_GIT_HOOKS_CLIENT_DIR=${GITCID_GIT_HOOKS_CLIENT_DIR:-"${GITCID_DIR}.git-hooks-client/"}
    GITCID_UTIL_DIR=${GITCID_UTIL_DIR:-"${GITCID_DIR}.gc-util/"}
    GITCID_UTIL_LOG=${GITCID_UTIL_LOG:-"${GITCID_UTIL_DIR}log.env"}

    echo "$(date -Ins)  info: Running script: $PWD/${GITCID_DIR:2}$(basename "$0") $@"

    echo "$(date -Ins)  info: Importing GitCid log utils: ${GITCID_UTIL_LOG}"
    source "${GITCID_UTIL_LOG}"
    res_import_util_log=$?
    if [ $res_import_util_log -ne 0 ]; then
        echo "$(date -Ins)  error: Failed importing GitCid log utils. I guess it's not going to work, sorry!"
        return $res_import_util_log
    fi

    gitcid_detect_sudo $@
    res_detect_sudo=$?
    if [ $res_detect_sudo -ne 0 ]; then
        gc_log_warn "GitCid failed detecting if you have sudo privileges. We will assume you don't, \
so you'll need to run this script as root. It will probably fail now if you aren't root already."
    fi

    gitcid_detect_os $@
    res_detect_os=$?
    if [ $res_detect_os -ne 0 ]; then
        gc_log_err "GitCid failed detecting your OS. I guess it's not going to work, sorry!"
        return $res_detect_os
    fi

    HAS_DEPS=0
    for i in ${GITCID_DEPS_CMDS[@]}; do
        which $i >/dev/null 2>&1
        HAS_DEPS=$?
    done

    if [ $HAS_DEPS -ne 0 ]; then
        gc_log_info "You are missing at least one of these dependencies:"
        echo "${GITCID_DEPS[@]}"
        echo ""
        
        if [ $SUPPORTED_DISTRO -eq 0 ]; then
            gc_log_info "We will try to install them now, using the following command:"
            echo "${GITCID_DEPS_INSTALL_CMD[@]} ${GITCID_DEPS[@]}"
            echo ""

            eval "${GITCID_DEPS_INSTALL_CMD[@]} ${GITCID_DEPS[@]}"
            res=$?

            if [ $res -ne 0 ]; then
                gc_log_err "Failed installing dependencies. You'll need to install them manually then I guess."
                return 2
            fi
        else
            gc_log_err "You are missing some dependencies and your OS isn't supported. \
Please install them yourself and try again afterwards. Maybe it'll work if you do that."
            gc_log_err "You can also try setting the following environment variables to \
please our system, if you know the correct values for your unsupported OS:"
            echo "GITCID_DEPS_INSTALL_CMD=${GITCID_DEPS_INSTALL_CMD[@]}"
            echo "GITCID_DEPS=${GITCID_DEPS[@]}"
            echo "GITCID_DEPS_CMDS=${GITCID_DEPS_CMDS[@]}"
            echo ""
            return 1
        fi
    fi

    gc_log_info "Setting \"$GITCID_GIT_HOOKS_CLIENT_DIR\" as this git repo's \"core.hooksPath\""
    
    git config core.hooksPath "$GITCID_GIT_HOOKS_CLIENT_DIR"
    git_config_res=$?
    if [ $git_config_res -ne 0 ]; then
        gc_log_err "Failed setting this git repo's \"core.hooksPath\". I guess this isn't going to work, sorry!"
        return $git_config_res
    fi

    gc_log_info "All GitCid dependencies are installed."
}

gitcid_deps $@
