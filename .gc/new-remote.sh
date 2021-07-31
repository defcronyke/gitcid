#!/usr/bin/env bash
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
  #   ./new-remote.sh hostname:repo1
  #
  # Pushes to this real path on the git server:
  #
  #   --> hostname:~/git/new/repo1.git
  #
  # It will be available for cloning using
  # "git clone" and pushing using "git push" at 
  # the following path shortly afterwards 
  # (typically after less than 1 minute):
  #
  #   git clone git:~/git/repo1.git
  #

  # Check if we're using a special "git server path", for example:
  #
  #   user@hostname:repo1.git
  #     or
  #   hostname:repo1
  #
  gc_git_server_path_detected=1
  gc_test_repo_path="$(echo "$gc_remote_repo" | cut -d: -f2)"
  echo "$gc_test_repo_path" | grep -P "^~|^/" || gc_git_server_path_detected=0
  if [ $gc_git_server_path_detected -eq 0 ]; then
    echo ""
    echo "note: It looks like you've supplied a \"git server path\". Creating new git remote repo using special git server behaviour..."
    gc_remote_repo="$(gc_remote_repo="$gc_remote_repo"; printf '%s:~/git/new/%s.git\n' "$(echo "$gc_remote_repo" | cut -d: -f1)" "$(echo "$gc_remote_repo" | cut -d: -f2 | sed 's/~\/git\/new\///' | sed 's/~\/git//' | sed 's/\.git$//')")"
    echo ""
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

  gc_remote_repo_clone="$(echo $gc_remote_repo | sed 's/\/new//')"
  remote_localname="$(echo $gc_remote_repo_clone | sed 's/.git$//g' | xargs basename)"

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

  echo ""
  echo "----------"
  echo ""
  echo "Cloning a local copy of your new git repo. Please wait..."
  echo ""
  echo "  git clone $gc_remote_repo_clone"

  gc_clone_attempt_count=1
  while [ $gc_clone_attempt_count -le 40 ]; do
    git clone "$gc_remote_repo_clone" 2>/dev/null
    gc_clone_new_remote_res=$?
    
    if [ $gc_clone_new_remote_res -eq 0 ]; then
      cd "$remote_localname"

      # Install GitCid into freshly cloned git repo.
      source <(curl -sL https://tinyurl.com/gitcid) -e >/dev/null 2>&1

      echo ""
      echo "----------"
      echo ""
      echo "Created a new remote git repo, and cloned it:"
      echo ""
      echo "  git clone $gc_remote_repo_clone"
      echo ""
      echo "Your local copy has been cloned to this location:"
      echo ""
      echo "  $PWD"
      echo ""
      echo "To push new commits to your origin git remote:"
      echo ""
      echo "  git push"
      echo ""
      echo "(Optional) To commit and push using GitCid:"
      echo ""
      echo "  .gc/commit-push.sh A commit message."
      echo ""
      echo "----------"
      echo ""

      break
    fi
    
    sleep 1

    ((clone_attempt_count++))
  done





  # if [ $res -eq 0 ]; then
  #   echo ""
  #   echo "----------"
  #   echo ""
  #   echo "Created a new remote git repo. To clone your new repo, run this command:"
  #   echo ""
  #   echo "  git clone $gc_remote_repo_clone && cd $remote_localname"
  #   echo ""
  #   echo "To add GitCid to your freshly cloned repo, run this command inside the repo:"
  #   echo ""
  #   echo "  source <(curl -sL https://tinyurl.com/gitcid) -e"
  #   echo ""
  #   echo "Here's a one-line version of above commands, for copy-paste convenience:"
  #   echo ""
  #   echo "  git clone $gc_remote_repo_clone && cd $remote_localname && \\"
  #   echo "  source <(curl -sL https://tinyurl.com/gitcid) -e"
  #   echo ""
  #   echo "----------"
  #   echo ""
  # fi


  return $res
}

gitcid_new_remote "$@"
