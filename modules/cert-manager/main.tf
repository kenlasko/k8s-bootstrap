terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "kubectl" {
  config_path    = "/home/ken/.kube/config"
  config_context = var.kube_context
}

variable "cert_manager_version" {
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
  default = "/home/ken/k8s-lab/manifests/system/cert-manager"
}



resource "helm_release" "cert-manager" {
  name              = "cert-manager"
  repository        = "https://charts.jetstack.io"
  chart             = "cert-manager"
  version           = var.cert_manager_version
  namespace         = "cert-manager"
  create_namespace  = true
  values            = [file("${var.manifests_dir}/values.yaml")]
  depends_on        = [var.sealed_secrets_status]
}

data "kubectl_path_documents" "docs" {
    pattern = "${var.manifests_dir}/[a-s]*.yaml"
}

resource "kubectl_manifest" "cert-manager" {
    for_each    = data.kubectl_path_documents.docs.manifests
    yaml_body   = each.value
    depends_on  = [helm_release.cert-manager]
}



