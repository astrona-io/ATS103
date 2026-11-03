#!/usr/bin/env bash
# PASS when the project robot account puller exists, is enabled and can only pull repositories in hub-private.
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

PROJECT_ID="$(harbor_api GET /projects/hub-private | json '.project_id' 2>/dev/null || true)"
if [ -z "$PROJECT_ID" ]; then echo "FAIL: there is no project named hub-private."; exit 1; fi
ROBOT="$(harbor_api GET "/robots?page_size=100&q=Level%3Dproject%2CProjectID%3D$PROJECT_ID" | ws jq -c '.[] | select(.name=="robot$hub-private+puller")')"
if [ -z "$ROBOT" ]; then
  echo 'FAIL: there is no project robot account named puller in hub-private (its full name is robot$hub-private+puller).'
  exit 1
fi
DISABLED="$(printf '%s' "$ROBOT" | json '.disable')"
if [ "$DISABLED" = "true" ]; then echo "FAIL: the robot account puller is disabled."; exit 1; fi
ACTIONS="$(printf '%s' "$ROBOT" | json '[.permissions[].access[] | .resource + ":" + .action] | sort | join(",")')"
if [ "$ACTIONS" != "repository:pull" ]; then
  echo "FAIL: puller has the permissions '$ACTIONS'; it must have only repository:pull."
  exit 1
fi
echo "PASS: puller can only pull repositories in hub-private."
exit 0
