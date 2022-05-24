locals {
  all_nodes = { for n in var.cluster_nodes: n.name => n }

  provisioned_nodes = {
    for n in var.cluster_nodes: n.name => merge(n, {
      id = try(aws_instance.node[n.name].id,
               hcloud_server.node[n.name].id)
      ipv4 = try(aws_instance.node[n.name].public_ip,
                 hcloud_server.node[n.name].ipv4_address)
    })
  }
}
