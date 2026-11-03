#!/usr/bin/env bash
# PASS when pull-vendor-tools is an enabled pull rule from the endpoint mirror that runs on the schedule 0 0 * * * *.
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

RULE="$(harbor_api GET "/replication/policies?page_size=100" | ws jq -c '.[] | select(.name=="pull-vendor-tools")')"
if [ -z "$RULE" ]; then
  echo "FAIL: there is no replication rule named pull-vendor-tools."
  exit 1
fi
ENABLED="$(printf '%s' "$RULE" | json '.enabled')"
TRIGGER="$(printf '%s' "$RULE" | json '.trigger.type')"
CRON="$(printf '%s' "$RULE" | json '.trigger.trigger_settings.cron // ""')"
SRC="$(printf '%s' "$RULE" | json '.src_registry.name // ""')"
DEST_REGISTRY="$(printf '%s' "$RULE" | json '.dest_registry.name // ""')"
if [ "$ENABLED" != "true" ]; then echo "FAIL: pull-vendor-tools is not enabled."; exit 1; fi
if [ "$SRC" != "mirror" ] || [ -n "$DEST_REGISTRY" ]; then
  echo "FAIL: pull-vendor-tools must pull from the endpoint mirror into this Harbor (source: '$SRC', destination endpoint: '$DEST_REGISTRY')."
  exit 1
fi
if [ "$TRIGGER" != "scheduled" ]; then echo "FAIL: pull-vendor-tools has the trigger '$TRIGGER'; it must be scheduled."; exit 1; fi
if [ "$CRON" != "0 0 * * * *" ]; then echo "FAIL: the schedule is '$CRON'; it must be '0 0 * * * *' (every hour, on the hour)."; exit 1; fi
echo "PASS: pull-vendor-tools is an enabled, hourly, pull-based rule from mirror."
exit 0
