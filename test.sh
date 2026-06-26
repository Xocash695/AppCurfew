#!/bin/bash

BASE_URL="http://0.0.0.0:8080"
USERNAME="testuser_$(date +%s)"
PASSWORD="secret123"

echo "=== Register ($USERNAME) ==="
curl -s -X POST "$BASE_URL/register" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Akash\",\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"confirmPassword\":\"$PASSWORD\"}"
echo ""
echo ""

echo "=== Login ==="
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/login" -u "$USERNAME:$PASSWORD")
echo "$LOGIN_RESPONSE"
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.value')
echo "Token: $TOKEN"
echo ""

echo "=== Create Child ==="
CHILD_RESPONSE=$(curl -s -X POST "$BASE_URL/children" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Timmy"}')
echo "$CHILD_RESPONSE"

CHILD_ID=$(echo "$CHILD_RESPONSE" | jq -r '.id')
API_KEY=$(echo "$CHILD_RESPONSE" | jq -r '.apiKey')
echo "Child ID: $CHILD_ID"
echo "API Key: $API_KEY"
echo ""

echo "=== Add Allowed App (60 second daily limit) ==="
curl -s -X POST "$BASE_URL/children/$CHILD_ID/allowed-apps" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"appIdentifier":"com.valvesoftware.steam","dailyLimitSeconds":60}'
echo ""
echo ""

echo "=== Check Allowed Apps (as child) — should show steam ==="
curl -s -X GET "$BASE_URL/allowed-apps" \
  -H "Authorization: Bearer $API_KEY"
echo ""
echo ""

echo "=== Report 60 Seconds Of Usage ==="
curl -s -X POST "$BASE_URL/usage-report" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"appIdentifier":"com.valvesoftware.steam","secondsUsed":60}'
echo ""
echo ""

echo "=== Check Allowed Apps Again — should now be EMPTY ==="
curl -s -X GET "$BASE_URL/allowed-apps" \
  -H "Authorization: Bearer $API_KEY"
echo ""
