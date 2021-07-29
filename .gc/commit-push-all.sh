#!/usr/bin/env bash
# Commit and push a git repo.
#
#   Usage:
#     ./commit-push-all.sh Some commit message.
#
# It currently only pushes a master branch 
# to an "all" remote, but this could be
# improved later.
# 
# The purpose of an "all" remote is that you 
# can push to a group of multiple remotes at 
# the same time.
#
# If you'd like to easily add an "all" remote
# to your git repos which points to both
# GitLab and GitHub repos which have the same
# repo name and also same user account name,
# you can use this helper command to do it
# quickly if you want:
#
#   bash <(curl -sL https://tinyurl.com/git-remote-add-multi)
#
# Make sure you have an origin remote set 
# up for your repo before you run the above 
# command, and origin should be either at 
# GitHub or GitLab for that to work properly.

gitcid_commit_push_all() {
  msg="$@"

  git add .; \
  git commit -m "$msg" && \
  .gc/push.sh -u all master
}

gitcid_commit_push_all "$@"
