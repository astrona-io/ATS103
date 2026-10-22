#!/usr/bin/env bash
# PASS when the preheat policy release-preheat in inventory uses dragonfly, is enabled, runs on push and selects only v* tags.
set -uo pipefail

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

if [ "$(harbor_status GET /projects/inventory/preheat/policies/release-preheat)" != "200" ]; then
  echo "FAIL: the project inventory has no preheat policy named release-preheat."; exit 1
fi
POLICY="$(harbor_api GET /projects/inventory/preheat/policies/release-preheat | ws jq -c .)"
POLICY_ID="$(printf '%s' "$POLICY" | json '.id')"
P_PROVIDER="$(printf '%s' "$POLICY" | json '.provider_id')"
P_ENABLED="$(printf '%s' "$POLICY" | json '.enabled')"
P_TRIGGER="$(printf '%s' "$POLICY" | json '.trigger | fromjson | .type')"
P_TAG="$(printf '%s' "$POLICY" | json '[.filters | fromjson | .[] | select(.type=="tag") | .value][0] // ""')"
P_REPO="$(printf '%s' "$POLICY" | json '[.filters | fromjson | .[] | select(.type=="repository") | .value][0] // ""')"
INSTANCE_ID="$(harbor_api GET /p2p/preheat/instances/dragonfly | json '.id')"
if [ "$P_PROVIDER" != "$INSTANCE_ID" ]; then echo "FAIL: release-preheat does not use the instance dragonfly."; exit 1; fi
if [ "$P_ENABLED" != "true" ]; then echo "FAIL: release-preheat is not enabled."; exit 1; fi
if [ "$P_TRIGGER" != "event_based" ]; then echo "FAIL: release-preheat has the trigger '$P_TRIGGER'; it must run when an artifact is pushed (event_based)."; exit 1; fi
if [ "$P_TAG" != "v*" ]; then echo "FAIL: release-preheat preheats the tags '$P_TAG'; only release tags (v*) may be preheated."; exit 1; fi
if [ -z "$P_REPO" ]; then echo "FAIL: release-preheat has no repository filter."; exit 1; fi

echo "PASS: release-preheat preheats release tags on push through dragonfly."
exit 0
