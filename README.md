# Install k3s:
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.25.5+k3s1 K3S_TOKEN=<TOKEN> sh -s - --write-kubeconfig-mode 644 --disable=traefik --disable=local-storage --disable=servicelb --cluster-init


curl -sfL https://get.k3s.io | K3S_TOKEN=<TOKEN> sh -s - --write-kubeconfig-mode 644 --disable=traefik --disable=local-storage --disable=servicelb --node-taint 'node-role.kubernetes.io/master=true:NoSchedule' --server https://192.168.178.21:6443

flux bootstrap git --url=https://gitea.elcattivo.de/philipp/k3s-gitops --password=himbeertoni --path=./cluster/flux --username=philipp --token-auth --token 9fa392acd4596e4f687ad66c039c813f6e5c3400

Uninstall k3s:
/usr/local/bin/k3s-uninstall.sh

SOPS Secrets:
pacman -S sops
https://fluxcd.io/docs/guides/mozilla-sops/
https://devopstales.github.io/kubernetes/gitops-flux2-sops/

### Apply flux2
kubectl apply --kustomize k3s-gitops/cluster/bootstrap/

### Add sops key to cluster
cat age.agekey |
kubectl create secret generic sops-age \
--namespace=flux-system \
--from-file=age.agekey=/dev/stdin

### Apply gitea secrets and flux-system
sops -d k3s-gitops/cluster/flux/flux-system/secret.sops.yaml | kubectl apply -f -
kubectl apply --kustomize k3s-gitops/cluster/flux/flux-system/

### Reconcile
      - flux reconcile -n flux-system source git flux-cluster
      - flux reconcile -n flux-system kustomization flux-cluster

sops -d -i secret.yaml

Longhorn:
pacman -S open-iscsi

Worker:
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.24.7+k3s1 K3S_URL=https://192.168.178.21:6443 K3S_TOKEN="<TOKEN>" sh -

