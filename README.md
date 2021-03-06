# GitCid  
--------  
  
## Download this project  
  
1. Make sure you've installed git first.
2. Run the following command:
    ```shell
    git clone https://github.com/defcronyke/gitcid.git && cd gitcid
    ```
  
## Requisites  
  
### Linux  
  
1. Run this command once inside this git repo after cloning this project:
    ```shell
    .gc/deps.sh
    ```
  
### Other OS (Windows, macOS, other)  

* Not currently supported.
  
## Usage Examples  
  
### Make new bare git repos, suitable for hosting as git remotes

#### Use the "`.gc/init.sh`" script to do it, and always run it from the top-level directory of this project's git repo.

1. Run this command for usage info:
    ```shell
    .gc/init.sh -h
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
1. Make a new local bare git repo with the default name of `repo.git` in the current directory:
    ```shell
    .gc/init.sh
    ```
