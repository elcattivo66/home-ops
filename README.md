# Bootstrap

## Flux

### Install Flux

```sh
kubectl apply --server-side --kustomize ./kubernetes/bootstrap/flux
```

### Apply Cluster Configuration

_These cannot be applied with `kubectl` in the regular fashion due to be encrypted with sops_

```sh
sops --decrypt kubernetes/bootstrap/flux/age-key.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/bootstrap/flux/github-deploy-key.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/flux/vars/cluster-secrets.sops.yaml | kubectl apply -f -
kubectl apply -f kubernetes/flux/vars/cluster-settings.yaml
```

### Kick off Flux applying this repository

```sh
kubectl apply --server-side --kustomize ./kubernetes/flux/config
```


# Install k3s:
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.25.5+k3s1 K3S_TOKEN=<TOKEN> sh -s - --write-kubeconfig-mode 644 --disable=traefik --disable=local-storage --disable=servicelb --cluster-init


curl -sfL https://get.k3s.io | K3S_TOKEN=<TOKEN> sh -s - --write-kubeconfig-mode 644 --disable=traefik --disable=local-storage --disable=servicelb --node-taint 'node-role.kubernetes.io/master=true:NoSchedule' --server https://192.168.178.21:6443


Uninstall k3s:
/usr/local/bin/k3s-uninstall.sh

SOPS Secrets:
pacman -S sops
https://fluxcd.io/docs/guides/mozilla-sops/
https://devopstales.github.io/kubernetes/gitops-flux2-sops/

### Apply flux2
kubectl apply --kustomize k3s-gitops/kubernetes/bootstrap/

### Add sops key to cluster
cat age.agekey |
kubectl create secret generic sops-age \
--namespace=flux-system \
--from-file=age.agekey=/dev/stdin

### Apply gitea secrets and flux-system
sops -d k3s-gitops/kubernetes/flux/flux-system/secret.sops.yaml | kubectl apply -f -
kubectl apply --kustomize k3s-gitops/kubernetes/flux/flux-system/

### Reconcile
      - flux reconcile -n flux-system source git flux-cluster
      - flux reconcile -n flux-system kustomization flux-cluster

sops -d -i secret.yaml

Longhorn:
pacman -S open-iscsi

Worker:
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.24.7+k3s1 K3S_URL=https://192.168.178.21:6443 K3S_TOKEN="<TOKEN>" sh -

