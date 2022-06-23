data "ct_config" "ignition" {
  for_each = local.all_nodes

  content      = data.template_file.fcc[each.value.name].rendered
  pretty_print = false
  strict       = true
}

data "template_file" "fcc" {
  for_each = local.all_nodes

  template = file("${path.module}/fcc.yaml")
  vars = {
    hostname   = each.value.name
    public_key = tls_private_key.node_ssh[each.value.name].public_key_openssh
  }
}
