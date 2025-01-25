#!/usr/bin/env bash

REACTOR_ID=$1
SLEEPER_LOG=60

while true
do
  REACTOR_BLOB=$(psql $DATABASE_URL -c "SELECT to_json(reactor.*) FROM view.reactor WHERE reactor.reactor_id = '${REACTOR_ID}';" --no-align -t)

  REACTOR_FUEL=$(echo ${REACTOR_BLOB} | jq -r ".fuel")
  REACTOR_LOAD=$(echo ${REACTOR_BLOB} | jq -r ".load")
  REACTOR_CAPACITY=$(echo ${REACTOR_BLOB} | jq -r ".capacity")

  echo "[Reactor ${REACTOR_ID}]  Fuel: ${REACTOR_FUEL}"
  echo "[Reactor ${REACTOR_ID}]  Load/Capacity: ${REACTOR_LOAD}/${REACTOR_CAPACITY}"

  sleep $SLEEPER_LOG
done
