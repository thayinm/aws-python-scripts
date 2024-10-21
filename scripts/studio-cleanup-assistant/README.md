# Studio Cleanup

This tool is designed to help you remove the following resources from your Domain if you would like to delete said Domain:
- The ingress and egress security groups used by Studio for mounting EFS volumes.
- Mount Targets for the main EFS volume for the Domain.
- The EFS volume itself.

You will need the `AWSCLIv2` as well as `jq` installed for this script to function. You will also need to ensure that your credentials are properly set so that the tool may read & delete these resources.

## Why use this tool?
If the Domain was created without setting the [retention policy](https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_RetentionPolicy.html) (this can be done through something like [Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_domain#retention_policy-block)) then when you want to delete the Domain there will still exist the security groups & EFS filesystem. Needing to manually delete these is a pain so before deleting the Domain we can first run this script to go ahead and delete these resources and finally delete the Domain itself.