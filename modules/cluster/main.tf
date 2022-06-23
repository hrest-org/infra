locals {
  all_nodes = { for n in var.cluster_nodes: n.name => n }
}

resource "tls_private_key" "node_ssh" {
  for_each = local.all_nodes

  algorithm = "ED25519"
}
