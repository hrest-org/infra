locals {
  aws_nodes = {
    for n in var.cluster_nodes: n.name => n if n.provider == "aws"
  }
}

data "aws_ami" "fcos" {
  most_recent = true
  owners      = ["125523088429"]  # TODO: recheck

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

resource "aws_instance" "server" {
  for_each = local.aws_nodes

  ami           = data.aws_ami.fcos.image_id
  instance_type = each.value.type

  user_data     = data.ct_config.ignition[each.value.name].rendered

  tags = merge(tomap({ cluster_name = var.cluster_name }), each.value.labels)
}
