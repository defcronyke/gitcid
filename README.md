# GitCid

---

## Quickstart / Demonstration

```shell
git init repo1 && cd repo1 && source <(curl -sL https://tinyurl.com/gitcid) -e; echo "test" | tee test.txt && git add . && git commit -m "Initial commit" && .gc/init.sh -b ../repo1; git remote add origin ../repo1.git/ && git push -u origin master && .gc/run.sh -v; .gc/init.sh -h; git log; git remote -v
```

---

## Download GitCid

1. Make sure you've installed [`git`](https://git-scm.com) and
   [`curl`](https://man7.org/linux/man-pages/man1/curl.1.html) first,
   then run the following command:

   ```shell
   source <(curl -sL https://tinyurl.com/gitcid)
   ```

1. (Optional) Or if you prefer, you can run this command instead:

   ```shell
   git clone https://gitlab.com/defcronyke/gitcid.git && cd gitcid && echo "" && .gc/init.sh -h
   ```

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
