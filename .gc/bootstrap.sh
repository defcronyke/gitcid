#!/usr/bin/env bash
#
# To use this to install GitCid, run the following command:
#
#   source <(curl -sL https://tinyurl.com/gitcid)
#
# If you want to add GitCid to an existing git repo, run this instead:
#
#   source <(curl -sL https://tinyurl.com/gitcid) -e
#
# To clone GitCid and any other related project git repos, for 
# developing or contributing to GitCid, use this command:
#
#   source <(curl -sL https://tinyurl.com/gitcid) -d
#


gitcid_bootstrap() {
	GITCID_OVERRIDE_REPO_TYPE=${GITCID_OVERRIDE_REPO_TYPE:-""}
	
  # GitCid git repo.
  GITCID_GIT_PROJECT_SOURCE="https://gitlab.com/defcronyke/gitcid.git"

  # Related project git repos.
  GITCID_GIT_PROJECT_SOURCE_GIT_SERVER="https://gitlab.com/defcronyke/git-server.git"
  GITCID_GIT_PROJECT_SOURCE_USB_MOUNT_GIT="https://gitlab.com/defcronyke/usb-mount-git.git"
  GITCID_GIT_PROJECT_SOURCE_DISCOVER_GIT_SERVER_DNS="https://gitlab.com/defcronyke/discover-git-server-dns.git"

  # ----------
  # Do some minimal git config setup to make some annoying yellow warning text stop 
  # showing on newer versions of git.

  # When doing "git pull", merge by default instead of rebase.
  git config --global pull.rebase >/dev/null 2>&1 || \
  git config --global pull.rebase false >/dev/null 2>&1

  # When doing "git init", use "master" for the default branch name.
  git config --global init.defaultBranch >/dev/null 2>&1 || \
  git config --global init.defaultBranch master >/dev/null 2>&1
  # ----------

	if [ $# -ge 1 ]; then
		new_args=()
		for arg in "$@"; do
      # If existing repo arg is set: -e
			printf "%b\n" "-e" | grep -P "^\-.*e.*$|\-\-existing-repo" >/dev/null
      # printf "%b\n" "$arg" | grep -P "^\-.*e.*$|\-\-existing-repo" >/dev/null
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

      # If dev arg is set: -d
      printf "%b\n" "-d" | grep -P "^\-.*d.*$|\-\-dev" >/dev/null
      # printf "%b\n" "$arg" | grep -P "^\-.*d.*$|\-\-dev" >/dev/null
			if [ $? -eq 0 ]; then
        # if [ ! -z ${GITCID_EXISTING_REPO+x} ]; then
        #   echo "error: Cannot specify command line flags -e and -d together."
        #   return 2
        # fi

				GITCID_DEV_REPO="y"

			# 	if [ "$arg" != "--dev" ]; then
			# 		new_arg=$(printf "%b" "$arg" | sed -E "s/^(\-.*)(d)(.*)$/\1\3/g")

			# 		if [ "$new_arg" != "-" ]; then
			# 			new_args+=("$new_arg")
			# 		fi
			# 	fi
			# else
			# 	new_args+=("$arg")
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
    
    if [ $? -ne 0 ]; then
      echo "error: Failed entering tmp directory: $tmpdir"
      echo "error: Cannot continue, this isn't going to work, sorry! Exiting..."
      return 1
    fi
		
		git clone ${GITCID_GIT_PROJECT_SOURCE} && cd gitcid && echo "" && \
    .gc/init.sh $@ "$pwd"

    cd "$pwd"

    ls "$tmpdir" >/dev/null && \
    echo "info: Removing tmp directory because we're finished with it: $tmpdir" && \
    rm -rf "$tmpdir" && \
    echo ""

    .gc/init.sh -h $@

    echo ""

		return 0

  elif [ ! -z ${GITCID_DEV_REPO+x} ]; then
		echo "note: GitCid is being installed as well as any related project git repos, for development purposes."

    git clone ${GITCID_GIT_PROJECT_SOURCE} && cd gitcid && echo "" && \
	  .gc/init.sh -h $@; \
    cd ..

    git clone ${GITCID_GIT_PROJECT_SOURCE_GIT_SERVER} && cd git-server && echo "" && \
    source <(curl -sL https://tinyurl.com/gitcid) -e && \
    echo "" && \
	  .gc/init.sh -h $@; \
    cd ..; \
    echo ""

    git clone ${GITCID_GIT_PROJECT_SOURCE_USB_MOUNT_GIT} && cd usb-mount-git && echo "" && \
    source <(curl -sL https://tinyurl.com/gitcid) -e && \
    echo "" && \
	  .gc/init.sh -h $@; \
    cd ..; \
    echo ""
    
    git clone ${GITCID_GIT_PROJECT_SOURCE_DISCOVER_GIT_SERVER_DNS} && cd discover-git-server-dns && echo "" && \
    source <(curl -sL https://tinyurl.com/gitcid) -e && \
    echo "" && \
	  .gc/init.sh -h $@; \
    cd ..; \
    echo ""

    return 0
	fi

	git clone ${GITCID_GIT_PROJECT_SOURCE} && cd gitcid && echo "" && \
	.gc/init.sh -h $@

  echo ""
}

gitcid_bootstrap $@
