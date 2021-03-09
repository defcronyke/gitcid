# GitCid

---

## Download GitCid

1. Make sure you've installed [`git`](https://git-scm.com) first, then run the following command:
   ```shell
   git clone https://gitlab.com/defcronyke/gitcid.git && cd gitcid && echo "" && .gc/init.sh -h
   ```
1. Or if you prefer, you can run this command instead (you need to have `curl` and `git` installed first):
   ```shell
   source <(curl -sL https://tinyurl.com/gitcid)
   ```

## Usage Examples

### Get Usage Help

- Run this command from the top-level directory of the GitCid repo, for usage info:
  ```shell
  .gc/init.sh -h
  ```

### Install GitCid into an existing git repository:

1. Run this command from the top-level directory of your existing git repo that
   you'd like to install GitCid into (it works for both regular and bare repos):
   ```shell
   source <(curl -sL https://tinyurl.com/gitcid) -e
   ```

### Make new git repositories:

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
