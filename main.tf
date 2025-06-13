terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = ">= 0.4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }
}

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

# resource "github_repository" "flux_config" {
#   count       = var.create_github_repository ? 1 : 0
#   name        = var.github_repository_name
#   description = "Flux configuration repository"
#   visibility  = "private"
#   auto_init   = true
# }

# resource "github_repository_deploy_key" "flux" {
#   count      = var.create_github_repository ? 1 : 0
#   title      = "Flux Deploy Key"
#   repository = github_repository.flux_config[0].name
#   key        = tls_private_key.flux.public_key_openssh
#   read_only  = false
# }

resource "kind_cluster" "default" {
  name = var.cluster_name
  
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      
      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "flux" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
  git = {
    url = var.github_repository_url
    ssh = {
      username    = "git"
      private_key = tls_private_key.flux.private_key_pem
    }
  }
}

resource "flux_bootstrap_git" "this" {
  depends_on = [kind_cluster.default]
  
  path = "clusters/${var.cluster_name}"
  
  components_extra = [
    "image-reflector-controller"
  ]
}

resource "kubernetes_namespace" "kbot" {
  depends_on = [flux_bootstrap_git.this]
  
  metadata {
    name = var.app_namespace
  }
}

resource "kubernetes_manifest" "kbot_git_repository" {
  depends_on = [flux_bootstrap_git.this]
  
  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata = {
      name      = "kbot-source"
      namespace = "flux-system"
    }
    spec = {
      interval = "30s"
      ref = {
        branch = var.kbot_git_branch
      }
      url = var.kbot_repository_url
    }
  }
}

resource "kubernetes_manifest" "kbot_helm_release" {
  depends_on = [
    flux_bootstrap_git.this,
    kubernetes_namespace.kbot,
    kubernetes_manifest.kbot_git_repository
  ]
  
  manifest = {
    apiVersion = "helm.toolkit.fluxcd.io/v2beta1"
    kind       = "HelmRelease"
    metadata = {
      name      = "kbot"
      namespace = var.app_namespace
    }
    spec = {
      interval = "1m"
      chart = {
        spec = {
          chart = var.helm_chart_path
          sourceRef = {
            kind = "GitRepository"
            name = "kbot-source"
            namespace = "flux-system"
          }
          interval = "30s"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "kbot_image_repository" {
  count      = var.enable_image_monitoring ? 1 : 0
  depends_on = [flux_bootstrap_git.this]
  
  manifest = {
    apiVersion = "image.toolkit.fluxcd.io/v1beta2"
    kind       = "ImageRepository"
    metadata = {
      name      = "kbot-image"
      namespace = "flux-system"
    }
    spec = {
      image    = var.kbot_image_repository
      interval = "5m"
    }
  }
}