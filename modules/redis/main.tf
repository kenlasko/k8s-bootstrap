terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}

provider "kubectl" {
  config_path    = var.kube_config
  config_context = var.kube_context
}

variable "kube_config" {
  type = string
}
variable "software_version" {
  type = string
}
variable "kube_env" {
  type = string
}
variable "kube_context" {
  type = string
}
variable "sealed_secrets_status" {
  type = string
}
variable "manifests_dir" {
  type = string
}

resource "helm_release" "redis" {
  name              = "redis"
  repository        = "oci://registry-1.docker.io/bitnamicharts"
  chart             = "redis"
  version           = var.software_version
  namespace         = "redis"
  create_namespace  = true
  values            = [file("${var.manifests_dir}/values.yaml")]
  depends_on        = [var.sealed_secrets_status]
  count             = var.enabled ? 1 : 0
}
