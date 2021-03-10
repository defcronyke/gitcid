#!/usr/bin/env bash

gitcid_docker_compose_run_up() {
	GITCID_YML_ARCH=${GITCID_YML_ARCH:-"$(gitcid_get_architecture $@)"}

	pwd="$PWD"
	cd "$(dirname "${BASH_SOURCE[0]}")"

	docker network create docker-compose-net --subnet 10.0.1.0/24 2>/dev/null

	cat Dockerfile.tmpl | \
		sed "s@\${GITCID_YML_ARCH}@${GITCID_YML_ARCH}@g" | \
		tee Dockerfile

	docker-compose up -d $@

	cd "$PWD"
}

gitcid_docker_compose_run_up $@
