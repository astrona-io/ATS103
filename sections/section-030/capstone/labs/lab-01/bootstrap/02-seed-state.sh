#!/usr/bin/env bash
# Creates the starting state for ats-103-capstone-030: a release pipeline in which nothing happens on push.
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

for _ in $(seq 1 60); do
  ws curl -fsS -o /dev/null "$DRAGONFLY_ENDPOINT/healthy" 2>/dev/null && break
  sleep 5
done
if [ -z "$(registry_id mirror)" ]; then
  harbor_api POST /registries '{"name":"mirror","type":"docker-registry","url":"http://mirror.localtest.me:5001","insecure":true,"description":"The mirror registry"}' >/dev/null
fi
MIRROR_ID="$(registry_id mirror)"
if [ -z "$(harbor_api GET "/replication/policies?page_size=100" | json '.[] | select(.name=="release-to-mirror") | .id')" ]; then
  harbor_api POST /replication/policies "{\"name\":\"release-to-mirror\",\"dest_registry\":{\"id\":$MIRROR_ID},\"dest_namespace\":\"inventory\",\"dest_namespace_replace_count\":1,\"filters\":[{\"type\":\"name\",\"value\":\"inventory/**\"},{\"type\":\"tag\",\"value\":\"v*\",\"decoration\":\"matches\"}],\"trigger\":{\"type\":\"manual\"},\"replicate_deletion\":false,\"override\":true,\"enabled\":true,\"speed\":-1}" >/dev/null
fi
# Created healthy first, then moved to the manager's gRPC port and disabled,
# in case Harbor refuses to create an instance it cannot reach.
if [ "$(harbor_status GET /p2p/preheat/instances/dragonfly)" != "200" ]; then
  harbor_api POST /p2p/preheat/instances "{\"name\":\"dragonfly\",\"vendor\":\"dragonfly\",\"endpoint\":\"$DRAGONFLY_ENDPOINT\",\"auth_mode\":\"NONE\",\"enabled\":true,\"insecure\":true,\"default\":false}" >/dev/null
fi
# Break the instance before the policy uses it: Harbor refuses to disable an
# instance that a preheat policy uses (412 Precondition Failed).
if [ "$(harbor_status GET /projects/inventory/preheat/policies/release-preheat)" != "200" ]; then
  BROKEN="$(harbor_api GET /p2p/preheat/instances/dragonfly | ws jq -c '.endpoint="http://dragonfly-manager.dragonfly-system.svc.cluster.local:65003" | .enabled=false')"
  harbor_api PUT /p2p/preheat/instances/dragonfly "$BROKEN" >/dev/null
fi
PROJECT_ID="$(harbor_api GET /projects/inventory | json '.project_id')"
INSTANCE_ID="$(harbor_api GET /p2p/preheat/instances/dragonfly | json '.id')"
if [ "$(harbor_status GET /projects/inventory/preheat/policies/release-preheat)" != "200" ]; then
  harbor_api POST /projects/inventory/preheat/policies "{\"name\":\"release-preheat\",\"project_id\":$PROJECT_ID,\"provider_id\":$INSTANCE_ID,\"filters\":\"[{\\\"type\\\":\\\"repository\\\",\\\"value\\\":\\\"**\\\"},{\\\"type\\\":\\\"tag\\\",\\\"value\\\":\\\"**\\\"}]\",\"trigger\":\"{\\\"type\\\":\\\"manual\\\",\\\"trigger_setting\\\":{\\\"cron\\\":\\\"\\\"}}\",\"enabled\":true}" >/dev/null
fi
RULE_ID="$(harbor_api GET "/replication/policies?page_size=100" | json '.[] | select(.name=="release-to-mirror") | .id')"
POLICY_ID="$(harbor_api GET /projects/inventory/preheat/policies/release-preheat | json '.id')"
kubectl -n workstation create configmap capstone-baseline \
  --from-literal=rule_id="$RULE_ID" --from-literal=instance_id="$INSTANCE_ID" --from-literal=policy_id="$POLICY_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[lab] Starting state ready: a release push neither replicates nor preheats."
