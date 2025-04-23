# Introduction
This repo is used to bootstrap my [Omni/Talos](https://github.com/kenlasko/omni-public) Kubernetes clusters. It replaces Ansible, which was much harder to keep working. 

It uses [OpenTofu](https://opentofu.org/) which is an open-source version of Terraform. At the time of writing, this repo works with either OpenTofu or Terraform, but was tested on OpenTofu.

It is a very opinionated repo designed to get my cluster to the point where ArgoCD can take over and install all applications. For ArgoCD to function, several other apps have to be running first:
- [Cilium](https://github.com/cilium/cilium) for networking
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) for secret management (requires Cilium)
- [Cert-Manager](https://github.com/cert-manager/cert-manager) for certificate management (requires Sealed Secrets)

It is configured to work with my multiple clusters (`home`, `cloud` and `lab`) using [Workspaces](https://opentofu.org/docs/cli/workspaces/).

## Related Repositories
Links to my other repositories mentioned or used in this repo:
- [NetbootXYZ](https://github.com/kenlasko/docker-rpi1/tree/main/netbootxyz): Simplified PXE boot setup for Omni-managed Talos nodes.
- [K8s Cluster Configuration](https://github.com/kenlasko/k8s): Manages Kubernetes cluster manifests and workloads.
- [NixOS](https://github.com/kenlasko/nixos-wsl): A declarative OS modified to support my Kubernetes cluster
- [Omni](https://github.com/kenlasko/omni): Creates and manages the Kubernetes clusters.

# Prerequisites
OpenTofu/Terraform must be installed on the workstation along with `kubectl` and an available kubeconfig file in `/home/USERNAME/.kube/config`

The repo expects that Kubernetes manifests for the cluster have been cloned to the same filesystem as OpenTofu/Terraform. In addition, you will have to do the following:
1. Modify the folder references in [kubernetes.tf](kubernetes.tf) to match the folder name(s) for your cluster manifests
2. Modify the `kube_env` list of clusters in [kubernetes.tf](kubernetes.tf) to match your own. This should map to the root folder of the repository containing all the manifests as well as the name of the contexts in your `.kubeconfig` file. The two should match. (IE. folder = `~/k8s`, kubecontext = `k8s`)
3. Change the `kube_config` path to match your own
4. Make sure the [Sealed Secret default key](modules/sealed-secrets/main.tf) is available outside the repo for import

# Installation
1. Clone the repo into a folder named something like `terraform`
```
git clone https://github.com/kenlasko/k8s-bootstrap.git terraform
```
2. Setup an alias for `tf` for your chosen application (either OpenTofu or Terraform)
```
echo "alias tf='tofu'" >> ~/.bashrc   # or terraform
source ~/.bashrc
```
3. Add the workspaces to match the `kube_env` references in [kubernetes.tf](kubernetes.tf)
```
tf workspace new home
tf workspace new cloud
tf workspace new lab
```
4. Initialize the application
```
cd ~/terraform
tf init
```
5. Select the appropriate workspace
```
tf workspace select lab
```
6. [Spin up the new cluster](https://github.com/kenlasko/omni)
7. When the new cluster responds to `kubectl get nodes`, run
```
tf apply
```
and type `yes` when ready.


# Tips & Tricks
## Logging
To turn on verbose logging:
```
export TF_LOG="DEBUG"
```