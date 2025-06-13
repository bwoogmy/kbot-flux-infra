output "cluster_name" {
  description = "Name of the created Kind cluster"
  value       = kind_cluster.default.name
}

output "kubeconfig_context" {
  description = "Kubeconfig context for the cluster"
  value       = "kind-${kind_cluster.default.name}"
}

output "flux_public_key" {
  description = "Flux public key for GitHub deploy key"
  value       = tls_private_key.flux.public_key_openssh
}

output "github_repository_url" {
  description = "GitHub repository URL"
  value       = var.github_repository_url
}

output "flux_bootstrap_path" {
  description = "Path where Flux configuration is stored"
  value       = "clusters/${var.cluster_name}"
}

output "kubectl_commands" {
  description = "Useful kubectl commands"
  value = {
    "switch_context" = "kubectl config use-context kind-${kind_cluster.default.name}"
    "get_flux_pods"  = "kubectl get pods -n flux-system"
    "get_kbot_pods"  = "kubectl get pods -n ${var.app_namespace}"
    "flux_status"    = "flux get all"
  }
}
