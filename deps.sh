#!/usr/bin/env bash

gitcid_detect_os() {
    SUDO_GROUPS=${SUDO_GROUPS:-"sudo|wheel"}
    SUDO_CMD=${SUDO_CMD:-""}

    cat /etc/group | grep -P "sudo|wheel" | grep "$(whoami)" >/dev/null
    if [ $? -eq 0 ]; then
        SUDO_CMD=$(if [ -z "$SUDO_CMD" ]; then echo "sudo"; fi)
    fi

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

    echo "info: running script: $PWD/$(basename "$0") $@"
    echo "info: Attempting to find any missing GitCid dependencies and install them."

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
        source ./arch-deps.env
    elif [ $IS_DEBIAN -eq 0 ]; then
        source ./debian-deps.env
    elif [ $IS_FEDORA -eq 0 ]; then
        source ./fedora-deps.env
    elif [ $IS_FEDORA_OLD -eq 0 ]; then
        source ./fedora-old-deps.env
    else
        SUPPORTED_DISTRO=1
        source ./unsupported-deps.env
        echo "warning: Your OS isn't supported. This still might work if you have the following dependencies installed:"
        echo "${GITCID_DEPS[@]}"
    fi
}

gitcid_deps() {
    gitcid_detect_os $@
    res_detect_os=$?

    if [ $res_detect_os -ne 0 ]; then
        echo "error: GitCid failed detecting your OS. I guess it's not going to work, sorry!"
        return $res_detect_os
    fi

    HAS_DEPS=0
    for i in ${GITCID_DEPS_CMDS[@]}; do
        which $i >/dev/null 2>&1
        HAS_DEPS=$?
    done

    if [ $HAS_DEPS -ne 0 ]; then
        echo "info: You are missing at least one of these dependencies:"
        echo "${GITCID_DEPS[@]}"
        echo ""
        
        if [ $SUPPORTED_DISTRO -eq 0 ]; then
            echo "info: We will try to install them now, using the following command:"
            echo "${GITCID_DEPS_INSTALL_CMD[@]} ${GITCID_DEPS[@]}"
            echo ""

            eval "${GITCID_DEPS_INSTALL_CMD[@]} ${GITCID_DEPS[@]}"
            res=$?

            if [ $res -ne 0 ]; then
                echo "error: Failed installing dependencies. You'll need to install them manually then I guess."
                return 2
            fi
        else
            echo "error: You are missing some dependencies and your OS isn't supported. \
Please install them yourself and try again afterwards. Maybe it'll work if you do that."
            echo "error: You can also try setting the following environment variables to \
please our system, if you know the correct values for your unsupported OS:"
            echo "GITCID_DEPS_INSTALL_CMD=${GITCID_DEPS_INSTALL_CMD[@]}"
            echo "GITCID_DEPS=${GITCID_DEPS[@]}"
            echo "GITCID_DEPS_CMDS=${GITCID_DEPS_CMDS[@]}"
            echo ""
            return 1
        fi
    fi

    echo "info: Setting ./git-hooks-client/ as this git repo's \"core.hooksPath\""
    
    git config core.hooksPath ./git-hooks-client
    git_config_res=$?
    if [ $git_config_res -ne 0 ]; then
        echo "error: Failed setting this git repo's \"core.hooksPath\". I guess this isn't going to work, sorry!"
        return $git_config_res
    fi

    echo "info: All GitCid dependencies are installed."
}

gitcid_deps $@
