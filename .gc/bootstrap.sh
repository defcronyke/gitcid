#!/usr/bin/env bash

gitcid_bootstrap() {
	GITCID_GIT_PROJECT_SOURCE="https://gitlab.com/defcronyke/gitcid.git"
	GITCID_OVERRIDE_REPO_TYPE=${GITCID_OVERRIDE_REPO_TYPE:-""}

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

		if [ ! -d ".git" ]; then
			printf "%b\n" "$@" | grep -P "^\-.*b.*$|\-\-bare" >/dev/null
			if [ $? -ne 0 ] && [ -z "$GITCID_OVERRIDE_REPO_TYPE" ]; then
				printf "%b\n" "\nwarning: The current directory doesn't have a \".git/\" folder. \
Assuming it's a bare repo, and treating it as such. To suppress this warning next time, \
run the command with the following flag: -b\n\n\
To override this automatic fix, you can set the following environment variable:\n\
GITCID_OVERRIDE_REPO_TYPE=\"y\"\n"

				new_args=()
				for arg in "$@"; do
					new_args+=("$arg")
				done

				new_args+=("-b")

				set -- "${new_args[@]}"
			fi
		else
			printf "%b\n" "$@" | grep -P "^\-.*b.*$|\-\-bare" >/dev/null
			if [ $? -eq 0 ] && [ -z "$GITCID_OVERRIDE_REPO_TYPE" ]; then
				printf "%b\n" "\nwarning: The current directory has a \".git/\" folder, but the \"-b\" flag was used. \
Assuming it's a normal (non-bare) repo, and treating it as such. To suppress this warning next time, \
run the command without the following flag: -b\n\n\
To override this automatic fix, you can set the following environment variable:\n\
GITCID_OVERRIDE_REPO_TYPE=\"y\"\n"

				new_args=()
				for arg in "$@"; do
					if [ "$arg" != "--bare" ]; then
						new_arg=$(printf "%b\n" "$arg" | sed -E "s/^(\-.*)(b)(.*)$/\1\3/g")

						if [ "$new_arg" != "-" ]; then
							new_args+=("$new_arg")
						fi
					fi
				done

				set -- "${new_args[@]}"
			fi
		fi

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
