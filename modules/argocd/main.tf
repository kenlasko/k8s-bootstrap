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

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

data "kubectl_file_documents" "configmap" {
  content = file("${var.manifests_dir}/configmap.yaml")
}

resource "kubectl_manifest" "argocd_configmap" {
    for_each  = data.kubectl_file_documents.configmap.manifests
    yaml_body = each.value
    depends_on = [ resource.kubernetes_namespace.argocd ]
}

resource "helm_release" "argocd" {
  name              = "argocd"
  repository        = "https://argoproj.github.io/argo-helm"
  chart             = "argo-cd"
  version           = var.software_version
  namespace         = "argocd"
  create_namespace  = true
  values            = [file("${var.manifests_dir}/values.yaml")]
  depends_on        = [ var.external_secrets_status, resource.kubectl_manifest.argocd_configmap ]
}

data "kubectl_path_documents" "docs" {
    pattern = "${var.manifests_dir}/[a-u]*.yaml"
}

resource "kubectl_manifest" "argocd" {
    for_each    = data.kubectl_path_documents.docs.manifests
    yaml_body   = each.value
    depends_on  = [ helm_release.argocd ]
}



