# GitCid

---

## Dependencies

GitCid will try to install these for you automatically if they're missing from your system, but if it fails, you might need to install them yourself:

- curl
- rsync
- git
- docker
- docker-compose - Usually the version found in `pip` or `pip3` (python's package manager) is the one that works properly.
- yq - [https://github.com/mikefarah/yq](https://github.com/mikefarah/yq)

There are a few more dependencies needed depending on your OS, but they should be installed automatically in most cases. See the files in `.gc/.gc-deps` for full details.

## Quickstart

### Download GitCid

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

### Create a new git remote with GitCid CI/CD features added to it

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

## Usage Examples

### Get Usage Help

- Run this command from the top-level directory of the GitCid repo, for usage info:

  ```shell
  .gc/init.sh -h
  ```

### Install GitCid into an existing git repository

- Run this command from the top-level directory of your existing git repo that
  you'd like to install GitCid into (it works for both regular and bare repos):

  ```shell
  source <(curl -sL https://tinyurl.com/gitcid) -e
  ```

### Make new git repositories

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
