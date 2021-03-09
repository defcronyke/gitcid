#!/usr/bin/env bash

gitcid_get_architecture() {
	uname -a | grep "x86_64" >/dev/null
	IS_X64=$?

	uname -a | grep "arm64" >/dev/null
	IS_ARM64=$?

	uname -a | grep "arm" >/dev/null
	IS_ARMHF=$?

	if [ $IS_X64 -eq 0 ]; then
		ARCH=""
	elif [ $IS_ARM64 -eq 0 ]; then
		ARCH="arm64v8/"
	elif [ $IS_ARMHF -eq 0 ]; then
		ARCH="arm32v7/"
	else
		ARCH=""
	fi
}

gitcid_docker_compose_hello_up() {
	gitcid_get_architecture $@

	pwd="$PWD"
	cd "$(dirname "${BASH_SOURCE[0]}")"

	docker network create docker-compose-net --subnet 10.0.1.0/24 2>/dev/null

	cat Dockerfile.tmpl | sed "s@{ARCH}@${ARCH}@g" | tee Dockerfile

	docker-compose up $@
	docker-compose down $@

	cd "$PWD"
}

gitcid_docker_compose_hello_up $@
