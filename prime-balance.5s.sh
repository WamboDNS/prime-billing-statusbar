#!/bin/bash
# <bitbar.title>Prime Intellect Balance</bitbar.title>
# <bitbar.version>1.0.0</bitbar.version>
# <bitbar.desc>Shows current Prime Intellect wallet balance in the macOS menu bar.</bitbar.desc>
# <bitbar.dependencies>bash,curl,python3</bitbar.dependencies>

set -u

CONFIG_DIR="${PRIME_CONFIG_DIR:-$HOME/.config/prime-balance}"
LOGO_FILE="${CONFIG_DIR}/assets/prime-logo-template.png"
KEY_FILE="${CONFIG_DIR}/key"
ENDPOINT="https://api.primeintellect.ai/api/v1/billing/wallet"

if [[ -r "$LOGO_FILE" ]]; then
  LOGO_B64="$(base64 -i "$LOGO_FILE" | tr -d '\n')"
  ICON_PARAM="templateImage=${LOGO_B64}"
else
  ICON_PARAM=""
fi

if [[ -n "${PRIME_API_KEY:-}" ]]; then
  API_KEY="$PRIME_API_KEY"
elif [[ -r "$KEY_FILE" ]]; then
  API_KEY="$(cat "$KEY_FILE")"
else
  echo "prime: no key"
  echo "---"
  echo "API key missing. Save it to $KEY_FILE (chmod 600)."
  exit 0
fi

response=$(curl -sS --max-time 4 \
  -H "Authorization: Bearer $API_KEY" \
  -H "Accept: application/json" \
  "$ENDPOINT")
curl_exit=$?

if [[ $curl_exit -ne 0 || -z "$response" ]]; then
  echo "prime: —"
  echo "---"
  echo "Network error (curl exit $curl_exit)"
  echo "Refresh | refresh=true"
  exit 0
fi

parsed=$(/usr/bin/python3 -c '
import sys, json
raw = sys.stdin.read()
try:
    d = json.loads(raw)
    bal = float(d["balance_usd"])
    cur = d.get("currency", "USD")
    print(f"{bal:.2f} {cur}")
except Exception:
    print("ERR ERR")
' <<<"$response" 2>/dev/null)
read -r balance currency <<<"$parsed"

if [[ "$balance" == "ERR" || -z "$balance" ]]; then
  echo "prime: ?"
  echo "---"
  echo "Parse error. Raw response:"
  echo "$response" | head -c 400
  echo "Refresh | refresh=true"
  exit 0
fi

symbol="\$"
[[ "$currency" != "USD" ]] && symbol="$currency "

echo "${symbol}${balance} | ${ICON_PARAM}"
echo "---"
echo "Prime Intellect: ${symbol}${balance}"
echo "Updated: $(date '+%H:%M:%S')"
echo "---"
echo "Open billing dashboard | href=https://app.primeintellect.ai/dashboard/billing"
echo "Refresh now | refresh=true"
