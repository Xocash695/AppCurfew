#
//  addingAppsTest.sh
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-07-01.
//

#!/bin/bash

BASE_URL="http://localhost:8080"
API_KEY="ICEK8+vr9VMqzYrZN9ZSf1YJxEa5VU/O7eyemZXI2D8=" // just a testing api key not an api key that is used in production

echo "=== Report Installed Apps (as existing child) ==="
curl -s -X POST "$BASE_URL/installed-apps" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"apps":[{"id":"com.valvesoftware.Steam","name":"Steam"},{"id":"com.discordapp.Discord","name":"Discord"},{"id":"org.mozilla.firefox","name":"Firefox"},{"id":"com.spotify.Client","name":"Spotify"}]}'
echo ""
echo "(expect HTTP 200 with empty body)"
echo ""

echo "=== Check Allowed Apps (sanity check the key works) ==="
curl -s -X GET "$BASE_URL/allowed-apps" \
  -H "Authorization: Bearer $API_KEY"
echo ""
