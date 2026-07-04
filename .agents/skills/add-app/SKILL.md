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
8. **Needs database** - whether the app needs a PostgreSQL database (yes/no)
9. **If database: DB name** - the PostgreSQL database name (e.g., `radarr_main`)
10. **If database: DB user** - the dedicated role name (e.g., `radarr`)
11. **If database: Bitwarden UUID** - the Bitwarden item UUID that contains `pg_user` and `pg_password` fields (e.g., `133e1c1d-894d-4fc7-a69c-d44bd3fe090f`)

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
    - ../../../../components/postgres-db  # only if app needs a database
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

Only include `dependsOn` if user specified dependencies. The list should include:
- `external-secrets-stores` (always, if the app has secrets or uses postgres-db)
- `cloudnative-pg-cluster` (only if app uses postgres-db component)
- Any other component dependencies (`volsync`, `rook-ceph-cluster`, etc.)

Example:
```yaml
  dependsOn:
    - name: external-secrets-stores
      namespace: external-secrets
    - name: cloudnative-pg-cluster
      namespace: databases
```

For the `postBuild.substitute` block, add database variables when applicable:
```yaml
  postBuild:
    substitute:
      APP: *appname
      DB_NAME: <db-name>          # only if app needs a database
      DB_USER: <db-user>          # only if app needs a database
      DB_BITWARDEN_ID: <uuid>     # only if app needs a database
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

> **If the app needs a database**: The app needs env vars for the DB connection. Add them under `controllers.<app-name>.containers.app.env` (or via `envFrom` referencing the app's secret). The DB host is always `postgres-rw.databases.svc.cluster.local`, port `5432`. The DB credentials (user, password) come from the same Bitwarden item as the app's other secrets. Fetch them in the `externalsecret.yaml` under `pg_user` and `pg_password` properties, and map them to the app's expected env var names.

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

> **If the app needs a database**: The same Bitwarden item typically contains `pg_user` and `pg_password` fields. Add them to the ExternalSecret template, mapped to the app's DB credential env vars. Example:
> ```yaml
>       data:
>         APP_DB_USER: "{{ .pg_user }}"
>         APP_DB_PASSWORD: "{{ .pg_password }}"
> ```
> Then reference these in the HelmRelease via `envFrom`:
> ```yaml
>             envFrom:
>               - secretRef:
>                   name: <app-name>-secret
> ```
> The DB host and port (`postgres-rw.databases.svc.cluster.local:5432`) and database name are typically static and set directly in the HelmRelease env, not in the secret.

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
- **PostgreSQL database** (postgres-db component): Creates a CNPG Database and DatabaseRole CR, plus an ExternalSecret for the DB password, all reconciled into the `databases` namespace. The app **must not** include init-db containers or any other database provisioning logic.
- `DB_BITWARDEN_ID` should reference a Bitwarden item that has `pg_user` and `pg_password` custom fields with the dedicated role credentials for the app
- The postgres-db component automatically grants the `pg_monitor` role to the dedicated DB role
- DB credentials (user + password) are typically fetched from the **same Bitwarden item** as the app's other secrets and mapped in the app's `externalsecret.yaml`
- The DB host is always `postgres-rw.databases.svc.cluster.local`, port `5432`
- Recommended DB naming convention: `<app>_main` for the primary database, `<app>` for the role name
