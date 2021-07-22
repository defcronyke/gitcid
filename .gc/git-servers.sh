#!/bin/bash
# Run this to list all detected git servers on 
# your network.

gitcid_git_servers() {
  in_args="$@"

  if [ ! -d ".gc/discover-git-server-dns" ]; then
    git clone https://gitlab.com/defcronyke/discover-git-server-dns.git .gc/discover-git-server-dns >/dev/null 2>&1 && \
    cd .gc/discover-git-server-dns
  else
    cd .gc/discover-git-server-dns && \
    git pull >/dev/null 2>&1
  fi

  ./git-web.sh

  res=$?

  cd ../..

  return $res
}

gitcid_git_servers $@
