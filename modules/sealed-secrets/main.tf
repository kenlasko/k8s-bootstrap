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
variable "cilium_status" {
  type = string
}
variable "manifests_dir" {
  type = string
}

data "kubectl_file_documents" "default_sealingkey" {
  content = file("/run/secrets/global-sealed-secrets-key.yaml")
}

resource "kubectl_manifest" "default_sealingkey" {
    for_each  = data.kubectl_file_documents.default_sealingkey.manifests
    yaml_body = each.value
}

resource "helm_release" "sealed-secrets" {
  name              = "sealed-secrets"
  repository        = "oci://registry-1.docker.io/bitnamicharts"
  chart             = "sealed-secrets"
  version           = var.software_version
  namespace         = "kube-system"
  create_namespace  = false
  values            = [file("${var.manifests_dir}/values.yaml")]
  depends_on        = [var.cilium_status, resource.kubectl_manifest.default_sealingkey]
}

output "status" {
  value = helm_release.sealed-secrets.status
}