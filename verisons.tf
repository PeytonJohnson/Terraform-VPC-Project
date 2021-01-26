terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    ec2 = {
      # TF-UPGRADE-TODO
      #
      # No source detected for this provider. You must add a source address
      # in the following format:
      #
      # source = "your-registry.example.com/organization/ec2"
      #
      # For more information, see the provider source documentation:
      #
      # https://www.terraform.io/docs/configuration/providers.html#provider-source
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.13"
}
