terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "= 1.19.0"
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
variable "manifests_dir" {
  type = string
}
variable "kube_context" {
  type = string
}
variable "gateway_api_crd_version" {
  type = string
  default = "v1.2.0"
}

# Data source to fetch the Gateway API CRD YAML
data "http" "gateway_api_crd" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.gateway_api_crd_version}/experimental-install.yaml"
}

# Resource to apply the Gateway API CRDs
resource "kubectl_manifest" "gateway_api_crds" {
  yaml_body = data.http.gateway_api_crd.response_body 
}

# Install Cilium using Helm
resource "helm_release" "cilium" {
  name              = "cilium"
  repository        = "https://helm.cilium.io/"
  chart             = "cilium"
  version           = var.software_version
  namespace         = "cilium"
  create_namespace  = true
  values            = [file("${var.manifests_dir}/values.yaml")]
}

# Apply all the other Cilium manifests, excluding values.yaml
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

