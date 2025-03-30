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

variable "cilium_version" {
  type = string
}
variable "kube_env" {
  type = string
}
variable "manifests_dir" {
  type = string
}
variable "kube_context" {
  type = string
}

resource "helm_release" "cilium" {
  name              = "cilium"
  repository        = "https://helm.cilium.io/"
  chart             = "cilium"
  version           = var.cilium_version
  namespace         = "cilium"
  create_namespace  = true
  values            = [file("${var.manifests_dir}/values.yaml")]
}

data "kubectl_path_documents" "docs" {
    pattern = "${var.manifests_dir}/[a-h]*.yaml"
}

resource "kubectl_manifest" "cilium" {
    for_each    = data.kubectl_path_documents.docs.manifests
    yaml_body   = each.value
    depends_on  = [helm_release.cilium]
}

output "status" {
  value = helm_release.cilium.status
}

