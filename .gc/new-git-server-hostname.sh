#!/usr/bin/env bash

# Choose an available hostname: git1, git2, git3, ..., gitn
gc_new_git_server_hostname() {
  # Set up DNS discovery features.
  .gc/git-servers.sh

  # You can change the default git server hostname here.
  # A number starting from 1 will be appended to the end
  # to make the complete hostname, for example: git1
  GITCID_NEW_GIT_SERVER_HOSTNAME_PREFIX_DEFAULT="${GITCID_NEW_GIT_SERVER_HOSTNAME_PREFIX_DEFAULT:-"git"}"

  GITCID_NEW_GIT_SERVER_HOSTNAME_PREFIX="$GITCID_NEW_GIT_SERVER_HOSTNAME_PREFIX_DEFAULT"


  gc_git_server_install_os_choose_hostname_current_dir="$PWD"

  cd .gc/discover-git-server-dns


  GITCID_NEW_GIT_SERVER_HOSTNAME_N=1

  GITCID_NEW_GIT_SERVER_TRY_HOSTNAME="${GITCID_NEW_GIT_SERVER_HOSTNAME_PREFIX}${GITCID_NEW_GIT_SERVER_HOSTNAME_N}"

  for i in "$(./git-srv.sh | awk '{print $NF}' | sed 's/\.$//g')"; do
    echo "Checking if hostname taken: $GITCID_NEW_GIT_SERVER_TRY_HOSTNAME"

    ping -c 1 -W 2 $GITCID_NEW_GIT_SERVER_TRY_HOSTNAME >/dev/null 2>&1
    if [ $? -ne 0 ]; then
      break
    fi

    ((GITCID_NEW_GIT_SERVER_HOSTNAME_N++))

    GITCID_NEW_GIT_SERVER_TRY_HOSTNAME="${GITCID_NEW_GIT_SERVER_HOSTNAME_PREFIX}${GITCID_NEW_GIT_SERVER_HOSTNAME_N}"
  done

  GITCID_NEW_GIT_SERVER_HOSTNAME="$GITCID_NEW_GIT_SERVER_TRY_HOSTNAME"

  echo "$GITCID_NEW_GIT_SERVER_HOSTNAME"

  cd "$gc_git_server_install_os_choose_hostname_current_dir"
}

gc_new_git_server_hostname $@
