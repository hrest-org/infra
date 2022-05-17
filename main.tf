provider "hcloud" {
  token = var.hcloud_token
}

module "cluster" {
  source = "./modules/cluster"

  cluster_name = "test"
  cluster_nodes = [{
    name       = "test.node"
    provider   = "hcloud"
    type       = "cx21"
    location   = "nbg1"
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOc1R31qal9hTojZJnKR0E1/eVVy+eoxm09OxMmBK0Og"
    labels     = {}
  }]
}
