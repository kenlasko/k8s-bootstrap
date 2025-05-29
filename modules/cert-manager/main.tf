terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}

# provider "kubectl" {
#   config_path    = var.kube_config
#   config_context = var.kube_context
# }

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
variable "external_secrets_status" {
  type = string
}
variable "manifests_dir" {
  type = string
}

resource "helm_release" "cert-manager" {
  name              = "cert-manager"
  repository        = "https://charts.jetstack.io"
  chart             = "cert-manager"
  version           = var.software_version
  namespace         = "cert-manager"
  create_namespace  = true
  values            = [file("${var.manifests_dir}/values.yaml")]
  depends_on        = [var.external_secrets_status]
}

data "kubectl_path_documents" "docs" {
    pattern = "${var.manifests_dir}/[a-s]*.yaml"
}

resource "kubectl_manifest" "cert-manager" {
    for_each    = data.kubectl_path_documents.docs.manifests
    yaml_body   = each.value
    depends_on  = [helm_release.cert-manager]
}
