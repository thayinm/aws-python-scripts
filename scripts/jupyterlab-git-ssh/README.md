# Description

This script is intended to grab your private key from AWS Secrets Manager and save it in `.ssh`. If you do not have a key then you will need to generate one first.

## Generate the SSH Key Pair

- Run the `ssh-keygen` command in a Studio JupyterLab or Code Editor Space.
  ```shell
  mkdir -p ~/.ssh
  cd ~/.ssh && ssh-keygen -o -t rsa -C "ssh@github.com"
  ```
- Create the Secret with the AWS CLI. Note you will need the necessary IAM permissions to do so.
  ```shell
  aws secretsmanager create-secret --name GithubSSHKey --secret-string "$(cat ~/.ssh/git_key)"
  ```
- Copy the PUBLIC KEY `git_key.pub` to your Git Repo of choice. If using GitHub then you need to click on your Profile, navigate to Settings --> Access --> SSH & GPG keys and paste your PUBLIC KEY here.
- Add the `on-start.sh` script to a Lifecycle Config in the SageMaker console and attach to your Domain.
- You can now create a new JupyterLab or Code Editor Space and set the LCC to this newly created one.