#!/usr/bin/env bash

gitcid_docker_compose_hello_down() {
    pwd="$PWD"
    cd "$(dirname "${BASH_SOURCE[0]}")"

    docker-compose down $@

    cd "$PWD"
}

gitcid_docker_compose_hello_down $@
