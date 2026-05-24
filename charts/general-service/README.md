# general-service

A general-purpose Helm chart for deploying containerized services with HTTPRoute, Service, HPA, and PDB support.

## Overview

This chart provides a flexible way to deploy containerized applications to Kubernetes with common production-ready features including:

- Configurable Deployment with init containers
- Service exposure (ClusterIP, LoadBalancer, NodePort)
- HTTPRoute for Gateway API integration
- Horizontal Pod Autoscaler (HPA)
- Pod Disruption Budget (PDB)
- Security hardening with sensible defaults

## Installation

```bash
helm install my-release ./charts/general-service \
  --set image.repository=nginx \
  --set image.tag=1.21
```

## Quick Start

### Basic deployment

```yaml
image:
  repository: nginx
  tag: "1.21"
```

### Full example with all features

```yaml
image:
  repository: myapp
  tag: "v1.0.0"
  pullPolicy: IfNotPresent
  pullSecrets:
    - name: my-registry-secret

replicas: 3
containerPort: 8080

command:
  - /app/server
args:
  - --config=/etc/config/app.yaml

env:
  literal:
    LOG_LEVEL: info
    ENV: production
  fromConfigMaps:
    - configMapName: app-config
      keys:
        - key: database-url
          envName: DATABASE_URL
  fromSecrets:
    - secretName: app-secrets
      keys:
        - key: api-key
          envName: API_KEY

volumes:
  - name: config
    configMap:
      name: app-config
  - name: tmp
    emptyDir: {}

volumeMounts:
  - name: config
    mountPath: /etc/config
    readOnly: true
  - name: tmp
    mountPath: /tmp

initContainers:
  - name: init-db
    image:
      repository: postgres
      tag: "15"
    command:
      - sh
      - -c
      - "until pg_isready -h $DB_HOST; do sleep 2; done"
    env:
      literal:
        DB_HOST: postgres.default.svc

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5

service:
  enabled: true
  type: ClusterIP
  port: 8080

httpRoute:
  enabled: true
  gateway:
    name: main-gateway
    namespace: gateway-system
  hostnames:
    - myapp.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /

hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

pdb:
  enabled: true
  minAvailable: 1
```

## Configuration Reference

### General

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nameOverride` | Override the name of the chart | `""` |
| `fullnameOverride` | Override the full name of the release | `""` |
| `replicas` | Number of replicas for the deployment | `2` |

### Image

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `""` (required) |
| `image.tag` | Container image tag | `""` (defaults to Chart.appVersion) |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.pullSecrets` | Image pull secrets for private registries | `[]` |

### Container

| Parameter | Description | Default |
|-----------|-------------|---------|
| `containerPort` | Container port | `8080` |
| `command` | Override the container command | `[]` |
| `args` | Override the container arguments | `[]` |
| `resources` | Resource requests and limits | `{}` |

### Environment Variables

| Parameter | Description | Default |
|-----------|-------------|---------|
| `env.literal` | Literal environment variables (key-value pairs) | `{}` |
| `env.fromConfigMaps` | Environment variables from ConfigMaps | `[]` |
| `env.fromSecrets` | Environment variables from Secrets | `[]` |

#### Environment from ConfigMap example

```yaml
env:
  fromConfigMaps:
    - configMapName: my-config
      keys:
        - key: config-key
          envName: MY_CONFIG_VAR  # optional, defaults to key name
```

#### Environment from Secret example

```yaml
env:
  fromSecrets:
    - secretName: my-secret
      keys:
        - key: secret-key
          envName: MY_SECRET_VAR  # optional, defaults to key name
```

### Volumes

| Parameter | Description | Default |
|-----------|-------------|---------|
| `volumes` | Volumes for the pod | `[]` |
| `volumeMounts` | Volume mounts for the container | `[]` |

#### Volumes example

```yaml
volumes:
  - name: config-volume
    configMap:
      name: my-config
  - name: secret-volume
    secret:
      secretName: my-secret
  - name: empty-dir
    emptyDir: {}
  - name: pvc-volume
    persistentVolumeClaim:
      claimName: my-pvc

volumeMounts:
  - name: config-volume
    mountPath: /etc/config
    readOnly: true
```

### Init Containers

| Parameter | Description | Default |
|-----------|-------------|---------|
| `initContainers` | Init containers configuration | `[]` |

Init containers support the same features as the main container:
- `name` - Container name (required)
- `image.repository` - Image repository (required)
- `image.tag` - Image tag (required)
- `image.pullPolicy` - Pull policy
- `command` - Command override
- `args` - Arguments override
- `env` - Environment variables (literal, fromConfigMaps, fromSecrets)
- `volumeMounts` - Volume mounts
- `resources` - Resource requests/limits
- `securityContext` - Security context (inherits default if not specified)

#### Init container example

```yaml
initContainers:
  - name: init-myservice
    image:
      repository: busybox
      tag: "1.36"
      pullPolicy: IfNotPresent
    command:
      - sh
      - -c
      - "echo initializing..."
    env:
      literal:
        INIT_VAR: "init-value"
    volumeMounts:
      - name: shared
        mountPath: /shared
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
```

### Health Probes

| Parameter | Description | Default |
|-----------|-------------|---------|
| `livenessProbe` | Liveness probe configuration | `{}` |
| `readinessProbe` | Readiness probe configuration | `{}` |
| `startupProbe` | Startup probe configuration | `{}` |

#### Probe example

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5

startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

### Service

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.enabled` | Enable service creation | `true` |
| `service.type` | Service type (ClusterIP, LoadBalancer, NodePort) | `ClusterIP` |
| `service.port` | Service port | `8080` |
| `service.annotations` | Additional service annotations | `{}` |

### HTTPRoute (Gateway API)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `httpRoute.enabled` | Enable HTTPRoute creation | `false` |
| `httpRoute.gateway.name` | Gateway name (required when enabled) | `""` |
| `httpRoute.gateway.namespace` | Gateway namespace | `""` (same namespace) |
| `httpRoute.hostnames` | Hostnames for the route | `[]` |
| `httpRoute.rules` | HTTP route rules | PathPrefix `/` |
| `httpRoute.annotations` | Additional HTTPRoute annotations | `{}` |

#### HTTPRoute example

```yaml
httpRoute:
  enabled: true
  gateway:
    name: main-gateway
    namespace: gateway-system
  hostnames:
    - myapp.example.com
    - www.myapp.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
    - matches:
        - path:
            type: PathPrefix
            value: /
```

### Horizontal Pod Autoscaler (HPA)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `hpa.enabled` | Enable HPA creation | `false` |
| `hpa.minReplicas` | Minimum number of replicas | `2` |
| `hpa.maxReplicas` | Maximum number of replicas | `10` |
| `hpa.targetCPUUtilizationPercentage` | Target CPU utilization percentage | `80` |
| `hpa.targetMemoryUtilizationPercentage` | Target memory utilization percentage | `null` |

When HPA is enabled, the `replicas` field is not set in the Deployment to allow HPA to manage scaling.

### Pod Disruption Budget (PDB)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `pdb.enabled` | Enable PDB creation | `false` |
| `pdb.minAvailable` | Minimum available pods (number or percentage) | `1` |
| `pdb.maxUnavailable` | Maximum unavailable pods (alternative to minAvailable) | `null` |

### Security Context

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podSecurityContext` | Pod-level security context | `runAsNonRoot: true` |
| `securityContext` | Container-level security context | See below |

Default container security context (applied to main and init containers):

```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
```

### Pod Scheduling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nodeSelector` | Node selector for pod scheduling | `{}` |
| `tolerations` | Tolerations for pod scheduling | `[]` |
| `affinity` | Affinity rules for pod scheduling | `{}` |

### Pod Metadata

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podAnnotations` | Additional pod annotations | `{}` |
| `podLabels` | Additional pod labels | `{}` |

### Service Account

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create a service account | `false` |
| `serviceAccount.name` | Service account name | `""` (generated) |
| `serviceAccount.annotations` | Service account annotations | `{}` |

#### Service account example (AWS IRSA)

```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/my-role
```

## Security Defaults

This chart ships with security-hardened defaults:

1. **Pod runs as non-root**: `runAsNonRoot: true`
2. **No privilege escalation**: `allowPrivilegeEscalation: false`
3. **Read-only root filesystem**: `readOnlyRootFilesystem: true`
4. **All capabilities dropped**: `capabilities.drop: [ALL]`

If your application requires different security settings, you can override these values:

```yaml
podSecurityContext:
  runAsNonRoot: false
  runAsUser: 0

securityContext:
  allowPrivilegeEscalation: true
  readOnlyRootFilesystem: false
  capabilities:
    drop: []
    add:
      - NET_BIND_SERVICE
```

## Upgrading

### To 0.x

Initial release - no upgrade notes.
