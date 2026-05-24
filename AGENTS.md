# AGENTS.md — Helm Charts Repository

## Quick start
```bash
make all                    # lint + fmt-check + template + test on all charts
CHARTS='charts/general-service' make lint  # target specific chart(s)
```

Helm must be installed. `helm unittest` plugin required for tests (`helm plugin install https://github.com/helm-unittest/helm-unittest.git --verify=false`).

## Charts

| Chart | Description |
|---|---|
| `charts/general-service` | Deployment + Service + HTTPRoute + HPA + PDB. Most feature-rich. |
| `charts/claw` | claw bot with RBAC (ClusterRole/Binding + Role/Binding), PVC, hardened security. |
| `charts/manifests` | Renders arbitrary K8s resources from `values.resources` YAML list via `toYaml`. Minimal, no helpers. |

## CI pipeline (PR checks)
1. **detect-changes** — `./scripts/changed-charts.sh` finds changed charts vs base branch
2. **lint** — `helm lint` on changed charts
3. **format** — `yamllint -c .yamllint.yaml` on changed charts
4. **template** — `helm template` with default values (must not error)
5. **unit-tests** — `helm unittest` on charts with `tests/` directories
6. **version-check** — `./scripts/check-version.sh` enforces semver bump on modified charts
7. **publish** (main only) — Packages and pushes to `oci://ghcr.io/<repo>/<chart>:<version>` via `helm push`

## Branch & PR workflow
- All changes go through PRs via side branches — no direct pushes to `main`.
- Branch off `main`, open a PR targeting `main`.

## Versioning rules
- Every chart modification **must** bump `version:` in `Chart.yaml` (semver), once per PR.
- Choose the bump based on the change:
  - **patch** — bug fixes, refactors, dependency updates, docs
  - **minor** — new features or values (backward-compatible)
  - **major** — breaking changes to templates, required values, or behavior
- `./scripts/check-version.sh <chart_path> <base_ref>` validates: version must increase, cannot stay same or decrease.
- New charts on main have no base version to compare against — they're auto-approved.

## Testing conventions
- Tests are YAML files under `charts/*/tests/` using `helm-unittest` format.
- Each test file starts with `suite:` and lists `templates:` + `tests:` (array of `it:` blocks with `set:` + `asserts:`).
- Snapshot files live in `charts/*/tests/__snapshot__/`.
- Tests require `image.repository` set (no default — schema requires it).

## YAML formatting
- `.yamllint.yaml` config: 2-space indent, 200-char line-length warning, `comments-indentation` disabled, `document-start` disabled.
- Skips `charts/*/charts/` and `charts/*/templates/` (Helm template output/formatted YAML isn't linted).

## repo conventions
- All charts use `apiVersion: v2`, `type: application`.
- Chart versions follow semver (`MAJOR.MINOR.PATCH`).
- Secrets/tokens from environment must not be committed.
