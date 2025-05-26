terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.37.1"
    }
    helm = {
      source = "hashicorp/helm"
      version = "= 2.17.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}

variable "kube_config" {
  type = string
  default = "/home/ken/.kube/config"
}

variable "kube_env" {
  type = map(string)
  default = {
    home  = "k8s"
    cloud = "k8s-cloud"
    lab   = "k8s-lab"
  }
}

provider "kubernetes" {
  config_path    = var.kube_config
  config_context = "omni-${terraform.workspace}"
}

provider "helm" {
  kubernetes {
    config_path = var.kube_config
    config_context = "omni-${terraform.workspace}"
  }
}

provider "kubectl" {
  config_path    = var.kube_config
  config_context = "omni-${terraform.workspace}"
}

module "cilium" {
  source                = "./modules/cilium"
  software_version      = "1.17.4"
  kube_env              = var.kube_env[terraform.workspace]
  kube_context          = "omni-${terraform.workspace}"
  kube_config           = var.kube_config
  manifests_dir         = "/home/ken/${var.kube_env[terraform.workspace]}/manifests/network/cilium"
}

module "sealed-secrets" {
  source                = "./modules/sealed-secrets"
  software_version      = "2.5.12"
  kube_env              = var.kube_env[terraform.workspace]
  kube_context          = "omni-${terraform.workspace}"
  kube_config           = var.kube_config
  manifests_dir         = "/home/ken/${var.kube_env[terraform.workspace]}/manifests/system/sealed-secrets"
  cilium_status         = module.cilium.status   # Will only start when Cilium is ready
}

module "cert-manager" {
  source                = "./modules/cert-manager"
  software_version      = "v1.17.2"
  kube_env              = var.kube_env[terraform.workspace]
  kube_context          = "omni-${terraform.workspace}"
  kube_config           = var.kube_config
  manifests_dir         = "/home/ken/${var.kube_env[terraform.workspace]}/manifests/system/cert-manager"
  sealed_secrets_status = module.sealed-secrets.status  # Will only start when Sealed Secrets is ready
}

module "redis" {
  count                 = terraform.workspace == "cloud" ? 0 : 1
  source                = "./modules/redis"
  software_version      = "8.0.1"
  kube_env              = var.kube_env[terraform.workspace]
  kube_context          = "omni-${terraform.workspace}"
  kube_config           = var.kube_config
  manifests_dir         = "/home/ken/${var.kube_env[terraform.workspace]}/manifests/database/redis"
  sealed_secrets_status = module.sealed-secrets.status  # Will only start when Sealed Secrets is ready
}

module "argocd" {
  source                = "./modules/argocd"
  software_version      = "8.0.10"
  kube_env              = var.kube_env[terraform.workspace]
  kube_context          = "omni-${terraform.workspace}"
  kube_config           = var.kube_config
  manifests_dir         = "/home/ken/${var.kube_env[terraform.workspace]}/argocd"
  sealed_secrets_status = module.sealed-secrets.status  # Will only start when Sealed Secrets is ready
}