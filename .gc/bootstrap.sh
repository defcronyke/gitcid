#!/usr/bin/env bash

gitcid_bootstrap() {
	GITCID_GIT_PROJECT_SOURCE="https://gitlab.com/defcronyke/gitcid.git"

	if [ $# -ge 1 ]; then
		new_args=()
		for arg in "$@"; do
			printf "%b\n" "-e" | grep -P "^\-.*e.*$|\-\-existing-repo" >/dev/null
			if [ $? -eq 0 ]; then
				GITCID_EXISTING_REPO="y"

				if [ "$arg" != "--existing-repo" ]; then
					new_arg=$(printf "%b" "$arg" | sed -E "s/^(\-.*)(e)(.*)$/\1\3/g")

					if [ "$new_arg" != "-" ]; then
						new_args+=("$new_arg")
					fi
				fi
			else
				new_args+=("$arg")
			fi
		done

		set -- "${new_args[@]}"
	fi

	if [ ! -z ${GITCID_EXISTING_REPO+x} ]; then
		pwd="$PWD"
		echo "note: GitCid is being installed into an existing git repo: $pwd"
		tmpdir="$(mktemp -d)"
		cd "$tmpdir"
		
		git clone ${GITCID_GIT_PROJECT_SOURCE} && cd gitcid && echo "" && \
		.gc/init.sh $@ "$pwd"; \
		cd "$pwd" && \
		.gc/init.sh -h $@

		return 0
	fi

	git clone ${GITCID_GIT_PROJECT_SOURCE} && cd gitcid && echo "" && \
	.gc/init.sh -h $@
}

gitcid_bootstrap $@
