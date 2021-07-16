#!/bin/bash
# Try to push twice, just in case the first time
# failed for some unusual reason and might work
# on second try.
#
# This is useful for example, when the remote
# didn't have Docker installed before and has
# it installed by GitCid, then it's needed to
# push a second time for the user to gain its
# newly granted docker group permissions to be
# able to operate docker for CI/CD.

gitcid_push() {
  git push $@ || \
  git push $@
}

gitcid_push $@
