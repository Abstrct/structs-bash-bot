#!/usr/bin/env bash

SUBSTATION_ID=$1
SLEEPER_LOG=60

while true
do

  SUBSTATION_BLOB=$(psql $DATABASE_URL -c "SELECT to_json(substation.*) FROM view.substation WHERE substation.substation_id = '${SUBSTATION_ID}';" --no-align -t)

  SUBSTATION_LOAD=$(echo ${SUBSTATION_BLOB} | jq -r ".load")
  SUBSTATION_CAPACITY=$(echo ${SUBSTATION_BLOB} | jq -r ".capacity")
  SUBSTATION_CONNECTION_COUNT=$(echo ${SUBSTATION_BLOB} | jq -r ".connection_count")
  SUBSTATION_CONNECTION_CAPACITY=$(echo ${SUBSTATION_BLOB} | jq -r ".connection_capacity")

  echo "[Substation ${SUBSTATION_ID}]  Total Capacity: ${SUBSTATION_CAPACITY}"
  echo "[Substation ${SUBSTATION_ID}]  Allocation Load: ${SUBSTATION_LOAD}"
  echo "[Substation ${SUBSTATION_ID}]  Player Capacity: ${SUBSTATION_CONNECTION_CAPACITY} (${SUBSTATION_CONNECTION_COUNT} Connected)"

  sleep $SLEEPER_LOG
done
