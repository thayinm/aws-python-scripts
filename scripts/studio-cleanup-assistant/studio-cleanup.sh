#!/usr/bin/env bash
set -o pipefail

cat << "EOF"

  ____                   __  __       _             
 / ___|  __ _  __ _  ___|  \/  | __ _| | _____ _ __ 
 \___ \ / _` |/ _` |/ _ \ |\/| |/ _` | |/ / _ \ '__|
  ___) | (_| | (_| |  __/ |  | | (_| |   <  __/ |   
 |____/ \__,_|\__, |\___|_|  |_|\__,_|_|\_\___|_|   
              |___/                                 

 Cleanup tool for Amazon SageMaker Studio.
 v0.1.0
EOF

echo "Looking for Domains"
declare -a DOMAINS=($(aws sagemaker list-domains | jq -r '.Domains.[].DomainId'))
if [[ -z "${DOMAINS[@]}" ]]; then
    echo "Could not find any Domains. Please check your AWSCLI settings."
    exit 1
fi

echo "Found the following Domains:"
for DOMAIN in "${DOMAINS[@]}"; do
  echo " - ${DOMAIN}"
done
echo ""
read -p "Enter your Domain ID: " DOMAIN_ID

while true; do
  if [[ ! " ${DOMAINS[*]} " =~ [[:space:]]${DOMAIN_ID}[[:space:]] ]]; then
    echo "Not a Valid Domain" 
    read -p "Enter a valid Domain ID: " DOMAIN_ID
  else
    read -p "Are you sure? THIS ACTION CANNOT BE UNDONE! (y/N) " yn
    if [[ $yn =~ ^[Yy]$ ]]; then
        echo "Getting info about Domain."
        EFS_ID=$(aws sagemaker describe-domain --domain-id $DOMAIN_ID | jq -r '.HomeEfsFileSystemId')
        break
    else
        echo "No action taken. Exiting."
        exit 0
    fi
  fi
done

# Deleting EFS filesystem associated with Domain.

echo "Deleting the Domain's EFS mount targets."
for mount_target_id in $(aws efs describe-mount-targets --file-system-id $EFS_ID | jq -r '.MountTargets[] | .MountTargetId'); do
  aws efs delete-mount-target --mount-target-id $mount_target_id
done
sleep 5
echo "Mount targets deleted. Deleting EFS."
aws efs delete-file-system --file-system-id $EFS_ID

#Delete Security Groups
echo "Deleting SG Rule for TCP 2049 on Inbound & Outbound"

SG_IN=$(aws ec2 describe-security-groups --filters \
  Name=group-name,Values="security-group-for-inbound-nfs-${DOMAIN_ID}" \
  | jq '.SecurityGroups.[].GroupId')

SG_OUT=$(aws ec2 describe-security-groups --filters \
  Name=group-name,Values="security-group-for-outbound-nfs-${DOMAIN_ID}" \
  | jq '.SecurityGroups.[].GroupId')

echo "Deleting Ingress SG for ${DOMAIN_ID}"
aws ec2 revoke-security-group-ingress --group-id ${SG_IN//\"} \
  --protocol tcp --port 2049 --source-group ${SG_OUT//\"}

echo "Deleting Egress SG for ${DOMAIN_ID}"
aws ec2 revoke-security-group-egress --group-id ${SG_OUT//\"} \
  --protocol tcp --port 2049 --source-group ${SG_IN//\"}

echo "Deleting inbound & outbound SG's"
sleep 5
aws ec2 delete-security-group --group-id ${SG_IN//\"}
aws ec2 delete-security-group --group-id ${SG_OUT//\"}

echo "COMPLETE"