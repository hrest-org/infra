locals {
  all_nodes = { for n in var.cluster_nodes: n.name => n }
}
