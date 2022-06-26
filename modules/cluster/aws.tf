# Provisioning of AWS cluster nodes with Fedora CoreOS installed.

locals {
  aws_nodes = {
    for n in var.cluster_nodes: n.name => n if n.provider == "aws"
  }
}

data "aws_ami" "fcos" {
  most_recent = true
  owners      = ["125523088429"]
  # https://getfedora.org/coreos/download?tab=cloud_launchable&stream=stable

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "description"
    values = ["Fedora CoreOS stable *"]
  }
}

resource "aws_instance" "node" {
  for_each = local.aws_nodes

  ami           = data.aws_ami.fcos.image_id
  instance_type = each.value.type

  user_data     = data.ct_config.ignition[each.value.name].rendered

  security_groups = [aws_security_group.firewall[0].name]

  tags = merge(tomap({
    Name         = each.value.name
    cluster_name = var.cluster_name
    node_name    = each.value.name
  }), each.value.labels)

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

resource "aws_security_group" "firewall" {
  count = length(local.aws_nodes) > 0 ? 1 : 0

  name = "${var.cluster_name}.firewall"
  description = "Firewall rules for ${var.cluster_name} cluster"

  ingress {
    description = "SSH port"

    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    cluster_name = var.cluster_name
  }
}
