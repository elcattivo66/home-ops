### My Home Operations Repository

_... managed with Flux, Renovate, and GitHub Actions_ 🤖

---

## 📖 Overview

This is a mono repository for my home infrastructure and Kubernetes cluster. I try to adhere to Infrastructure as Code (IaC) and GitOps practices using tools like [Ansible](https://www.ansible.com/), [Terraform](https://www.terraform.io/), [Kubernetes](https://kubernetes.io/), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate), and [GitHub Actions](https://github.com/features/actions).

---

## ⛵ Kubernetes

This is based on the structure of the template over at [onedr0p/flux-cluster-template](https://github.com/onedr0p/flux-cluster-template).

### Installation

My cluster is [k3s](https://k3s.io/) provisioned overtop bare-metal Debian using the [Ansible](https://www.ansible.com/) galaxy role [ansible-role-k3s](https://github.com/PyratLabs/ansible-role-k3s). This is a semi-hyper-converged cluster, workloads and block storage are sharing the same available resources on my nodes while I have a separate server for (NFS) file storage.

🔸 _[Click here](./ansible/) to see my Ansible playbooks and roles._

### Core Components

- [cilium](https://github.com/cilium/cilium): internal Kubernetes networking plugin
- [cert-manager](https://cert-manager.io/docs/): creates SSL certificates for services in my cluster
- [external-dns](https://github.com/kubernetes-sigs/external-dns): automatically syncs DNS records from my cluster ingresses to a DNS provider
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx): ingress controller for Kubernetes
- [longhorn](https://github.com/longhorn/longhorn): distributed block storage for persistent storage
- [sops](https://toolkit.fluxcd.io/guides/mozilla-sops/): managed secrets for Kubernetes, Ansible, and Terraform which are committed to Git

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [kubernetes](./kubernetes/) folder (see Directories below) and makes the changes to my cluster based on the YAML manifests.

The way Flux works for me here is it will recursively search the [kubernetes/main/apps](./kubernetes/apps) folder until it finds the most top level `kustomization.yaml` per directory and then apply all the resources listed in it. That aforementioned `kustomization.yaml` will generally only have a namespace resource and one or many Flux kustomizations. Those Flux kustomizations will generally have a `HelmRelease` or other resources related to the application underneath it which will be applied.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created. When some PRs are merged [Flux](https://github.com/fluxcd/flux2) applies the changes to my cluster.

### Directories

This Git repository contains the following directories under [Kubernetes](./kubernetes/).

```sh
📁 kubernetes
├── 📁 main            # main cluster
│   ├── 📁 apps           # applications
│   ├── 📁 bootstrap      # bootstrap procedures
│   ├── 📁 flux           # core flux configuration
│   └── 📁 templates      # re-useable components
└── 📁 nas             # nas cluster
    ├── 📁 apps           # applications
    ├── 📁 bootstrap      # bootstrap procedures
    └── 📁 flux           # core flux configuration
```

### Cluster Layout

Below is a high-level look at the layout of how my directory structure with Flux works. In this brief example, you are able to see that `authelia` will not be able to run until `lldap` and  `cloudnative-pg` are running. It also shows that the `Cluster` custom resource depends on the `cloudnative-pg` Helm chart. This is needed because `cloudnative-pg` installs the `Cluster` custom resource definition in the Helm chart.

```python
# Key: <kind> :: <metadata.name>
GitRepository :: home-kubernetes
    Kustomization :: cluster
        Kustomization :: cluster-apps
            Kustomization :: cloudnative-pg
                HelmRelease :: cloudnative-pg
            Kustomization :: cloudnative-pg-cluster
                DependsOn:
                    Kustomization :: cloudnative-pg
                Cluster :: postgres
            Kustomization :: lldap
                HelmRelease :: lldap
                DependsOn:
                    Kustomization :: cloudnative-pg-cluster
            Kustomization :: authelia
                DependsOn:
                    Kustomization :: lldap
                    Kustomization :: cloudnative-pg-cluster
                HelmRelease :: authelia
```

---

## 🌐 DNS

### Home DNS

I have a Orange Pi Zero SBC with pihole and unbound deployed as containers. In my cluster external-dns is deployed with the pihole provider which syncs DNS records to pihole.

### Public DNS

Outside the `external-dns` instance mentioned above another instance is deployed in my cluster and configured to sync DNS records to [Cloudflare](https://www.cloudflare.com/). The only ingress this `external-dns` instance looks at to gather DNS records to put in `Cloudflare` are ones that have an ingress class name of `external` and an ingress annotation of `external-dns.alpha.kubernetes.io/target`.

---

## 🔧 Hardware

| Device                      | Count | OS Disk Size | Data Disk Size              | Ram  | Operating System | Purpose             |
|-----------------------------|-------|--------------|-----------------------------|------|------------------|---------------------|
| Intel NUC11i3               | 1     | 512GB NVMe   |                             | 40GB | Debian           | Kubernetes Master   |
| Morefine M9                 | 1     | 512GB NVMe   |                             | 16GB | Debian           | Kubernetes Master   |
| Gigabyte Brix 7100          | 1     | 512GB NVMe   |                             | 24GB | Debian           | Kubernetes Master   |
| Node 304 + Ryzen 5600G      | 1     | 128GB SSD    | 2x16TB+2x8TB ZFS & 2TB SSD  | 32GB | NixOS            | NAS                 |

---
