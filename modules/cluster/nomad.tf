# Installing or updating Nomad.

locals {
  nomad_ver = "1.3.1"
}

resource "null_resource" "install_nomad" {
  depends_on = [aws_instance.node, hcloud_server.node]

  for_each = local.provisioned_nodes

  connection {
    host        = each.value.ipv4
    user        = "core"
    private_key = file("~/Job/tmp.key")  # TODO: manage secret properly
  }

  # Install Nomad systemd service.
  provisioner "file" {
    source      = templatefile("${path.module}/nomad/nomad.service", {})
    destination = "/etc/systemd/system/nomad.service"
  }

  # Install Nomad server config.
  provisioner "file" {
    source      = templatefile("${path.module}/nomad/server.hcl", {})
    destination = "/etc/nomad/server.hcl"
  }

  # Install Nomad binary and start.
  provisioner "remote-exec" {
    inline = [
      "set -x -o errexit",
      "mkdir -p /tmp/nomad/",
      "curl -fL -o /tmp/nomad/nomad.zip https://releases.hashicorp.com/nomad/${local.nomad_ver}/nomad_${local.nomad_ver}_linux_amd64.zip",
      "unzip /tmp/nomad/nomad.zip -d /tmp/nomad/",
      "cp -f /tmp/nomad/nomad /usr/local/bin/",
      "rm -rf /tmp/nomad",
      "systemctl daemon-reload",
      "systemctl enable nomad.service",
      "systemctl restart nomad.service",
    ]
  }
}
