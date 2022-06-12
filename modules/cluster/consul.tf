# Installing or updating Consul.

locals {
  consul_ver = "1.12.1"
}

resource "null_resource" "install_consul" {
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

  # Prepare Consul systemd service.
  provisioner "file" {
    content     = file("${path.module}/consul/consul.service")
    destination = "/tmp/consul.service"
  }

  # Prepare Consul config.
  provisioner "file" {
    content     = templatefile("${path.module}/consul/conf.hcl.tftpl", {
      node = each.value
    })
    destination = "/tmp/consul.conf.hcl"
  }

  # Install Consul binary and start Consul as systemd service.
  provisioner "remote-exec" {
    inline = [
      "set -x -o errexit",

      "sudo rm -rf /tmp/consul",
      "mkdir -p /tmp/consul/",

      "curl -fL -o /tmp/consul/consul.zip https://releases.hashicorp.com/consul/${local.consul_ver}/consul_${local.consul_ver}_linux_amd64.zip",
      "unzip /tmp/consul/consul.zip -d /tmp/consul/",
      "sudo cp -f /tmp/consul/consul /usr/local/bin/",

      "sudo mkdir -p /etc/consul/",
      "sudo cp -f /tmp/consul.conf.hcl /etc/consul/conf.hcl",

      "sudo cp -f /tmp/consul.service /etc/systemd/system/consul.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable consul.service",
      "sudo systemctl restart consul.service",

      "sudo rm -rf /tmp/consul /tmp/consul.*",
    ]
  }
}
