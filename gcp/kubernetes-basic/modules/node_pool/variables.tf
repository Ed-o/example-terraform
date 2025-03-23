variable "project_id" {
  description = "The project ID to host the cluster in"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}

variable "location" {
  description = "The region to host the cluster in"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "The machine type for the nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "The disk size for the nodes in GB"
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "The disk type for the nodes"
  type        = string
  default     = "pd-standard"
}

variable "preemptible" {
  description = "Whether nodes are preemptible or not"
  type        = bool
  default     = false
}

variable "service_account" {
  description = "The service account to run nodes as"
  type        = string
  default     = null
}

variable "node_labels" {
  description = "The Kubernetes labels to apply to the nodes"
  type        = map(string)
  default     = {}
}

variable "node_tags" {
  description = "The network tags to apply to the nodes"
  type        = list(string)
  default     = []
}

variable "enable_autoscaling" {
  description = "Whether to enable autoscaling for the node pool"
  type        = bool
  default     = false
}

variable "min_node_count" {
  description = "Minimum number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "auto_upgrade" {
  description = "Whether to enable auto-upgrade for the node pool"
  type        = bool
  default     = true
}

variable "max_surge" {
  description = "The maximum number of nodes that can be added to the node pool during an upgrade"
  type        = number
  default     = 1
}

variable "max_unavailable" {
  description = "The maximum number of nodes that can be unavailable during an upgrade"
  type        = number
  default     = 0
}
