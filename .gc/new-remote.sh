#!/bin/bash
# Run this to make a new remote git repo:
#
#   Usage:
#     .gc/new-remote.sh [ssh_path | local_path]
#
#   Examples:
#     .gc/new-remote.sh git1:~/repo1.git
#     .gc/new-remote.sh repo1.git
#
# Create a new git remote (a.k.a. "bare repo"),
# and create a new regular git repo.
#
# Commit a test file into the regular repo,
# then push the commit to the remote.
#
# If anything goes wrong, the push should be
# rejected by the new remote.
#
# On success, this will output instructions on
# how to clone a local copy of your new repo.

gitcid_new_remote() {
  input="$@"
  gc_remote_repo="${1:-"git1:~/repo1.git"}"
  gc_local_repo="repo1"

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


  # Convert new remote repo temporary push path 
  # to the required format, for example:
  # 
  #   hostname:repo1 -> git:~/git/new/repo1.git
  #
  # It will be available for cloning using
  # "git clone" at the following path shortly
  # afterwards (typically after less than 1 
  # minute):
  #
  #   git clone git:~/git/repo1.git
  #

  gc_remote_repo="$(echo "$(echo "$gc_remote_repo" | sed 's/~*\([^\^]\.*git\)*\(\/\)*//g' | sed 's/^.*\(\.git\)$//' | sed 's/\(^.*\:\)\/*\(.*\)\(\.git\)*$/\1~\/git\/new\/\2/').git")"


  # echo "$gc_remote_repo" | grep -vP "^.+:~/git"
  # if [ $? -eq 0 ]; then
  #   # Add if missing: ~/git
  #   gc_remote_repo="$(echo "$gc_remote_repo" | sed 's/^\(.*:\)\(\w\)\(.*\)$/\1~/git\3/')"
  # fi

  # gc_remote_repo="$(echo $gc_remote_repo | sed "s/^\(.*\):\([^]\)//g")"


  # # Add ".git" to the end of the remote repo name if 
  # # it's missing.
  # echo $gc_remote_repo | grep ".git$"
  # if [ $? -ne 0 ]; then
  #   gc_remote_repo="${gc_remote_repo}.git"
  # fi

  tmpdir=""
  tmpdir="$(mktemp -d)"
  currentdir="$PWD"

  .gc/init.sh -b "$gc_remote_repo" && \
  .gc/init.sh "${tmpdir}/${gc_local_repo}" && \
  cd "${tmpdir}/${gc_local_repo}" && \
  date | tee .gc-epoch.txt && \
  git add . && \
  git commit -m "Initial commit" && \
  git remote add origin "$gc_remote_repo" && \
  .gc/push.sh -u origin master; \
  res=$?; \
  cd "$currentdir"

  gc_remote_repo_clone="$(echo $gc_remote_repo | sed 's/\/new//')"
  remote_localname="$(echo $gc_remote_repo_clone | sed 's/.git$//g' | xargs basename)"

  if [ $res -eq 0 ]; then
    echo
    echo "----------"
    echo
    echo "Created a new remote git repo. To clone your new repo, run this command:"
    echo
    echo "  git clone $gc_remote_repo_clone && cd $remote_localname"
    echo
    echo "To add GitCid to your freshly cloned repo, run this command inside the repo:"
    echo
    echo "  source <(curl -sL https://tinyurl.com/gitcid) -e"
    echo
    echo "----------"
    echo
  fi

  if [ "$tmpdir" == "/" ] || \
    [ "$tmpdir" == "." ] || \
    [ "$tmpdir" == ".." ] || \
    [ "$tmpdir" == "~" ] || \
    [ "$tmpdir" == "$HOME" ] || \
    [ "$tmpdir" == "*" ]; then
    echo "warning: Tried to delete something we shouldn't."
    return 1
  fi

  rm -rf "$tmpdir"

  return $res
}

gitcid_new_remote "$@"
