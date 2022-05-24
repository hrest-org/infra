# Output values of "cluster" module.

output "nodes" {
  value       = local.provisioned_nodes
  description = "All nodes of the cluster"
}
