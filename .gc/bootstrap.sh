#!/usr/bin/env bash

gitcid_bootstrap() {
    git clone https://gitlab.com/defcronyke/gitcid.git && cd gitcid && echo "" && \
    .gc/init.sh -h $@
}

gitcid_bootstrap $@
