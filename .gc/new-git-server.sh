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

gitcid_new_git_server_usage() {
  echo ""
  echo "Install a git server at an ssh target location."
  echo "-------"
  echo ""
  echo "Currently supported target platforms are:"
  echo ""
  echo "  Debian Testing (amd64)"
  echo "  Raspberry Pi OS (armhf)"
  echo "  Raspberry Pi OS (aarch64)"
  echo ""
  echo "Usage:"
  echo "-----"
  echo ""
  echo "  $0 [-y[o]] [\$USER@]<target new git server's ssh path>"
  echo ""
  echo "Examples"
  echo "--------"
  echo ""
  echo "Interactive:"
  echo ""
  echo "  $0 git1"
  echo ""
  echo "Interactive, open web browser:"
  echo ""
  echo "  $0 -o git1"
  echo ""
  echo "Non-interactive:"
  echo ""
  echo "  $0 -y git1"
  echo ""
  echo "Non-interactive, open web browser:"
  echo ""
  echo "  $0 -yo git1"
  echo ""
  echo "--------"
  echo ""
  echo "Full instructions are here:"
  echo ""
  echo "  https://gitlab.com/defcronyke/gitcid"
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
  return 2
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
    .gc/git-servers-open.sh 2>/dev/null
    echo ""
    echo "GitWeb pages launched in web browser. If any pages don't"
    echo "load on first attempt, try refreshing the page."
  else
    .gc/git-servers.sh 2>/dev/null
  fi

  echo ""
  echo "To open a web browser tab for each detected GitWeb server,"
  echo "run this command:"
  echo ""
  echo "  .gc/git-servers-open.sh"
  echo ""
}

gitcid_new_git_server() {
  trap 'gc_new_git_server_install_cancel $@ || return $?' INT

  tasks=( )
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
  echo "Installing new git server(s) at the following ssh path(s): $@"

  for j in $@; do
    if [ $gc_new_git_server_setup_sudo -eq 0 ]; then
      echo ""
      echo "Sequential mode: $0 -s $@"
      echo ""
      { ssh -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt $j 'echo ""; echo "-----"; echo "  hostname: $(hostname)"; echo "  user: $USER"; echo "-----"; source <(curl -sL https://tinyurl.com/git-server-init) -s; exit $?'; } || \
        return $?
      echo ""
    else
      echo ""
      echo "Parallel mode: $0 $@"
      echo ""
      echo "info: For sequential mode, use this command instead: $0 -s $@"
      echo ""
      echo "info: You need to use sequential mode the first time, to set up passwordless sudo so that parallel mode can work properly."
      echo ""
      { ssh -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt $j 'alias sudo="sudo -n"; echo ""; echo "-----"; echo "  hostname: $(hostname)"; echo "  user: $USER"; echo "-----"; source <(curl -sL https://tinyurl.com/git-server-init); exit $?'; } & tasks+=( $! )
    fi
  done

  if [ $gc_new_git_server_setup_sudo -ne 0 ]; then
    for i in ${tasks[@]}; do
      wait $i || \
        return $?
    done
  fi

  new_git_server_detect_other_git_servers $@ || \
    return $?

  return 0
}

gitcid_new_git_server $@
res=$?

if [ $res -ne 0 ]; then
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
    { ssh -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt $i 'sudo -n cat /dev/null; res=$?; if [ $res -ne 0 ]; then echo ""; echo "ERROR: [ HOST: $USER@$(hostname) ]: Host failed running sudo non-interactively, so they cannot be used in parallel mode. Trying again in sequential mode..."; echo ""; echo "-----"; echo "  hostname: $(hostname)"; echo "  user: $USER"; echo "-----"; source <(curl -sL https://tinyurl.com/git-server-init) -s; res=$?; fi; exit $res'; };
    res=$?

    echo "res=$res"

    if [ $res -eq 19 ]; then
      echo ""
      echo "Succeeded at enabling passwordless sudo. Trying parallel mode install..."
      echo ""
      { ssh -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt $i 'echo ""; echo "-----"; echo "  hostname: $(hostname)"; echo "  user: $USER"; echo "-----"; source <(curl -sL https://tinyurl.com/git-server-init); res2=$?; exit $res2'; };
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

  exit $last_bad
fi

if [ $res -eq 0 ]; then
  new_git_server_detect_other_git_servers $@
fi

exit $res
