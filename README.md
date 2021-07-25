# GitCid | power tools for `git` | gitc.id

---

[![sponsor the project](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&link=https://github.com/sponsors/defcronyke)](https://github.com/sponsors/defcronyke) ⊙ [Copyright © 2021](https://defcronyke.gitlab.io/epaper-idf/jeremy-profile-paint-bw.png) [Jeremy Carter](https://eternalvoid.net) `<`[jeremy@jeremycarter.ca](mailto:Jeremy%20Carter%20<jeremy@jeremycarter.ca>?subject=gitcid)`>`

---

## [Table of Contents](#table-of-contents)

- [GitCid | power tools for `git` | gitc.id](#gitcid--power-tools-for-git--gitcid)
  - [Table of Contents](#table-of-contents)
  - [Links](#links)
  - [Terms of Use](#terms-of-use)
  - [Features](#features)
  - [Dependencies](#dependencies)
  - [Quickstart](#quickstart)
    - [Download GitCid](#download-gitcid)
    - [Create a new git remote with GitCid features](#create-a-new-git-remote-with-gitcid-features)
  - [Usage Examples](#usage-examples)
    - [Get Usage Help](#get-usage-help)
    - [Install GitCid into an existing git repo](#install-gitcid-into-an-existing-git-repo)
    - [Make new git repositories](#make-new-git-repositories)
  - [Install a Dedicated Git Server](#install-a-dedicated-git-server)
    - [TLDR; Let's just install the git server](#tldr-lets-just-install-the-git-server)
    - [Git Server Install Instructions](#git-server-install-instructions)
    - [Git Server Usage Examples](#git-server-usage-examples)

---

## [Links](#links)

[https://gitc.id](https://gitc.id)

[https://gitlab.com/defcronyke/gitcid](https://gitlab.com/defcronyke/gitcid)  
[https://github.com/defcronyke/gitcid](https://github.com/defcronyke/gitcid)

---

## [Terms of Use](#terms-of-use)

Use of this software is governed by the terms of [the included MIT License](https://gitlab.com/defcronyke/gitcid/-/raw/master/LICENSE) ([GitHub mirror](https://raw.githubusercontent.com/defcronyke/gitcid/master/LICENSE)).

---

## [Features](#features)

- Quickly deploy new `git` remotes using `ssh` and `rsync` that you can push to, with `gitcid` tools activated inside them.
- Quickly commit, push, or clone `git` repos, and add `gitcid` tools inside them.
- The `gitcid` tools live inside each local or remote `git` repo, you can add them to any of your existing repos with one command.
- When you add `gitcid` to your repo, it gains built-in `CI/CD` features with a bit of help from `docker-compose` (work-in-progress).
- Specify your `CI/CD pipelines` in a `yaml` format that might be comfortable for you if you've used other `CI/CD` systems before.
- Quickly deploy [`dedicated git servers`](#install-a-dedicated-git-server) to `ssh` remote locations using one command. It's recommended to install them on some dedicated devices on your LAN such as `Raspberry Pi` running `Raspberry Pi OS (aarch64 or armhf)`. Regular `Debian (amd64)` targets are also supported. Perhaps it works on some `Debian-derived` distros as well, but that hasn't been tested.
- Plug in some removable disks to your `git server` and it will find and share any `git repos` it finds to the rest of your LAN.
- Browse your plugged-in `git repos` with a familiar `GitWeb` UI.

---

## [Dependencies](#dependencies)

GitCid will try to install these for you automatically if they're missing from your system, but if it fails, you might need to install them yourself:

- curl
- rsync
- git
- docker
- docker-compose - Usually the version found in `pip` or `pip3` (python's package manager) is the one that works properly.
- yq ( [https://github.com/mikefarah/yq](https://github.com/mikefarah/yq) )

There are a few more dependencies needed depending on your OS, but they should be installed automatically in most cases. See the files in `.gc/.gc-deps` for full details.

---

## [Quickstart](#quickstart)

---

### [Download GitCid](#download-gitcid)

1. Make sure you've installed [`git`](https://git-scm.com) and
   [`curl`](https://man7.org/linux/man-pages/man1/curl.1.html) first,
   then run the following command:

   ```shell
   source <(curl -sL https://tinyurl.com/gitcid)
   ```

   When this command finishes, it will have created a new folder called `gitcid` in your current directory, and then it will bring you into this new folder.

2. (Optional) Or if you prefer, you can run this command instead:

   ```shell
   git clone https://gitlab.com/defcronyke/gitcid.git && cd gitcid && echo "" && .gc/init.sh -h
   ```

### [Create a new git remote with GitCid features](#create-a-new-git-remote-with-gitcid-features)

1. In the `gitcid` folder, run this command:

   ```shell
   .gc/new-remote.sh ~/repo1.git
   ```

   - It should output some details, and if successful, it will have created a new git remote repo at the path: `~/repo1.git`
   - It will tell you the proper `git clone` command that you can use to clone your new repo at the bottom of the output if everything worked properly.
   - If it didn't work properly for some reason, it will mention some errors which can help you figure out what went wrong.

2. You can use remote `ssh` paths for the new remote repo location also, instead of a local path, for example:

   ```shell
   .gc/new-remote.sh git1:~/repo1.git
   ```

3. An example `git clone` command to clone your git repo might look something like this:

   ```shell
   git clone git1:~/repo1.git && cd repo1
   ```

   It's just the regular way of cloning git repos.

4. When you make your new remote repo, you will also be given a command you can use to add `GitCid` features to your locally cloned repo that you cloned from the remote. Here's that same command in case you need it. Make sure you're inside your local repo when you run this command:

   ```shell
   source <(curl -sL https://tinyurl.com/gitcid) -e
   ```

   The above command will add GitCid to your git repo in a .gitignore'd folder called: `.gc/`

---

## [Usage Examples](#usage-examples)

---

### [Get Usage Help](#get-usage-help)

- Run this command from the top-level directory of the GitCid repo, for usage info:

  ```shell
  .gc/init.sh -h
  ```

### [Install GitCid into an existing git repo](#install-gitcid-into-an-existing-git-repo)

- Run this command from the top-level directory of your existing git repo that
  you'd like to install GitCid into (it works for both regular and bare repos):

  ```shell
  source <(curl -sL https://tinyurl.com/gitcid) -e
  ```

### [Make new git repositories](#make-new-git-repositories)

- NOTE: The remote targets need to have `rsync` installed.

- Run these `.gc/init.sh` commands from the top-level directory of the GitCid repo,
  to make new GitCid git repositories.

1. Make a new local git repo with the default name of "`repo`" in the current directory:

   ```shell
   .gc/init.sh
   ```

1. Make a new local git repo:

   ```shell
   .gc/init.sh ./local-repo
   ```

1. Make a new remote git repo at a target ssh server path:

   ```shell
   .gc/init.sh user@host:~/remote-repo
   ```

1. Make several new git repos at once, local and/or remote ones:

   ```shell
   .gc/init.sh local-repo1 user@host:~/remote-repo1 user@host:~/remote-repo2 ./local-repo2
   ```

1. Make several new bare git repos at once (suitable for using as git remotes), local and/or remote ones:

   ```shell
   .gc/init.sh -b user@host:~/remote-bare-repo1.git local-bare-repo1.git ./local-bare-repo2
   ```

---

## [Install a Dedicated Git Server](#install-a-dedicated-git-server)

---

Install a git server at a target ssh location, using tools from this project:

[https://gitlab.com/defcronyke/git-server](https://gitlab.com/defcronyke/git-server)

Currently supported target platforms:

- Debian Stable (amd64)
- Debian Testing (amd64)
- Raspberry Pi OS (armhf)
- Raspberry Pi OS (aarch64)

Platform support wishlist (Please feel free to test and contribute fix suggestions if you'd like to help with adding support for these):

- Arch Linux (amd64)

Maybe it works on other Debian or Debian-based platforms, but this hasn't been tested yet.

WARNING: USE AT YOUR OWN RISK! You should only run the commands in this section to install a dedicated git server onto a freshly installed Linux distro which is intended to be used only as a dedicated git server! This will install some dependencies automatically and do some system configurations that you might not prefer to have on devices that are being used for other purposes. USE AT YOUR OWN RISK! YOU HAVE BEEN WARNED!!

---

### [TLDR; Let's just install the git server](#tldr-lets-just-install-the-git-server)

- Install a `git server` to a remote `ssh` location (or two as in this example), by running the following command in a `bash` terminal:

  ```shell
  source <(curl -sL https://tinyurl.com/gitcid) && .gc/new-git-server.sh -o pi@git1 $USER@gitlab
  ```

  Usually it just works, and with the `-o` flag used above, it should auto-open a web page for each git server it finds on your network after the install is finished. For more info and other options, see the next section below.

- The example above will also install `gitcid`, which makes it easier to work with the git server. If you already have `gitcid` installed, you don't need to install it again, so in that case you can omit the first part of the above command, for example:

  ```shell
  .gc/new-git-server.sh -o pi@git1 $USER@gitlab
  ```

  Just make sure you're inside the `gitcid/` folder first (or any `gitcid`-enabled git repo), before trying to run any `gitcid` commands.

---

### [Git Server Install Instructions](#git-server-install-instructions)

1. Install GitCid:

   ```shell
   source <(curl -sL https://tinyurl.com/gitcid)
   ```

   If successful, you will now be inside the freshly downloaded `./gitcid/` folder. You need to be inside this folder for step 2.

2. Install new git server(s) onto dedicated device(s) at the given `ssh` target location(s):

   - Usage details:

   ```shell
   .gc/new-git-server.sh -h
   ```

   - Install or update some git servers, with a confirmation prompt before installing:

   ```shell
   .gc/new-git-server.sh git1 git2 gitlab
   ```

   - Install or update some git servers with a confirmation prompt. Open a web browser tab for each available GitWeb server page found on your network when finished:

   ```shell
   .gc/new-git-server.sh -o git1 git2 gitlab
   ```

   - Non-interactive automated version:

   ```shell
   .gc/new-git-server.sh -y git1 git2 gitlab
   ```

   - Non-interactive automated version, open web browser to GitWeb pages when finished:

   ```shell
   .gc/new-git-server.sh -yo git1 git2 gitlab
   ```

   - Non-interactive sequential install. In the examples above, installs are attempted first in parallel whenever possible. To override that behaviour and perform all installs sequentially one at a time, use this command instead:

   ```shell
   .gc/new-git-server.sh -s git1 git2 gitlab
   ```

   - Non-interactive sequential install, and open a web browser to GitWeb pages when finished:

   ```shell
   .gc/new-git-server.sh -so git1 git2 gitlab
   ```

   - Specify the ssh username to log in as during install on the targets. By default, the ssh config for each hostname is used from your `~/.ssh/config` file, but if you prefer, you can add a username in the command below for each target. You can do this for any of the various commands listed above, for example:

   ```shell
   .gc/new-git-server.sh -yo pi@git1 pi@git2 $USER@gitlab
   ```

   If everything worked as intended, your git server(s) are now ready to use. See the output in your terminal for more details. During parallel installs (the default behaviour unless using the `-s` flag variants), if non-interactive sudo support isn't configured on the target, the system will fall back to sequential install mode for any targets which need the sudo password typed manually. After typing the sudo password once successfully, a passwordless sudo configuration will be attempted on the target, so that any future interactions with that target can be fully-automated.

---

### [Git Server Usage Examples](#git-server-usage-examples)

Here's some examples of how to use your git server for some common git-related tasks. The following commands should be run from inside your `gitcid/` folder, or inside any `gitcid`-enabled git repo.

1. Create a new git remote repo on the git server, for example, a repo named `repo1.git` at the hostname `git1`:

   ```shell
   .gc/new-remote.sh git1:repo1
   ```

   Newly created remote repos will become available for use after a short delay, typically less than 1 minute. If you receive an error when trying to use a newly created remote repo, try again after 1 minute has passed since creating it and it should work.

2. Clone a local copy of your new repo from the server:

   ```shell
   git clone git1:~/git/repo1.git
   cd repo1
   ```

3. Commit some changes to your new repo, then push it to the origin remote on your git server:

   ```shell
   date | tee -a test1.txt
   git add .
   git commit -m "A test commit."
   git push
   ```

4. (Optional) Add `gitcid` to your local copy of your git repo if you'd like to use any `gitcid` commands while working inside your repo. Run the following command while inside your repo to install `gitcid` features:

   ```shell
   source <(curl -sL https://tinyurl.com/gitcid) -e
   ```

5. (Optional) With `gitcid` added to your repo from the previous step, you can commit and push more easily:

   ```shell
   .gc/commit-push.sh Commit message.
   ```

---
