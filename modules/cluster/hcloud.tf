locals {
  hcloud_nodes = {
    for n in var.cluster_nodes: n.name => n if n.provider == "hcloud"
  }
}

resource "tls_private_key" "hcloud_bootstrap" {
  count = length(local.hcloud_nodes) > 0 ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "hcloud_ssh_key" "bootstrap" {
  count = length(local.hcloud_nodes) > 0 ? 1 : 0

  name       = "${var.cluster_name}.bootstrap.unsecure"
  public_key = tls_private_key.hcloud_bootstrap[0].public_key_openssh

  labels = {
    cluster_name = var.cluster_name
  }
}

resource "hcloud_server" "node" {
  for_each = local.hcloud_nodes

  name        = each.value.name
  server_type = each.value.type
  location    = each.value.location

  # There is no prepared FCOS image for Hetzner Cloud,
  # that's why we choose whatever image and install FCOS in rescue mode.
  rescue    = "linux64"
  image     = "debian-11"  # ignored, but required by `hcloud_server` resource
  keep_disk = "true"

  ssh_keys = [hcloud_ssh_key.bootstrap[0].id]

  labels = merge(tomap({
    cluster_name = var.cluster_name
    node_name    = each.value.name
  }), each.value.labels)

  connection {
    host        = hcloud_server.node[each.value.name].ipv4_address
    timeout     = "5m"
    private_key = tls_private_key.hcloud_bootstrap[0].private_key_pem
  }

  provisioner "file" {
    when = create

    content     = data.ct_config.ignition[each.value.name].rendered
    destination = "/root/ignition.json"
  }

  provisioner "remote-exec" {
    when = create

    inline = [
      "set -x -o errexit",
      "update-alternatives --set iptables /usr/sbin/iptables-legacy",
      "update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy",
      "apt-get -y update",
      "apt-get -y install podman",
      "apt-get -y clean",
      "podman run --privileged --rm -v /dev:/dev -v /run/udev:/run/udev -v /root:/data -w /data quay.io/coreos/coreos-installer:release install /dev/sda -p qemu -i ignition.json",
      "sync",  # force a sync, otherwise install sometimes fails
      "shutdown -r +1",
    ]
  }
}
