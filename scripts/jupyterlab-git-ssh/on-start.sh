#!/usr/bin/env bash
set -eu -o pipefail

KEYFILE=/home/sagemaker-user/.ssh/git_key.pem
REPO=git@github.com:<ORG>/<REPO>.git
OUT_LOC=/home/sagemaker-user/<REPO_NAME>

# Check if jq is installed
if [[ $(which jq) ]]; then
    echo "jq is installed"
else
    echo "Installing jq"
    sudo apt install -y jq
fi

# setup .ssh and grab private key from AWS Secrets Manager
mkdir -p /home/sagemaker-user/.ssh
if [ -f $KEYFILE ]; then
    echo "KEYFILE exists."
else
    aws secretsmanager get-secret-value --secret-id GithubSSHKey | jq -r '.SecretString' > $KEYFILE
    chmod 400 $KEYFILE
fi

# Clone into repo
if [ -d $OUT_LOC ]; then
    echo "Repository exists"
else
    sudo -i -u sagemaker-user bash << EOF
    git clone -c "core.sshCommand=ssh -o StrictHostKeyChecking=no -i ${KEYFILE}" $REPO $OUT_LOC
    
    # Make sure that the ssh command persists for the desired repo.
    cd $OUT_LOC
    git config core.sshCommand "ssh -o StrictHostKeyChecking=no -i ${KEYFILE}"
EOF
fi

set +u
source /home/sagemaker-user/.bashrc
if [[ -z ${GIT_SSH_COMMAND} ]]; then
    echo "Setting GIT_SSH_COMMAND"
    GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -i ${KEYFILE}"
    echo "export GIT_SSH_COMMAND=\"${GIT_SSH_COMMAND}\"" | tee -a /home/sagemaker-user/.bashrc >/dev/null
fi