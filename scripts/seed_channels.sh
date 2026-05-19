#!/usr/bin/env bash
# Seed the popularity backend with the user's social channels (socials.md).
#
# Env:
#   AUTH_URL       — default https://auth.marketmaker.cc/api/v1
#   API_URL        — default http://localhost:8082
#   AUTH_EMAIL     — default suenot@gmail.com
#   AUTH_PASSWORD  — required (no default; pass via env, e.g. `AUTH_PASSWORD=... ./seed_channels.sh`)
set -euo pipefail

AUTH_URL="${AUTH_URL:-https://auth.marketmaker.cc/api/v1}"
API_URL="${API_URL:-http://localhost:8082}"
AUTH_EMAIL="${AUTH_EMAIL:-suenot@gmail.com}"
: "${AUTH_PASSWORD:?set AUTH_PASSWORD env var}"

command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }

echo "logging in as $AUTH_EMAIL → $AUTH_URL"
TOK=$(curl -fsS -X POST "$AUTH_URL/auth/login" \
        -H 'content-type: application/json' \
        -d "$(jq -n --arg e "$AUTH_EMAIL" --arg p "$AUTH_PASSWORD" '{email:$e,password:$p}')" \
      | jq -r .token)
if [ -z "$TOK" ] || [ "$TOK" = "null" ]; then
  echo "login failed" >&2; exit 1
fi

# platform | handle | url
CHANNELS=(
  "youtube|marketmaker-school-ru|https://www.youtube.com/@marketmaker-school-ru"
  "youtube|marketmaker-school|https://www.youtube.com/@marketmaker-school"
  "youtube|marketmaker-cc|https://www.youtube.com/@marketmaker-cc"
  "x|suenot|https://x.com/suenot"
  "facebook|soloviov.evgeniy|https://www.facebook.com/soloviov.evgeniy/"
  "telegram|suenot_dev|https://t.me/suenot_dev"
  "telegram|klavaorgwork|https://t.me/klavaorgwork"
  "telegram|klavaorg|https://t.me/klavaorg"
  "telegram|klavaorg_keyboards|https://t.me/klavaorg_keyboards"
  "telegram|marketmaker_cc|https://t.me/marketmaker_cc"
  "instagram|evgeniy.soloviov|https://www.instagram.com/evgeniy.soloviov/"
  "stackoverflow|937966/eugen-soloviov|https://stackoverflow.com/users/937966/eugen-soloviov"
  "linkedin|suenot|https://www.linkedin.com/in/suenot/"
  "habr|suenot|https://habr.com/ru/users/suenot/"
  "tbank_pulse|profit_maker|https://www.tbank.ru/invest/social/profile/profit_maker/?author=profile"
  "smartlab|suenot|https://smart-lab.ru/my/suenot/"
  "reddit|suenot|https://www.reddit.com/user/suenot/"
)

ok=0; fail=0
for row in "${CHANNELS[@]}"; do
  IFS='|' read -r platform handle url <<< "$row"
  payload=$(jq -n --arg p "$platform" --arg h "$handle" --arg u "$url" '{platform:$p,handle:$h,url:$u}')
  code=$(curl -s -o /tmp/seed_resp.json -w "%{http_code}" \
          -X POST "$API_URL/api/v1/channels" \
          -H 'content-type: application/json' \
          -H "authorization: Bearer $TOK" \
          -d "$payload")
  if [ "$code" = "201" ] || [ "$code" = "200" ]; then
    echo "  ok   $platform $handle"
    ok=$((ok+1))
  else
    echo "  FAIL $platform $handle → HTTP $code: $(cat /tmp/seed_resp.json)" >&2
    fail=$((fail+1))
  fi
done

echo "done: ok=$ok fail=$fail"
[ "$fail" = "0" ]
