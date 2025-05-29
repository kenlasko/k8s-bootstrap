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
variable "cilium_status" {
  type = string
}
variable "manifests_dir" {
  type = string
}



resource "helm_release" "external-secrets" {
  name              = "external-secrets"
  repository        = "oci://registry-1.docker.io/bitnamicharts"
  chart             = "external-secrets"
  version           = var.software_version
  namespace         = "external-secrets"
  create_namespace  = true
  values            = [file("${var.manifests_dir}/values.yaml")]
  depends_on        = [var.cilium_status]
}

data "kubectl_file_documents" "secretstore_secrets" {
  content = file("/run/secrets/eso-secretstore-secrets.yaml")
}

resource "kubectl_manifest" "secretstore_secrets" {
    for_each  = data.kubectl_file_documents.secretstore_secrets.manifests
    yaml_body = each.value
}

output "status" {
  value = helm_release.external-secrets.status
}