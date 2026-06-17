#!/usr/bin/env bash
# Seed the 6 suenot GitHub repositories as project channels.
# Requires the backend API to be running and a valid JWT token.
#
# Usage:
#   export TOKEN="your_jwt_here"
#   ./scripts/seed_projects.sh
#
# Or read token from frontend localStorage (macOS):
#   export TOKEN=$(osascript -e 'tell application "Google Chrome" to execute javascript "localStorage.getItem('\"'\"'token'\"'\"')"' 2>/dev/null || echo "")

set -euo pipefail

API_URL="${API_URL:-http://localhost:8080}"
TOKEN="${TOKEN:-}"

if [[ -z "$TOKEN" ]]; then
  echo "Error: TOKEN env var is not set. Set it to a valid JWT from the frontend."
  exit 1
fi

repos=(
  "suenot/awesome-ccxt"
  "suenot/vasya"
  "suenot/profitmaker"
  "suenot/awesome-crypto-trading"
  "suenot/awesome-trading-terminal"
  "suenot/awesome-visual-programming"
)

for repo in "${repos[@]}"; do
  echo "Creating project: $repo ..."
  curl -s -X POST "${API_URL}/api/v1/channels" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -d "{\"platform\":\"github_repo\",\"handle\":\"${repo}\",\"url\":\"https://github.com/${repo}\"}" | cat
  echo ""
done

echo "Done. Projects will be fetched automatically by the scheduler."
