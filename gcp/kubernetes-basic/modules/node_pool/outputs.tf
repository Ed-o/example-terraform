output "node_pool_id" {
  description = "The ID of the node pool"
  value       = google_container_node_pool.primary_nodes.id
}

output "node_pool_name" {
  description = "The name of the node pool"
  value       = google_container_node_pool.primary_nodes.name
}

output "node_count" {
  description = "The number of nodes in the node pool"
  value       = google_container_node_pool.primary_nodes.node_count
}
