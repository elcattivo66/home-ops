---
name: add-app
description: Scaffold a new app-template Helm chart application
---

# Add New Application

This skill scaffolds a new application in your home-ops repository based on the `app-template` Helm chart.

## Workflow

### Step 1: Collect Application Details

Use the `question` tool to gather:

1. **App name** - the Kubernetes resource name (e.g., `radarr`, `sonarr`)
2. **Namespace** - the target Kubernetes namespace (e.g., `default`, `ai`, `networking`)
3. **Image repository** - full container image URL (e.g., `ghcr.io/autobrr/autobrr`)
4. **Image tag** - version tag (e.g., `v1.76.0`)
5. **Port** - application port number (e.g., `7474`)
6. **Dependencies** - any Flux Kustomization dependencies (e.g., `volsync`)
7. **Has secrets** - whether to create an ExternalSecret (yes/no)

### Step 2: Create Directory Structure

Create the directory: `kubernetes/apps/<namespace>/<app-name>/app/`

### Step 3: Generate Files

Create these files with templated values:

---

**`kubernetes/apps/<namespace>/<app-name>/ks.yaml`**
```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/kustomize.toolkit.fluxcd.io/kustomization_v1.json
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: <app-name>
spec:
  commonMetadata:
    labels:
      app.kubernetes.io/name: <app-name>
  components:
    - ../../../../components/volsync
  interval: 1h
  path: "./kubernetes/apps/<namespace>/<app-name>/app"
  postBuild:
    substitute:
      APP: <app-name>
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  targetNamespace: <namespace>
  timeout: 5m
  wait: false
```

Only include `dependsOn` if user specified dependencies.

---

**`kubernetes/apps/<namespace>/<app-name>/app/kustomization.yaml`**
```yaml
---
# yaml-language-server: $schema=https://json.schemastore.org/kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./ocirepository.yaml
  - ./helmrelease.yaml
```

Include `./externalsecret.yaml` only if secrets are needed.

---

**`kubernetes/apps/<namespace>/<app-name>/app/ocirepository.yaml`**
```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/source.toolkit.fluxcd.io/ocirepository_v1.json
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: <app-name>
spec:
  interval: 15m
  layerSelector:
    mediaType: application/vnd.cncf.helm.chart.content.v1.tar+gzip
    operation: copy
  ref:
    tag: 5.0.1
  url: oci://ghcr.io/bjw-s-labs/helm/app-template
```

---

**`kubernetes/apps/<namespace>/<app-name>/app/helmrelease.yaml`**
```yaml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/bjw-s-labs/helm-charts/main/charts/other/app-template/schemas/helmrelease-helm-v2.schema.json
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: <app-name>
spec:
  chartRef:
    kind: OCIRepository
    name: <app-name>
  interval: 30m
  values:
    controllers:
      <app-name>:
        pod:
          securityContext:
            runAsGroup: 1000
            runAsNonRoot: true
            runAsUser: 1000
        containers:
          app:
            image:
              repository: <image-repo>
              tag: <image-tag>
            probes:
              liveness:
                enabled: true
                spec:
                  periodSeconds: 30
                  timeoutSeconds: 5
                  failureThreshold: 5
              readiness:
                enabled: true
                spec:
                  periodSeconds: 10
                  timeoutSeconds: 5
                  failureThreshold: 5
              startup:
                enabled: true
                spec:
                  failureThreshold: 30
                  periodSeconds: 10
            resources:
              requests:
                cpu: 10m
                memory: 128Mi
            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
              capabilities:
                drop:
                  - ALL
    service:
      app:
        ports:
          http:
            port: <port>
```

---

**`kubernetes/apps/<namespace>/<app-name>/app/externalsecret.yaml`** (only if secrets needed)
```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/external-secrets.io/externalsecret_v1.json
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: <app-name>
spec:
  target:
    deletionPolicy: Delete
    template:
      type: Opaque
      data:
  data:
    - secretKey: SECRET_KEY
      sourceRef:
        storeRef:
          name: bitwarden-fields
          kind: ClusterSecretStore
      remoteRef:
        key: <app-name>
        property: secret_key
```

Update the `data` section with actual secret keys based on the app's needs.

### Step 4: Update Namespace Kustomization

Read `kubernetes/apps/<namespace>/kustomization.yaml` and add the new app's ks.yaml to the resources array:
```yaml
resources:
  - ./namespace.yaml
  - ./<app-name>/ks.yaml
  # ... existing apps
```

### Step 5: Verify

Run `find kubernetes/apps/<namespace>/<app-name> -type f` to confirm all files were created correctly.

## Notes

- Default app-template version is `5.0.1`
- Security context defaults: runAsUser/runAsGroup 1000, readOnlyRootFilesystem true, drop ALL caps
- If the namespace directory doesn't exist, ask user to create it first
- Always ask for confirmation before writing files
