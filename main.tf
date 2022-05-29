provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "aws_region" "current" {}

provider "hcloud" {
  token = var.hcloud_token
}

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
    },/*
    {
      name       = "test2.node"
      provider   = "aws"
      type       = "t2.micro"
      location   = data.aws_region.current.name
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOc1R31qal9hTojZJnKR0E1/eVVy+eoxm09OxMmBK0Og"
      labels     = {}
    },*/
  ]
}

output "cluster_nodes" {
  value = module.cluster.nodes
}
