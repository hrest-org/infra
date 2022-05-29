# Butane/Ignition config preparing for Fedora CoreOS provisioning.
# See details: https://coreos.github.io/butane

# TODO: Try out this: https://github.com/hashicorp/terraform-provider-cloudinit
data "ct_config" "ignition" {
  for_each = local.all_nodes

  content = templatefile("${path.module}/fcos/butane.yaml", {
    hostname   = each.value.name
    public_key = each.value.public_key
  })

  pretty_print = false
  strict       = true
}

# TODO: Replace with `extensions:` in `fcc.yaml` once 1.5 FCOS Butane is
#       released.
resource "null_resource" "rpm_packages" {
  depends_on = [aws_instance.node, hcloud_server.node]

  for_each = local.provisioned_nodes

  connection {
    host        = each.value.ipv4
    user        = "core"
    private_key = file("~/Job/tmp.key")  # TODO: manage secret properly
    timeout     = "5m"
  }

  # Required for installing software (like Nomad, Consul, etc.) not available
  # in tarballs to download.
  provisioner "remote-exec" {
    inline = [
      "set -x -o errexit",
      "sudo rpm-ostree install --idempotent zip",
      "sudo shutdown -r +1",  # required due to layering of `rpm-ostree`
    ]
  }
}
