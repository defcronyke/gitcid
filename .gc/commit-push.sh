#!/bin/bash
# Commit and push a git repo.
#
#   Usage:
#     ./commit-push.sh Some commit message.
#
# It currently only pushes a master branch 
# to an origin remote, but this could be
# improved later.

gitcid_commit_push() {
  msg="$@"

  git add .; \
  git commit -m "$msg" && \
  .gc/push.sh -u origin master
}

gitcid_commit_push "$@"
