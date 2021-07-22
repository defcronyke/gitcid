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

gc_new_git_server_interactive() {
  echo ""
  echo "Are you sure you want to install git server(s) at the ssh path(s): $@ [ y / N ] ? "

  read gc_new_git_server_confirm
  if [ "$gc_new_git_server_confirm" != "y" ] && [ "$gc_new_git_server_confirm" != "Y" ]; then
    echo "Cancelled git server installation."
    echo ""
    return 2
  fi

  return 0
}

tasks=( )

gitcid_new_git_server() {
  gc_new_git_server_open_web_browser=1

  trap 'echo ""; for k in $(jobs -rp); do kill "$k"; done; for i in ${tasks[@]}; do kill "$i" 2>/dev/null; done; gitcid_new_git_server_usage; echo ""; exit 255' INT
  # trap 'echo ""; for i in $tasks; do kill $i; done; echo ""; gitcid_new_git_server_usage; exit 255' INT

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

  if [ $# -lt 1 ]; then
    gitcid_new_git_server_usage $@
    return 0

  elif [ $# -lt 2 ]; then
    gc_new_git_server_interactive $@ || \
    return $?

  else
    if [ "$1" == "-h" ]; then
      shift 1
      gitcid_new_git_server_usage $@
      return 0

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
    else
      echo ""
      echo "error: Invalid arguments: $@"
      echo ""
      gitcid_new_git_server_usage $@
      return 1
    fi
  fi

  echo ""
  echo "Installing new git server(s) at the following ssh path(s): $@"

  # stty tostop
  # stty -tostop
  for j in $@; do
    { ssh -tt $j 'echo ""; echo "-----"; echo "hostname: $(hostname)"; echo "-----"; curl -sL https://tinyurl.com/git-server-init | bash; exit 0'; exit 0; } & tasks+=( $! )
    #  & tasks+=( $! )
  done

  for i in $(jobs -rp); do
    wait $i
    loop_res=$?
    if [ $loop_res -ne 0 ]; then
      for k in $(jobs -rp); do
        kill $k
      done

      for k in ${tasks[@]}; do
        kill $k 2>/dev/null
      done

      return $loop_res
    fi
  done

  # while [ true ]; do
  #   # for i in ${tasks[@]}; do
  #   #   wait $i || \
  #   #   return 0
  #   # done
  # done

  # echo ""; for i in ${tasks[@]}; do wait "$i" 2>/dev/null || return $?; done; echo ""

  return $?
}

gitcid_new_git_server $@
res=$?

echo ""; for i in ${tasks[@]}; do kill "$i" 2>/dev/null; done; echo ""

# List all detected git servers on the network.
if [ $res -eq 0 ]; then
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
fi

exit $res
