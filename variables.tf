variable "cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "flux-demo"
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "github_repository_url" {
  description = "GitHub repository URL for Flux configuration"
  type        = string
}

variable "github_repository_name" {
  description = "GitHub repository name for Flux configuration"
  type        = string
  default     = "flux-config"
}

variable "create_github_repository" {
  description = "Whether to create GitHub repository"
  type        = bool
  default     = false
}

variable "git_branch" {
  description = "Git branch to use"
  type        = string
  default     = "main"
}

variable "app_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "kbot"
}

variable "kbot_repository_url" {
  description = "GitHub repository URL for kbot application"
  type        = string
}

variable "kbot_image_repository" {
  description = "Container image repository for kbot"
  type        = string
}

variable "helm_chart_path" {
  description = "Path to Helm chart in repository"
  type        = string
  default     = "helm"
}

variable "kbot_git_branch" {
  description = "Git branch to track for kbot application"
  type        = string
  default     = "develop"
}

variable "enable_image_monitoring" {
  description = "Enable image monitoring (optional, for logging purposes)"
  type        = bool
  default     = false
}
