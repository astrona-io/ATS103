#!/usr/bin/env bash
# Creates the starting state for ats-103-capstone-010: an endpoint on the wrong port and a rule that cannot work.
#
# The corrected configuration is NOT applied here: producing it is the task.
set -euo pipefail

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

regctl_login

# Harbor 2.15 checks an endpoint's health on every create and update and
# refuses an unreachable one (400 "the registry is unhealthy"). To seed an
# endpoint on the wrong port, the mirror Service answers on port 5000 for a
# moment, the endpoint is saved with :5000, and then port 5000 is removed.
if [ -z "$(registry_id mirror)" ]; then
  harbor_api POST /registries '{"name":"mirror","type":"docker-registry","url":"http://mirror.localtest.me:5001","insecure":true,"description":"The mirror registry"}' >/dev/null
fi
MIRROR_ID="$(registry_id mirror)"
kubectl -n mirror patch service mirror --type=json \
  -p '[{"op":"add","path":"/spec/ports/-","value":{"name":"wrong-port","port":5000,"targetPort":"http"}}]' >/dev/null
for _ in $(seq 1 30); do
  harbor_api PUT "/registries/$MIRROR_ID" '{"url":"http://mirror.localtest.me:5000","insecure":true}' >/dev/null 2>&1 && break
  sleep 2
done
kubectl -n mirror patch service mirror --type=json \
  -p '[{"op":"remove","path":"/spec/ports/1"}]' >/dev/null
[ "$(harbor_api GET "/registries/$MIRROR_ID" | json '.url')" = "http://mirror.localtest.me:5000" ] || {
  echo "ERROR: could not move the endpoint mirror to port 5000." >&2; exit 1; }
if [ -z "$(harbor_api GET "/replication/policies?page_size=100" | json '.[] | select(.name=="release-to-mirror") | .id')" ]; then
  harbor_api POST /replication/policies "{\"name\":\"release-to-mirror\",\"dest_registry\":{\"id\":$MIRROR_ID},\"dest_namespace\":\"inventory\",\"dest_namespace_replace_count\":1,\"filters\":[{\"type\":\"name\",\"value\":\"inventry/**\"},{\"type\":\"tag\",\"value\":\"v*\",\"decoration\":\"matches\"}],\"trigger\":{\"type\":\"manual\"},\"replicate_deletion\":false,\"override\":true,\"enabled\":false,\"speed\":-1}" >/dev/null
fi
RULE_ID="$(harbor_api GET "/replication/policies?page_size=100" | json '.[] | select(.name=="release-to-mirror") | .id')"
kubectl -n workstation create configmap capstone-baseline --from-literal=rule_id="$RULE_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[lab] Starting state ready: release tags do not reach the mirror."
