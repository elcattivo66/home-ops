# Bootstrap

## Flux

### Install Flux

```sh
kubectl apply --server-side --kustomize ./kubernetes/main/bootstrap
```

### Apply Cluster Configuration

_These cannot be applied with `kubectl` in the regular fashion due to be encrypted with sops_

```sh
sops --decrypt kubernetes/main/bootstrap/age-key.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/main/bootstrap/github-deploy-key.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/main/flux/vars/cluster-secrets.sops.yaml | kubectl apply -f -
kubectl apply -f kubernetes/main/flux/vars/cluster-settings.yaml
```

### Kick off Flux applying this repository

```sh
kubectl apply --server-side --kustomize ./kubernetes/main/flux/config
```

# Install k3s:
SOPS Secrets:
pacman -S sops
https://fluxcd.io/docs/guides/mozilla-sops/
https://devopstales.github.io/kubernetes/gitops-flux2-sops/

### Add sops key to cluster
cat age.agekey |
kubectl create secret generic sops-age \
--namespace=flux-system \
--from-file=age.agekey=/dev/stdin

sops -d -i secret.yaml

### Apply gitea secrets and flux-system
sops -d home-ops/kubernetes/main/flux/flux-system/secret.sops.yaml | kubectl apply -f -
kubectl apply --kustomize home-ops/kubernetes/main/flux/flux-system/

### Reconcile
      - flux reconcile -n flux-system source git flux-cluster
      - flux reconcile -n flux-system kustomization flux-cluster

