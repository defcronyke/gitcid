#!/usr/bin/env bash
# Run this to list all detected git servers on 
# your network.

gitcid_git_servers_open() {
  in_args="$@"

  .gc/git-servers.sh $@ >/dev/null 
  res=$?
  
  if [ $res -eq 0 ]; then
    cd .gc/discover-git-server-dns && \
    ./git-web-open.sh $@ && \
    cd ../..
  fi

  return $res
}

gitcid_git_servers_open $@
