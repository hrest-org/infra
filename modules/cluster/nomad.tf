# Installing or updating Nomad.

locals {
  nomad_ver = "1.3.1"
}

resource "null_resource" "install_nomad" {
  depends_on = [
    aws_instance.node,
    hcloud_server.node,
    null_resource.rpm_packages,
  ]

  for_each = local.provisioned_nodes

  connection {
    host        = each.value.ipv4
    user        = "core"
    private_key = file("~/Job/tmp.key")  # TODO: manage secret properly
    timeout     = "5m"
  }

  # Prepare Nomad systemd service.
  provisioner "file" {
    content     = templatefile("${path.module}/nomad/nomad.service", {})
    destination = "/tmp/nomad.service"
  }

  # Prepare Nomad config.
  provisioner "file" {
    content     = templatefile("${path.module}/nomad/conf.hcl", {})
    destination = "/tmp/nomad.conf.hcl"
  }

  # Install Nomad binary and start Nomad as systemd service.
  provisioner "remote-exec" {
    inline = [
      "set -x -o errexit",

      "sudo rm -rf /tmp/nomad",
      "mkdir -p /tmp/nomad/",

      "curl -fL -o /tmp/nomad/nomad.zip https://releases.hashicorp.com/nomad/${local.nomad_ver}/nomad_${local.nomad_ver}_linux_amd64.zip",
      "unzip /tmp/nomad/nomad.zip -d /tmp/nomad/",
      "sudo cp -f /tmp/nomad/nomad /usr/local/bin/",

      "sudo mkdir -p /etc/nomad/",
      "sudo cp -f /tmp/nomad.conf.hcl /etc/nomad/conf.hcl",

      "sudo cp -f /tmp/nomad.service /etc/systemd/system/nomad.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable nomad.service",
      "sudo systemctl restart nomad.service",

      "sudo rm -rf /tmp/nomad /tmp/nomad.*",
    ]
  }
}
