#!/usr/bin/env bash
# PASS when library/alpine with the tag 3.22 is cached in the project dockerhub-proxy.
set -uo pipefail
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

# Harbor caches the platform images of a multi-platform pull at once, but the
# index with its tag 3.22 only when every image it lists is cached, or after
# 30 minutes (src/controller/proxy/manifestcache.go). So any cached artifact in
# library/alpine proves the pull went through the cache.
for _ in $(seq 1 24); do
  COUNT="$(harbor_api GET "/projects/dockerhub-proxy/repositories/library%252Falpine/artifacts?page_size=50" 2>/dev/null | json 'length' 2>/dev/null || echo 0)"
  if [ "${COUNT:-0}" -gt 0 ] 2>/dev/null; then echo "PASS: dockerhub-proxy/library/alpine holds $COUNT cached artifacts."; exit 0; fi
  sleep 5
done
echo "FAIL: dockerhub-proxy holds no cached library/alpine. Pull alpine:3.22 through the cache with the library/ prefix."
exit 1
