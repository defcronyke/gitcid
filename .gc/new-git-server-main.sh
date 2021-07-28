#!/usr/bin/env bash
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

gitcid_new_git_server_usage() {
  echo ""
  echo "Install git servers at ssh target locations."
  echo "-------"
  echo ""
  echo "Currently supported target platforms are:"
  echo ""
  echo "  Debian Stable (amd64)"
  echo "  Debian Testing (amd64)"
  echo "  Raspberry Pi OS (armhf)"
  echo "  Raspberry Pi OS (aarch64)"
  echo ""
  echo "Usage:"
  echo "-----"
  echo ""
  echo "  $0 [-y[o] | -s[o]] [\$USER@]<target new git server's ssh path> [target2 [target3 ...]]"
  echo ""
  echo "Examples"
  echo "--------"
  echo ""
  echo "Interactive:"
  echo ""
  echo "  $0 git1 [pi@git2 [git3 ...]]"
  echo ""
  echo "Interactive, open web browser:"
  echo ""
  echo "  $0 -o git1 [pi@git2 [git3 ...]]"
  echo ""
  echo "Non-interactive:"
  echo ""
  echo "  $0 -y git1 [pi@git2 [git3 ...]]"
  echo ""
  echo "Non-interactive, open web browser:"
  echo ""
  echo "  $0 -yo git1 [pi@git2 [git3 ...]]"
  echo ""
  echo "Sequential mode (instead of the default parallel mode"
  echo "when installing multiple targets), non-interactive:"
  echo ""
  echo "  $0 -s git1 [pi@git2 [git3 ...]]"
  echo ""
  echo "Sequential mode non-interactive, open web browser:"
  echo ""
  echo "  $0 -so git1 [pi@git2 [git3 ...]]"
  echo ""
  echo "--------"
  echo ""
  echo "Full instructions are here:"
  echo ""
  echo "  https://gitlab.com/defcronyke/gitcid#install-a-dedicated-git-server"
  echo ""
  echo "--------"
  echo ""
}

gc_new_git_server_install_cancel() {
  echo ""
  gitcid_new_git_server_usage $@
  echo ""
  echo "Cancelled git server installation."
  echo ""
  return 20
}

gc_new_git_server_interactive() {
  echo ""
  echo "Are you sure you want to install git server(s) at the ssh path(s): $@ [ y / N ] ? "

  read gc_new_git_server_confirm
  if [ "$gc_new_git_server_confirm" != "y" ] && [ "$gc_new_git_server_confirm" != "Y" ]; then
    gc_new_git_server_install_cancel $@ || \
      return $?
  fi

  return 0
}

new_git_server_detect_other_git_servers() {
  echo ""
  echo "GitWeb servers detected on your network:"
  echo ""
  if [ $gc_new_git_server_open_web_browser -eq 0 ]; then
    .gc/git-servers-open.sh $@ 2>/dev/null
    echo ""
    echo "GitWeb pages launched in web browser. If any pages don't"
    echo "load on first attempt, try refreshing the page."
  else
    .gc/git-servers.sh $@ 2>/dev/null
  fi

  echo ""
  echo "To open a web browser tab for each detected GitWeb"
  echo "server and any additional user-specified servers,"
  echo "run this command:"
  echo ""
  echo "  .gc/git-servers-open.sh [[git1] [git2] ...]"
  echo ""
}

gitcid_new_git_server_post() {
    if [ $# -gt 0 ]; then
    echo ""
    echo "args at return: $@"
    echo ""
    
    first_arg=$1
    shift
  fi

  no_sudo_hosts=( )

  new_install_success=1
  
  last_bad=0

  bad_hosts=( )

  for i in $@; do
    mkdir -p $HOME/.ssh
    chmod 700 $HOME/.ssh
    ssh-keygen -F "$i" || ssh-keyscan "$i" >>$HOME/.ssh/known_hosts

    { ssh -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt $i 'sudo -n cat /dev/null; res=$?; if [ $res -ne 0 ]; then echo ""; echo "ERROR: [ HOST: $USER@$(hostname) ]: Host failed running sudo non-interactively, so they cannot be used in parallel mode. Trying again in sequential mode..."; echo ""; echo "-----"; echo "  hostname: $(hostname)"; echo "  user: $USER"; echo "-----"; source <(curl -sL https://tinyurl.com/git-server-init) -s; res=$?; fi; exit $res'; };
    res=$?

    echo "res=$res"

    if [ $res -eq 255 ]; then
      echo "error: Failed connecting with ssh to host: $i"
      continue

    elif [ $res -eq 19 ]; then
      echo ""
      echo "Succeeded at enabling passwordless sudo. Trying parallel mode install..."
      echo ""
      { ssh -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt $i 'echo ""; echo "-----"; echo "  hostname: $(hostname)"; echo "  user: $USER"; echo "-----"; source <(curl -sL https://tinyurl.com/git-server-init); res2=$?; exit $res2'; };
      res2=$?

      echo "res2=$res2"

      if [ $res2 -ne 0 ]; then
        last_bad=$res2
        bad_hosts+=( "$i" )
        echo ""
        echo "ERROR: [ HOST: $i ]: Failed parallel mode install. Sorry, it looks like it's going to take some manual intervention to install a git server on this host, this system can't seem to do it automatically. Giving up."
        echo ""
      else
        new_install_success=0
      fi

    elif [ $res -ne 0 ]; then
      last_bad=$res
      bad_hosts+=( "$i" )
      echo ""
      echo "ERROR: [ HOST: $i ]: Failed running in sequential mode. Return code: $res"
    else
      new_install_success=0
    fi
  done

  echo ""

  if [ $new_install_success -ne 0 ]; then
    gitcid_new_git_server_usage $@
    echo ""
  else
    new_git_server_detect_other_git_servers $@
    echo ""
  fi

  if [ $last_bad -ne 0 ]; then
    echo "ERROR: At least one git server install failed. The last exit error code was: $last_bad"
    echo ""
    echo "ERROR: Hosts that failed installation:"
    echo ""
    for h in ${bad_hosts[@]}; do
      echo "  $h"
    done
    echo ""
  fi

  # current_dir="$PWD"
  # cd ../discover-git-server-dns
  # # git fetch --all
  # git pull
  # ./git-update-srv.sh $@
  # cd "$current_dir"

  return $last_bad
}

gitcid_new_git_server_main() {
  tasks=( )

  trap 'for i in ${tasks[@]}; do kill $i 2>/dev/null; done; for i in $(jobs -p); do kill $i 2>/dev/null; done; gc_new_git_server_install_cancel $@ || return $?' INT

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

  source "${GITCID_DIR}deps.sh" >/dev/null
	res_import_deps=$?
	if [ $res_import_deps -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed importing GitCid dependencies. I guess it's not going to work, sorry!"
		return $res_import_deps
	fi

  if [ $# -ge 1 ]; then
    if [ "$1" == "-r" ]; then
      if [ $# -lt 2 ]; then
        echo ""
        echo "error: New git server installation on a Raspberry Pi requested without a target device path."
        echo ""
        echo "error: Path needs to be similar to: /dev/sdx"
        echo ""

        # exit 1
      else
        echo "$2" | grep -P "^/dev/.+$"
        if [ $? -ne 0 ]; then
          echo ""
          echo "error: New git server installation on a Raspberry Pi requested at an invalid target device path: $2"
          echo ""
          echo "error: Path needs to be similar to: /dev/sdx"
          echo ""

          exit 2
        fi

        echo ""
        echo "New git server installation on a Raspberry Pi requested at target device path: $2"
        echo ""
        echo ""
        echo "----- !! --- !! BIG WARNING !! --- !! -----"
        echo "----- !! --- !! BIG WARNING !! --- !! -----"
        echo ""
        echo "WARNING: !! This procedure will DESTROY ALL DATA ON THE TARGET DEVICE at the path you specified!"
        echo ""
        echo "WARNING: All data on the target device will be permanently lost and unrecoverable!"
        echo ""
        echo "WARNING: The device you're about to erase is: $2"
        echo ""
        echo "WARNING: !! YOU HAVE BEEN WARNED !!"
        echo ""
        echo "----- !! --- !! BIG WARNING !! --- !! -----"
        echo "----- !! --- !! BIG WARNING !! --- !! -----"
        echo ""
        echo ""
        echo "Are you sure you want to install a new git server at this local device path?: $2"
        echo ""
        printf "[ y / N ] ? "
        read gitcid_new_git_server_confirm_destroy_all_data_on_target_device
        echo ""

        if [ "$gitcid_new_git_server_confirm_destroy_all_data_on_target_device" != "y" ] && \
          [ "$gitcid_new_git_server_confirm_destroy_all_data_on_target_device" != "Y" ]; then
          echo ""
          echo "Cancelling..."
          echo ""
          gc_new_git_server_install_cancel $@
          return $?
        fi
        echo "Retreiving the latest Raspberry Pi OS image from their official server if necessary..."
        echo ""
        
        echo ""
      fi
      
      exit 0
    fi
  fi

  gc_new_git_server_open_web_browser=1
  gc_new_git_server_setup_sudo=1

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

  # Install new SSH key for git servers to update DNS.
  start_dir="$PWD"
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  cd "${HOME}/.ssh"

  if [ ! -f "git-server.key" ]; then
    ssh-keygen -t rsa -b 4096 -q -f $HOME/.ssh/git-server.key -N "" -C git-server
    chmod 600 $HOME/.ssh/git-server.key*
  fi

  if [ $# -eq 1 ] && [ "$1" == "-h" ]; then
    shift 1
    gitcid_new_git_server_usage
    return 0

  elif [ $# -eq 0 ]; then
    gitcid_new_git_server_usage
    return 0

  elif [ $# -ge 1 ]; then
    if [ "$1" == "-s" ]; then
      shift 1
      gc_new_git_server_setup_sudo=0

    elif [ "$1" == "-y" ]; then
      shift 1
      
    elif [ "$1" == "-o" ]; then
      shift 1
      gc_new_git_server_open_web_browser=0
      gc_new_git_server_interactive $@ || \
      return $?

    elif [ "$1" == "-yo" ] || [ "$1" == "-oy" ]; then
      shift 1
      gc_new_git_server_open_web_browser=0
    
    elif [ "$1" == "-so" ] || [ "$1" == "-os" ]; then
      shift 1
      gc_new_git_server_setup_sudo=0
      gc_new_git_server_open_web_browser=0

    else
      echo "$1" | grep -P "^\-.+" >/dev/null
      if [ $? -eq 0 ]; then
        echo ""
        echo "error: Invalid arguments: $@"
        echo ""
        gitcid_new_git_server_usage $@
        return 1
      else
        gc_new_git_server_interactive $@ || \
        return $?
      fi
    fi
  fi

  echo ""
  echo ""
  echo "Installing new git server(s) at the following ssh path(s): $@"


  # Install ssh keys on servers
  echo ""
  echo ""
  echo "Installing ssh keys if they aren't added yet."
  for j in $@; do
    echo ""
    echo "Adding git-server key to local ssh config: $HOME/.ssh/git-server.key >> $HOME/.ssh/config"
    cat $HOME/.ssh/config | grep "Host $j" >/dev/null || printf "%b\n" "\nHost $j\n\tHostName $j\n\tUser $USER\n\tIdentityFile ~/.ssh/git-server.key\n\tIdentitiesOnly yes\n" | tee -a $HOME/.ssh/config >/dev/null
    echo ""
    echo "Added key to local $HOME:/.ssh/config for host: $USER@$j"

    echo ""
    echo "Verifying host: $j"
    ssh-keygen -F "$j" || ssh-keyscan "$j" | tee -a $HOME/.ssh/known_hosts >/dev/null
    
    gc_ssh_username="$(cat $HOME/.ssh/config | grep -A2 -P "^Host $j$" | tail -n1 | awk '{print $NF}')"
    echo ""
    echo "Installing ssh key onto host: $gc_ssh_username@$j"

    scp $HOME/.ssh/git-server.key* $j:/home/$gc_ssh_username/.ssh/
    
    echo ""
    echo "Activating ssh key config on host: $gc_ssh_username@$j"
    { ssh -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt $j 'mkdir -p $HOME/.ssh; chmod 700 $HOME/.ssh; touch $HOME/.ssh/config; chmod 600 $HOME/.ssh/config; touch $HOME/.ssh/authorized_keys; chmod 600 $HOME/.ssh/authorized_keys; cat $HOME/.ssh/authorized_keys | grep "$(cat $HOME/.ssh/git-server.key.pub)" >/dev/null || cat $HOME/.ssh/git-server.key.pub | tee -a $HOME/.ssh/authorized_keys >/dev/null; cat $HOME/.ssh/config | grep -P "^Host '$j'$" >/dev/null || printf "%b\n" "\nHost '$j'\n\tHostName '$j'\n\tUser '$gc_ssh_username'\n\tIdentityFile ~/.ssh/git-server.key\n\tIdentitiesOnly yes\n" | tee -a $HOME/.ssh/config >/dev/null; ssh-keygen -F "$j" || ssh-keyscan "$j" | tee -a $HOME/.ssh/known_hosts >/dev/null; exit 0;'; };
    echo ""
    echo "Finished installing ssh key on host: $gc_ssh_username@$j"
    echo ""
  done

  echo "Finished installing ssh keys on hosts."
  echo ""
  echo ""

  for j in $@; do
    gc_ssh_username="$(cat $HOME/.ssh/config | grep -A2 -P "^Host $j$" | tail -n1 | awk '{print $NF}')"

    if [ $gc_new_git_server_setup_sudo -eq 0 ]; then
      echo ""
      echo "Sequential mode: $0 -s $@"
      echo ""
      { ssh -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt $j 'echo ""; echo "-----"; echo "  hostname: $(hostname)"; echo "  user: $USER"; echo "-----"; source <(curl -sL https://tinyurl.com/git-server-init) -s; exit $?'; }
      echo ""
    else
      echo ""
      echo "Parallel mode: $0 $@"
      echo ""
      echo "info: For sequential mode, use this command instead: $0 -s $@"
      echo ""
      echo "info: You need to use sequential mode the first time, to set up passwordless sudo so that parallel mode can work properly."
      echo ""
      { ssh -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt $j 'alias sudo="sudo -n"; echo ""; echo "-----"; echo "  hostname: $(hostname)"; echo "  user: $USER"; echo "-----"; source <(curl -sL https://tinyurl.com/git-server-init); exit $?'; exit $?; } & tasks+=( $! )
    fi
  done

  loop_res=0
  if [ $gc_new_git_server_setup_sudo -ne 0 ]; then
    for i in ${tasks[@]}; do
      wait $i
      loop_res=$?
      if [ $loop_res -eq 255 ]; then
        echo "error: Failed connecting with ssh to host."
        continue
      elif [ $loop_res -ne 0 ]; then
        return $loop_res
      fi
    done
  fi

  # current_dir="$PWD"
  # cd ../discover-git-server-dns
  # # git fetch --all
  # git pull
  # ./git-update-srv.sh $@
  # cd "$current_dir"

  new_git_server_detect_other_git_servers $@ || \
    return $?

  return 0
}

gitcid_new_git_server_main $@; res=$?

if [ $res -ne 0 ]; then
  # If cancelled.
  if [ $res -eq 20 ]; then
    exit $res
  fi

  gitcid_new_git_server_post $@; res2=$?

  exit $res2
fi

exit $res