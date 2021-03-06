# GitCid  
--------  
  
## Download this project  
  
1. Make sure you've installed `git` first, then run the following command:
    ```shell
    git clone https://github.com/defcronyke/gitcid.git && cd gitcid && .gc/init.sh -h
    ```
1. Or if you prefer, you can run this command instead (you need to have `curl` and `git` installed first):
    ```shell
    source <(curl -sL https://tinyurl.com/gitcid)
    ```
  
## Usage Examples  

* Always run the GitCid commands from the top-level directory of this project's git repo.

### `.gc/init.sh` - Make new bare git repositories, suitable for hosting as git remotes

1. Run this command for usage info:
    ```shell
    .gc/init.sh -h
    ```
1. Make a new local bare git repo with the default name of "`repo.git`" in the current directory:
    ```shell
    .gc/init.sh
    ```
1. Make a new local bare git repo:
    ```shell
    .gc/init.sh ./local-repo.git
    ```
1. Make a new remote bare git repo at a target ssh server path:
    ```shell
    .gc/init.sh user@host:~/remote-repo.git
    ```
1. Make several new bare git repos at once, local and/or remote ones:
    ```shell
    .gc/init.sh local-repo1 user@host:~/remote-repo1 user@host:~/remote-repo2.git ./local-repo2.git
    ```
1. Make several new regular (non-bare) git repos at once, local and/or remote ones:
    ```shell
    GITCID_NEW_REPO_NOT_BARE="y" \
    .gc/init.sh ~/example-regular-repo1 example-regular-repo2.git
    ```
