# Dependencies of "cluster" module.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.14"
    }
    ct = {
      source  = "poseidon/ct"
      version = "~> 0.10.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.33"
    }
  }
}
