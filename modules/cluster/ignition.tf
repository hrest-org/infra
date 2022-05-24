# Butane/Ignition config preparing for Fedora CoreOS provisioning.
# See details: https://coreos.github.io/butane

# TODO: https://github.com/hashicorp/terraform-provider-cloudinit

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
    public_key = each.value.public_key
  }
}
