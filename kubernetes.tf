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

module "external-secrets" {
  source                = "./modules/external-secrets"
  software_version      = "0.17.0"
  kube_env              = var.kube_env[terraform.workspace]
  kube_context          = "omni-${terraform.workspace}"
  kube_config           = var.kube_config
  manifests_dir         = "/home/ken/${var.kube_env[terraform.workspace]}/manifests/system/external-secrets"
  cilium_status         = module.cilium.status   # Will only start when Cilium is ready
}

module "cert-manager" {
  source                  = "./modules/cert-manager"
  software_version        = "v1.17.2"
  kube_env                = var.kube_env[terraform.workspace]
  kube_context            = "omni-${terraform.workspace}"
  kube_config             = var.kube_config
  manifests_dir           = "/home/ken/${var.kube_env[terraform.workspace]}/manifests/system/cert-manager"
  external_secrets_status = module.external-secrets.status  # Will only start when External Secrets Operator is ready
}

module "redis" {
  count                 = terraform.workspace == "cloud" ? 0 : 1
  source                = "./modules/redis"
  software_version      = "8.0.1"
  kube_env              = var.kube_env[terraform.workspace]
  kube_context          = "omni-${terraform.workspace}"
  kube_config           = var.kube_config
  manifests_dir         = "/home/ken/${var.kube_env[terraform.workspace]}/manifests/database/redis"
  external_secrets_status = module.external-secrets.status  # Will only start when External Secrets Operator is ready
}

module "argocd" {
  source                = "./modules/argocd"
  software_version      = "8.0.12"
  kube_env              = var.kube_env[terraform.workspace]
  kube_context          = "omni-${terraform.workspace}"
  kube_config           = var.kube_config
  manifests_dir         = "/home/ken/${var.kube_env[terraform.workspace]}/argocd"
  external_secrets_status = module.external-secrets.status  # Will only start when External Secrets Operator is ready
}