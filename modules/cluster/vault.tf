# Installing or updating Vault.

locals {
  vault_ver = "1.11.0"
  vault_nodes = {
    for n in local.provisioned_nodes: n.name => n
      if try(n.labels["vault/server"], false)
  }
}

resource "null_resource" "install_vault" {
  depends_on = [
    aws_instance.node,
    hcloud_server.node,
    null_resource.rpm_packages,
  ]

  for_each = local.vault_nodes

  connection {
    host        = each.value.ipv4
    user        = "core"
    private_key = tls_private_key.node_ssh[each.value.name].private_key_pem
    timeout     = "5m"
  }

  # Prepare Vault systemd service.
  provisioner "file" {
    content     = file("${path.module}/vault/systemd.service")
    destination = "/tmp/vault.service"
  }

  # Prepare Vault TLS assets.
  provisioner "file" {
    content     = tls_locally_signed_cert.vault[each.value.name].cert_pem
    destination = "/tmp/vault.crt"
  }
  provisioner "file" {
    content     = tls_private_key.vault[each.value.name].private_key_pem
    destination = "/tmp/vault.crt"
  }
  provisioner "file" {
    content     = tls_self_signed_cert.vault_ca[0].cert_pem
    destination = "/tmp/vault.ca.crt"
  }

  # Prepare Vault config.
  provisioner "file" {
    content     = templatefile("${path.module}/vault/conf.hcl.tftpl", {
      node           = each.value
      leaders = {
        for n in local.vault_nodes: n.name => n.ipv4
      }
      unseal_key_arn = aws_kms_key.vault_unseal[0].arn
      aws_access_key = aws_iam_access_key.vault_unseal[0].id
      aws_secret_key = aws_iam_access_key.vault_unseal[0].secret
    })
    destination = "/tmp/vault.conf.hcl"
  }

  # Install Vault binary and start Vault as systemd service.
  provisioner "remote-exec" {
    inline = [
      "set -x -o errexit",

      "sudo rm -rf /tmp/vault /tmp/vault.*",
      "mkdir -p /tmp/vault/",

      "curl -fL -o /tmp/vault/vault.zip https://releases.hashicorp.com/vault/${local.consul_ver}/vault_${local.consul_ver}_linux_amd64.zip",
      "unzip /tmp/vault/vault.zip -d /tmp/vault/",
      "sudo cp -f /tmp/vault/vault /usr/local/bin/",

      "sudo mkdir -p /etc/vault/",
      "sudo cp -f /tmp/vault.conf.hcl /etc/vault/conf.hcl",
      "sudo cp -f /tmp/vault.ca.crt /etc/vault/ca.crt",
      "sudo cp -f /tmp/vault.crt /etc/vault/tls.crt",
      "sudo cp -f /tmp/vault.key /etc/vault/tls.key",
      "sudo chmod 400 /etc/vault/tls.key",

      "sudo cp -f /tmp/vault.service /etc/systemd/system/vault.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable vault.service",
      "sudo systemctl restart vault.service",

      "sudo rm -rf /tmp/vault /tmp/vault.*",
    ]
  }
}

resource "aws_kms_key" "vault_unseal" {
  count = length(local.vault_nodes) > 0 ? 1 : 0

  description = "KMS key for auto-unsealing Vault"

  enable_key_rotation = true

  tags = {
    Name         = "vault_unseal"
    cluster_name = var.cluster_name
  }
}

resource "aws_iam_user" "vault_unseal" {
  count = length(local.vault_nodes) > 0 ? 1 : 0

  name = "vault_unseal"
  path = "/cluster/${var.cluster_name}/"

  force_destroy = true

  tags = {
    Name         = "vault_unseal"
    cluster_name = var.cluster_name
  }
}

resource "aws_iam_user_policy" "vault_unseal" {
  count = length(local.vault_nodes) > 0 ? 1 : 0

  name = "vault_unseal"
  user = aws_iam_user.vault_unseal[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:*",      # TODO: Tune to allow exact only.
        ]
        Effect   = "Allow"
        Resource = "*"  # TODO: Tune to allow exact only.
      }
    ]
  })
}

resource "aws_iam_access_key" "vault_unseal" {
  count = length(local.vault_nodes) > 0 ? 1 : 0

  user = aws_iam_user.vault_unseal[0].name
}

resource "tls_private_key" "vault_ca" {
  count = length(local.vault_nodes) > 0 ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "vault_ca" {
  count = length(local.vault_nodes) > 0 ? 1 : 0

  private_key_pem   = tls_private_key.vault_ca[0].private_key_pem
  is_ca_certificate = true

  validity_period_hours = 8640       # 360 days
  early_renewal_hours   = 8640 - 30  # renew month before expiration

  subject {
    common_name = "vault-ca"
  }

  allowed_uses = [
    "cert_signing",
  ]
}

resource "tls_private_key" "vault" {
  for_each = local.vault_nodes

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "vault" {
  for_each = local.vault_nodes

  private_key_pem = tls_private_key.vault[each.value.name].private_key_pem

  subject {
    common_name = each.value.name
  }

  dns_names = [
    each.value.name,
  ]
  ip_addresses = [
    each.value.ipv4,
  ]
}

resource "tls_locally_signed_cert" "vault" {
  for_each = local.vault_nodes

  cert_request_pem   = tls_cert_request.vault[each.value.name].cert_request_pem
  ca_private_key_pem = tls_private_key.vault_ca[0].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.vault_ca[0].cert_pem

  validity_period_hours = 8640       # 360 days
  early_renewal_hours   = 8640 - 30  # renew month before expiration

  allowed_uses = [
    "client_auth",
    "data_encipherment",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}
