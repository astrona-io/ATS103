#!/usr/bin/env bash
# Installs Harbor and its neighbours for ats-103-lab-010-01 (`ats-103-lab-010-01`).
#
# Graded lab bootstrap: this prepares the environment ONLY. It installs Helm,
# the CoreDNS rewrites, Harbor 2.15.4, the workstation pod and the
# mirror registry, creates the project inventory and copies podinfo into it.
# It never creates the objects the task asks for.
set -euo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

HELM_VERSION="3.22.1"
HARBOR_CHART_VERSION="1.19.4"
DRAGONFLY_CHART_VERSION="1.8.6"
WITH_DRAGONFLY="no"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# Pin Helm rather than accepting whatever is on the machine: the Harbor
# documentation is written for Helm 3.
have_version=""
command -v helm >/dev/null 2>&1 && \
  have_version=$(helm version --template '{{.Version}}' 2>/dev/null | sed 's/^v//')
if [ "$have_version" != "$HELM_VERSION" ]; then
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"
  case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT
  echo "[setup] Downloading Helm ${HELM_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$WORK"
  install -m 0755 "$WORK/${OS}-${ARCH}/helm" "$BIN_DIR/helm"
fi
helm version --short

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# --- shared helpers (generated; keep identical in every ATS103 script) ---
HARBOR_URL="https://harbor.localtest.me:8443"
HARBOR_AUTH="admin:Harbor12345"
MIRROR="mirror.localtest.me:5001"
DRAGONFLY_ENDPOINT="http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080"

# ws CMD...: runs a command in the workstation pod (it trusts Harbor's CA).
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# harbor_api METHOD PATH [JSON]: calls the Harbor REST API v2.0 as admin and
# prints the response body. Fails on an HTTP error.
harbor_api() {
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    printf '%s' "$body" | ws curl -fsS -u "$HARBOR_AUTH" -X "$method" \
      -H 'Content-Type: application/json' --data-binary @- "$HARBOR_URL/api/v2.0$path"
  else
    ws curl -fsS -u "$HARBOR_AUTH" -X "$method" "$HARBOR_URL/api/v2.0$path"
  fi
}

# harbor_status METHOD PATH [JSON]: like harbor_api, but prints only the HTTP status code.
harbor_status() {
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    printf '%s' "$body" | ws curl -sS -o /dev/null -w '%{http_code}' -u "$HARBOR_AUTH" -X "$method" \
      -H 'Content-Type: application/json' --data-binary @- "$HARBOR_URL/api/v2.0$path"
  else
    ws curl -sS -o /dev/null -w '%{http_code}' -u "$HARBOR_AUTH" -X "$method" "$HARBOR_URL/api/v2.0$path"
  fi
}

# json EXPR: reads JSON on stdin and prints the jq result (jq runs in the workstation).
json() { ws jq -r "$1"; }

# registry_id NAME: prints the id of a registry endpoint, or nothing.
registry_id() { harbor_api GET "/registries?page_size=100" | json ".[] | select(.name==\"$1\") | .id"; }

# regctl_login: signs regctl in to Harbor and marks the mirror as plain HTTP.
regctl_login() {
  ws regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345 >/dev/null
  ws regctl registry set "$MIRROR" --tls disabled >/dev/null
}

# mirror_tags REPOSITORY: prints the tags of a repository in the mirror, one per line.
mirror_tags() { ws regctl tag ls "$MIRROR/$1" 2>/dev/null || true; }

# new_release ARTIFACT_TAG: pushes a new, distinct podinfo artifact to
# inventory/podinfo with the given tag (a changed annotation gives it its own digest).
new_release() {
  ws regctl image mod "harbor.localtest.me:8443/inventory/podinfo:6.15.0" \
    --create "$1" --annotation "org.example.build=$1" >/dev/null
}
# --- end of shared helpers ---

# add_coredns_rewrite NAME TARGET: makes NAME resolve to TARGET inside the
# cluster. NAME also resolves to 127.0.0.1 on the reader's machine, so one
# address works in both places. The answer is rewritten back to the asked
# name: Go programs ignore DNS answers whose name differs from the question.
add_coredns_rewrite() {
  local name="$1" target="$2" corefile
  corefile="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}')"
  if printf '%s' "$corefile" | grep -qF "answer name $(printf '%s' "$target" | sed 's/\./\\./g') $name"; then
    return 0
  fi
  echo "[setup] Adding the CoreDNS rewrite for ${name}..."
  corefile="$(printf '%s\n' "$corefile" | NAME_RE="$(printf '%s' "$name" | sed 's/\./\\./g')" \
    TARGET="$target" TARGET_RE="$(printf '%s' "$target" | sed 's/\./\\./g')" NAME="$name" \
    awk '/^[[:space:]]*kubernetes / && !done {
        print "    rewrite stop {"
        print "        name regex " ENVIRON["NAME_RE"] " " ENVIRON["TARGET"]
        print "        answer name " ENVIRON["TARGET_RE"] " " ENVIRON["NAME"]
        print "    }"
        done=1
      } {print}')"
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$corefile" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
}

add_coredns_rewrite harbor.localtest.me harbor.harbor.svc.cluster.local
add_coredns_rewrite mirror.localtest.me mirror.mirror.svc.cluster.local

echo "[setup] Installing Harbor (chart ${HARBOR_CHART_VERSION}); this takes several minutes..."
helm repo add harbor https://helm.goharbor.io >/dev/null 2>&1 || true
helm repo update harbor >/dev/null
helm upgrade --install harbor harbor/harbor --version "$HARBOR_CHART_VERSION" \
  --namespace harbor --create-namespace \
  --values "$MANIFEST_DIR/harbor-values.yaml" \
  --wait --timeout 20m

# lab-start.yaml may already be applied through bootstrap.manifests;
# kubectl apply is idempotent.
echo "[setup] Starting the workstation pod and the mirror registry..."
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
kubectl -n mirror rollout status deployment/mirror --timeout=300s
kubectl -n workstation rollout status deployment/workstation --timeout=600s
for _ in $(seq 1 60); do
  kubectl -n workstation exec deploy/workstation -- test -s /usr/local/share/ca-certificates/harbor-ca.crt 2>/dev/null && break
  sleep 5
done

if [ "$WITH_DRAGONFLY" = "yes" ]; then
  echo "[setup] Installing MySQL and Redis for Dragonfly..."
  kubectl apply -f "$MANIFEST_DIR/dragonfly-deps.yaml"
  kubectl -n dragonfly-system rollout status deployment/mysql --timeout=600s
  kubectl -n dragonfly-system rollout status deployment/redis --timeout=300s
  echo "[setup] Installing Dragonfly (chart ${DRAGONFLY_CHART_VERSION})..."
  helm repo add dragonfly https://dragonflyoss.github.io/helm-charts/ >/dev/null 2>&1 || true
  helm repo update dragonfly >/dev/null
  helm upgrade --install dragonfly dragonfly/dragonfly --version "$DRAGONFLY_CHART_VERSION" \
    --namespace dragonfly-system \
    --values "$MANIFEST_DIR/dragonfly-values.yaml" \
    --wait --timeout 20m
fi

regctl_login
echo "[setup] Creating the project inventory and copying podinfo into it..."
if [ "$(harbor_status GET /projects/inventory)" != "200" ]; then
  harbor_api POST /projects '{"project_name":"inventory","public":false}' >/dev/null
fi
ws regctl image copy ghcr.io/stefanprodan/podinfo:6.15.0 harbor.localtest.me:8443/inventory/podinfo:6.15.0
ws regctl image copy harbor.localtest.me:8443/inventory/podinfo:6.15.0 harbor.localtest.me:8443/inventory/podinfo:v1.0.0

echo "[lab] Harbor is ready."
