variable "cluster_name" {
  description = "Name of this cluster"
}

variable "cluster_nodes" {
  type = list(object({
    name       = string
    provider   = string
    type       = string
    location   = string
    public_key = string
    labels     = map(string)
  }))
  description = "Nodes of this cluster and their settings"
}
