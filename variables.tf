variable "aws_access_key" {
  type        = string
  sensitive   = true
  description = "AWS access key"
}
variable "aws_secret_key" {
  type        = string
  sensitive   = true
  description = "AWS secret access key"
}

variable "hcloud_token" {
  type        = string
  sensitive   = true
  description = "Hetzner Cloud API token"
}
