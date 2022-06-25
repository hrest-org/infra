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
      location   = "nbg1"
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOc1R31qal9hTojZJnKR0E1/eVVy+eoxm09OxMmBK0Og"
      labels     = {}
    },
    {
      name       = "test2.node"
      provider   = "aws"
      type       = "t2.micro"
      location   = data.aws_region.current.name
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOc1R31qal9hTojZJnKR0E1/eVVy+eoxm09OxMmBK0Og"
      labels     = {}
    },
  ]
}

output "cluster_nodes" {
  value = module.cluster.nodes
}
