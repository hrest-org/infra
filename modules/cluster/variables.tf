# Input variables of "cluster" module.

variable "cluster_name" {
  description = "Name of this cluster"
}

variable "cluster_nodes" {
  type = list(object({
    name     = string
    provider = string
    type     = string
    location = string
    labels   = map(string)
  }))
  description = "Nodes of this cluster and their settings"
}
