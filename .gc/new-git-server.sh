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
  echo "  Raspberry Pi OS (aarch64)"
  echo ""
  echo ""
  echo "usage: $0 [-y[o]] <target new git server's ssh path>"
  echo "-----"
  echo ""
  echo "Examples"
  echo "--------"
  echo "Interactive:"
  echo "  $0 $USER@git1"
  echo ""
  echo "Interactive, open web browser:"
  echo "  $0 -o $USER@git1"
  echo ""
  echo "Non-interactive:"
  echo "  $0 -y $USER@git1"
  echo ""
  echo "Non-interactive, open web browser:"
  echo "  $0 -yo $USER@git1"
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
  echo "Are you sure you want to install a git server at the ssh path: $gc_new_git_server_target [ y / N ] ? "

  read gc_new_git_server_confirm
  if [ "$gc_new_git_server_confirm" != "y" ] && [ "$gc_new_git_server_confirm" != "Y" ]; then
    echo "Cancelled git server installation."
    echo ""
    return 2
  fi
}

gitcid_new_git_server() {
  input="$@"
  gc_new_git_server_open_web_browser=1

  trap 'echo ""; gitcid_new_git_server_usage; exit 255' INT

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
    gitcid_new_git_server_usage
    return 1

  elif [ $# -lt 2 ]; then
    gc_new_git_server_target="$1"
    
    gc_new_git_server_interactive $gc_new_git_server_target || \
    return $?

  else
    if [ "$1" == "-y" ]; then
      gc_new_git_server_target="$2"
    elif [ "$1" == "-o" ]; then
      gc_new_git_server_open_web_browser=0
      gc_new_git_server_interactive $gc_new_git_server_target || \
      return $?
    elif [ "$1" == "-yo" ] || [ "$1" == "-oy" ]; then
      gc_new_git_server_target="$2"
      gc_new_git_server_open_web_browser=0
    else
      gitcid_new_git_server_usage
      return 1
    fi
  fi

  echo ""
  echo "Installing a new git server at the following ssh path: $gc_new_git_server_target"
  echo ""

  ssh -t $gc_new_git_server_target 'curl -sL https://tinyurl.com/git-server-init | bash'
  res=$?

  # List all detected git servers on the network.
  echo ""
  echo "GitWeb servers detected on your network:"
  echo ""
  if [ $gc_new_git_server_open_web_browser -eq 0 ]; then
    .gc/git-servers-open.sh 2>/dev/null
    echo ""
    echo "GitWeb pages launched in web browser. If any pages don't"
    echo "load on first attempt, try refreshing the page."
    echo ""
  else
    .gc/git-servers.sh 2>/dev/null
    echo ""
    echo "To open a web browser tab for each detected GitWeb server,"
    echo "run this command:"
    echo ""
    echo "  .gc/git-servers-open.sh"
    echo ""
  fi

  return $res
}

gitcid_new_git_server $@
