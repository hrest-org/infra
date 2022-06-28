terraform {
  # Requires `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` env vars to be set.
  backend "s3" {
    # NOTE: Amazon S3 bucket names must be unique globally (among all users).
    # https://docs.aws.amazon.com/AmazonS3/latest/userguide/BucketRestrictions.html#bucketnamingrules
    bucket = "tfstate-test-rnadflj43jn0jns5e"
    key    = "terraform.tfstate"
    region = "eu-central-1"

    # Required for state locking and consistency.
    # https://terraform.io/language/settings/backends/s3#dynamodb_table
    dynamodb_table = "tfstate-test-rnadflj43jn0jns5e"

    # Requires `AWS_SSE_CUSTOMER_KEY` env var to be set.
    encrypt = true
  }
}

# Requires `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` env vars to be set.
provider "aws" {
  region = "eu-central-1"
}

# Requires `HCLOUD_TOKEN` env var to be set.
provider "hcloud" {}

data "aws_region" "current" {}

module "cluster" {
  source = "./modules/cluster"

  cluster_name = "test"
  cluster_nodes = [
    {
      name       = "test.node"
      provider   = "hcloud"
      type       = "cx21"
      datacenter = "nbg1"
      region     = "german"
      labels = {}
    },
    {
      name       = "test2.node"
      provider   = "aws"
      type       = "t2.micro"
      datacenter = data.aws_region.current.name
      region     = "german"
      labels = {
        "vault/server" = true
      }
    },
  ]
}

output "cluster_nodes" {
  value = module.cluster.nodes
}
