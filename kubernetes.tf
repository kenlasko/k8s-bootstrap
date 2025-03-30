terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "= 2.36.0"
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
  source          = "./modules/cilium"
  cilium_version  = "1.17.2"
  kube_env        = var.kube_env[terraform.workspace]
  kube_context    = "omni-${terraform.workspace}"
  kube_config     = var.kube_config
  manifests_dir   = "/home/ken/${var.kube_env[terraform.workspace]}/manifests/network/cilium"
}

module "sealed-secrets" {
  source                  = "./modules/sealed-secrets"
  sealed_secrets_version  = "2.5.8"
  kube_env                = var.kube_env[terraform.workspace]
  kube_context            = "omni-${terraform.workspace}"
  kube_config             = var.kube_config
  manifests_dir           = "/home/ken/${var.kube_env[terraform.workspace]}/manifests/system/sealed-secrets"
  cilium_status           = module.cilium.status   # Will only start when Cilium is ready
}

module "cert-manager" {
  source                  = "./modules/cert-manager"
  cert_manager_version    = "1.17.1"
  kube_env                = var.kube_env[terraform.workspace]
  kube_context            = "omni-${terraform.workspace}"
  kube_config             = var.kube_config
  manifests_dir           = "/home/ken/${var.kube_env[terraform.workspace]}/manifests/system/cert-manager"
  sealed_secrets_status   = module.sealed-secrets.status  # Will only start when Sealed Secrets is ready
}

module "argocd" {
  source                  = "./modules/argocd"
  argocd_version          = "7.8.15"
  kube_env                = var.kube_env[terraform.workspace]
  kube_context            = "omni-${terraform.workspace}"
  kube_config             = var.kube_config
  manifests_dir           = "/home/ken/${var.kube_env[terraform.workspace]}/manifests/argocd"
  sealed_secrets_status   = module.sealed-secrets.status  # Will only start when Sealed Secrets is ready
}