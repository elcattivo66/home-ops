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
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: &appname <app-name>
  namespace: &namespace <namespace>
spec:
  targetNamespace: *namespace
  commonMetadata:
    labels:
      app.kubernetes.io/name: *appname
  components:
    - ../../../../components/volsync/local
  path: ./kubernetes/apps/<namespace>/<app-name>/app
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  interval: 30m
  retryInterval: 1m
  timeout: 3m
  postBuild:
    substitute:
      APP: *appname
```

Only include `dependsOn` if user specified dependencies. Example:
```yaml
  dependsOn:
    - name: external-secrets-stores
      namespace: external-secrets
```

---

**`kubernetes/apps/<namespace>/<app-name>/app/kustomization.yaml`**
```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./helmrelease.yaml
```

Include `./externalsecret.yaml` only if secrets are needed.

If the app needs a configMapGenerator (e.g., for config files), add it:
```yaml
configMapGenerator:
  - name: <app-name>-configmap
    files:
      - ./resources/config.yaml
generatorOptions:
  disableNameSuffixHash: true
```

> **Note:** This repo uses a global `app-template` OCIRepository in the `flux-system` namespace. Do NOT create a local `ocirepository.yaml`. The HelmRelease's `chartRef` should reference `namespace: flux-system`.

---

**`kubernetes/apps/<namespace>/<app-name>/app/helmrelease.yaml`**
```yaml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/bjw-s-labs/helm-charts/main/charts/other/app-template/schemas/helmrelease-helm-v2.schema.json
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: &app <app-name>
spec:
  interval: 1h
  chartRef:
    kind: OCIRepository
    name: app-template
    namespace: flux-system
  install:
    remediation:
      retries: -1
  upgrade:
    cleanupOnFail: true
    remediation:
      retries: 3
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
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: <app-name>-secret
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
        key: <bitwarden-uuid>
        property: secret_key
```

Update the `data` section with actual secret keys based on the app's needs. The `name` must follow the `<app-name>-secret` convention. The `remoteRef.key` must be a valid Bitwarden item UUID (not the app name).

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

- The global `app-template` OCIRepository lives in `flux-system` namespace — never create a local `ocirepository.yaml`
- Use YAML anchors (`&app`, `&appname`, `&namespace`) in ks.yaml and helmrelease.yaml like existing apps
- ExternalSecret naming: `<app-name>-secret` (not just `<app-name>`)
- ExternalSecret `remoteRef.key` must be a valid Bitwarden item UUID
- ks.yaml uses `volsync/local` component, `interval: 30m`, `retryInterval: 1m`, `timeout: 3m`
- Security context defaults: runAsUser/runAsGroup 1000, readOnlyRootFilesystem true, drop ALL caps
- If the namespace directory doesn't exist, ask user to create it first
- Always ask for confirmation before writing files
