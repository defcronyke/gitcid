#!/usr/bin/env bash
# Run this to list all detected git servers on 
# your network.

gitcid_git_servers_open() {
  in_args="$@"

  .gc/git-servers.sh $@ >/dev/null && \
  cd .gc/discover-git-server-dns && \
  ./git-web-open.sh $@ && \
  cd ../..

  return $res
}

gitcid_git_servers_open $@
