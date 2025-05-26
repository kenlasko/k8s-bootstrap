terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
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
}

data "kubectl_path_documents" "docs" {
    pattern = "${var.manifests_dir}/(sealed-secrets|volume).yaml"
}

resource "kubectl_manifest" "redis" {
    for_each    = data.kubectl_path_documents.docs.manifests
    yaml_body   = each.value
    depends_on  = [helm_release.redis]
}
