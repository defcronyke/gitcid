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

  # Add ".git" to the end of the remote repo name if 
  # it's missing.
  echo $gc_remote_repo | grep ".git$"
  if [ $? -ne 0 ]; then
    gc_remote_repo="${gc_remote_repo}.git"
  fi

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

  remote_localname="$(echo $gc_remote_repo | sed 's/.git$//g' | xargs basename)"

  if [ $res -eq 0 ]; then
    echo
    echo "----------"
    echo
    echo "Created a new remote git repo. To clone your new repo, run this command:"
    echo
    echo "  git clone $gc_remote_repo && cd $remote_localname"
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
