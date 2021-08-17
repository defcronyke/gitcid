#!/bin/bash
# Run this to make a new git server.
#
# WARNING: The target is intended to be a freshly
# installed Linux distro which will become a
# dedicated git server. This command will attempt
# to install some dependencies, and it will do
# some system configurations on the target which
# you might not prefer to happen on a system that
# you're using for any other purposes!
# 
# PLEASE ONLY POINT THIS COMMAND AT A TARGET THAT
# YOU INTEND TO USE AS A DEDICATED GIT SERVER!
# IT COULD BREAK THE TARGET SYSTEM OTHERWISE!
#
# YOU HAVE BEEN WARNED!!
#

gitcid_new_git_server_detect_servers() {
  # gitcid_new_git_server_detect_servers_start_dir="$PWD"

  

  # # You can change the desired DNS seed server hostname by setting this 
  # # environment variable before running this script if you want.
  # GITCID_DEFAULT_DNS_SEED_SERVER1=${GITCID_DEFAULT_DNS_SEED_SERVER1:-"git1"}

  # GITCID_DNS_SEED_SERVER1=""


  # # If we didn't specify to install on the first DNS seed host, add it
  # # to the list of hosts we'll try.
  # if [[ ! "$@" =~ "$GITCID_DEFAULT_DNS_SEED_SERVER1" ]]; then

  # Detect other git servers and update them, adding DNS 
  # records for the new servers's we're installing now.

  # GITCID_OTHER_DETECTED_GIT_SERVERS=""

  # GITCID_NEW_GIT_SERVER_ARGS="$@"

  GITCID_NEW_GIT_SERVER_REQUESTED_BROWSER_OPEN=1

  if [ $# -ge 1 ] && [[ ! "$1" =~ ^\-.*[R|r]F?f?.*$ ]]; then

    cd "${HOME}"

    if [ ! -d "${HOME}/git-server" ]; then
      curl -sL https://tinyurl.com/git-server-init | bash
    fi
    
    cd "${HOME}/git-server"

    if [ ! -d "${HOME}/git-server/gitcid" ]; then
      source <(curl -sL https://tinyurl.com/gitcid)
    else
      cd "${HOME}/git-server/gitcid"
    fi

    echo ""
    echo "Detecting other git servers on your network. Please wait..."
    echo ""
    echo "  args: ${@:2:$#}"
    echo ""


    .gc/git-servers.sh $(hostname) git1 ${@:2:$#}

    gc_starting_dir="$PWD"

    cd .gc/discover-git-server-dns 2>/dev/null
    if [ $? -ne 0 ]; then
      git clone https://gitlab.com/defcronyke/discover-git-server-dns.git .gc/discover-git-server-dns
      cd .gc/discover-git-server-dns
    fi

    # Add any detected git servers to the list of servers 
    # that we're going to update.
    GITCID_OTHER_DETECTED_GIT_SERVERS=( )

    for i in $(./git-srv.sh $(hostname) git1 ${@:2:$#} | awk '{print $NF}' | sed 's/\.$//' | grep -v -e '^[[:space:]]*$'); do
      GITCID_OTHER_DETECTED_GIT_SERVERS+=( "$i" )
    done

    GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED=( )

    for i in ${GITCID_OTHER_DETECTED_GIT_SERVERS[@]}; do
      echo "${GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED[@]}" | grep "$i"

      if [ $? -ne 0 ]; then
        GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED+=( "$i" )
      fi
    done

    for i in ${@:2:$#}; do
      echo "${GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED[@]}" | grep "$i"

      if [ $? -ne 0 ]; then
        GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED+=( "$i" )
      fi
    done

    # echo "${GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED[@]}" | grep "$2" >/dev/null
    # if [ $? -ne 0 ]; then
    #   GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED+=( "$2" )
    # fi

    cd "$gc_starting_dir"

    echo "Reachable git servers found:"
    echo ""
    echo "${GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED[@]}"
    echo ""

    echo "Installing and updating the following git servers:"
    echo ""
    echo "$1 ${GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED[@]}"
    echo ""


    # fi




    # Prevent browser from opening the first time if we're
    # running more than once.
    if [ $# -ge 3 ] || [ ! -z "$GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED" ]; then

      if [[ "$@" =~ ^.*\-.*o.*[[:space:]]*.*$ ]]; then
        GITCID_NEW_GIT_SERVER_REQUESTED_BROWSER_OPEN=0

        # GITCID_NEW_GIT_SERVER_ARGS="$(echo "$@" | sed 's/^\(.*\-.*\)\(o\)\(.*\s*.*\)$/\1\3/g')"
        
        echo "Filtered args:"
        echo ""
        echo "  $1 ${GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED[@]}"
        echo ""
      fi
    fi

  else
    GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED="${@:2:$#}"
  fi

  # cd "${gitcid_new_git_server_detect_servers_start_dir}"
}

gitcid_new_git_server() {
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

  git pull >/dev/null 2>&1

  ${GITCID_DIR}new-git-server-main.sh $@

  return $?
}

# Start installing new git servers.
gitcid_new_git_server_detect_servers $@
gitcid_new_git_server $1 ${GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED[@]}


# Enable the "at" command, to launch things at some later time.
sudo systemctl enable --now atd

# Run this again every 10 minutes to keep DNS list of git servers 
# up-to-date, as well as all the dependencies and software.
# TODO: Choose the best timing for this.
echo 'sudo systemctl restart git-server-startup' | at now +2 minutes 2>/dev/null




# # Run the installer two more times so DNS records can 
# # propagate to many peers.
# if [ $# -ge 1 ] && [[ ! "$1" =~ ^\-.*[R|r]F?f?.*$ ]]; then
#   if [ $# -ge 3 ] || [ ! -z "$GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED" ]; then
#     echo "Updating the following git servers so they're all aware of each other:"
#     echo ""
#     echo "$1 ${GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED[@]}"
#     echo ""

#     # Second run.
#     gitcid_new_git_server_detect_servers $@
#     gitcid_new_git_server $1 ${GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED[@]}

#     # Third run.
#     gitcid_new_git_server_detect_servers $@
#     gitcid_new_git_server $1 ${GITCID_OTHER_DETECTED_GIT_SERVERS_FILTERED[@]}

#     # # Enable ufw firewall if not enabled.
#     # #
#     # # TODO: Support custom hostnames (with number on end)
#     # # instead of just: git1, git2, ..., gitn
#     # if [[ "$(hostname)" =~ ^git[0-9]*$ ]]; then
    
#     #   sudo ufw status | grep "Status: inactive"
    
#     #   if [ $? -eq 0 ]; then
#     #     echo ""
#     #     echo "info: Enabling ufw firewall..."
#     #     sudo ufw --force enable
#     #     echo ""
#     #   fi
#     # fi
#   fi
# fi





# gitcid_new_git_server $@ ${GITCID_OTHER_DETECTED_GIT_SERVERS[@]}

# # Run the installer one more time so DNS records can 
# # propagate to many peers, only if we are installing
# # to more than one peer or updating a DNS seed server.
# if [ $# -ge 3 ] || [ ! -z "$GITCID_DNS_SEED_SERVER1" ]; then
#   gitcid_new_git_server $@ $GITCID_DNS_SEED_SERVER1
# fi
