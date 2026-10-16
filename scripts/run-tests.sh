#!/usr/bin/env bash
#
# Builds the stack, runs smoke tests against it, and always tears down.
# Exit code: 0 if every test passed, non-zero otherwise.

set -Eeuo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"

on_error() {
  echo "ERROR: '$BASH_COMMAND' failed on line $1" >&2
}
trap 'on_error $LINENO' ERR

cleanup() {
  local rc=$?
  set +e
  if [[ $rc -ne 0 ]]; then
    echo "=== FAILED (exit $rc). Last logs: ==="
    docker compose logs --tail 30
  fi
  echo "=== Tearing down ==="
  docker compose down -v
  exit "$rc"
}
trap cleanup EXIT

check() {
  local name="$1"
  shift
  echo "--- $name"
  "$@"
  echo "    PASSED"
}

test_404() {
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/does-not-exist")
  if [[ "$code" != "404" ]]; then
    echo "    expected 404, got $code"
    return 1
  fi
}

test_api() {
  curl -fsS "$BASE_URL/api/hello" | grep -q "Hello from the backend"
}

echo "=== [1/3] Building images ==="
docker compose build

echo "=== [2/3] Starting the stack ==="
docker compose up -d --wait --wait-timeout 120

echo "=== [3/3] Smoke tests ==="
check "/health returns 200"       curl -fsS -o /dev/null "$BASE_URL/health"
check "nginx config is valid"     docker compose exec -T web nginx -t
check "home page returns 200"     curl -fsS -o /dev/null "$BASE_URL/"
check "unknown page returns 404"  test_404
check "API reaches the backend"   test_api

echo "=== ALL TESTS PASSED ==="
