# GitCid

---

## Download this project

1. Make sure you've installed `git` first, then run the following command:
   ```shell
   git clone https://github.com/defcronyke/gitcid.git && cd gitcid && echo "" && .gc/init.sh -hv
   ```
1. Or if you prefer, you can run this command instead (you need to have `curl` and `git` installed first):
   ```shell
   source <(curl -sL https://tinyurl.com/gitcid) -v
   ```

## Usage Examples

### Make new git repositories:

- Always run these GitCid commands from the top-level directory of this project's git repo.

1. Run this command for usage info:
   ```shell
   .gc/init.sh -h
   ```
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
   .gc/init.sh -b ~/example-regular-repo1 example-regular-repo2.git
   ```

### Install GitCid into an existing git repository:

1. Install GitCid into a regular git repo:

```shell
source <(curl -sL https://tinyurl.com/gitcid) -e
```

2. Install GitCid into a bare git repo:

```shell
source <(curl -sL https://tinyurl.com/gitcid) -eb
```
