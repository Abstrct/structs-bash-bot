#!/usr/bin/env bash

PLAYER_ID=$1
SLEEPER_LOG=60


PLAYER_BLOB=$(psql $DATABASE_URL -c "SELECT to_json(player.*) FROM view.player WHERE player.player_id = '${PLAYER_ID}';" --no-align -t)

PLAYER_GUILD_ID=$(echo ${PLAYER_BLOB} | jq -r ".guild_id")
PLAYER_USERNAME=$(echo ${PLAYER_BLOB} | jq -r ".username")
PLAYER_ADDRESS=$(echo ${PLAYER_BLOB} | jq -r ".primary_address")
PLAYER_ROLE_ID=$(psql $DATABASE_URL -c "SELECT id FROM signer.role WHERE role.player_id = '${PLAYER_ID}';" --no-align -t)

echo "[Player ${PLAYER_ID}] Beginning Monitoring ROLE_ID(${PLAYER_ROLE_ID})  GUILD_ID(${PLAYER_GUILD_ID}) USERNAME(${PLAYER_USERNAME}) ${PLAYER_ADDRESS}"

while true
do
  PLAYER_SUBSTATION_ID=$(echo ${PLAYER_BLOB} | jq -r ".substation_id")
  PLAYER_ORE=$(echo ${PLAYER_BLOB} | jq -r ".ore")
  PLAYER_LOAD=$(echo ${PLAYER_BLOB} | jq -r ".load")
  PLAYER_STRUCTS_LOAD=$(echo ${PLAYER_BLOB} | jq -r ".structs_load")
  PLAYER_CAPACITY=$(echo ${PLAYER_BLOB} | jq -r ".capacity")
  PLAYER_CONNECTION_CAPACITY=$(echo ${PLAYER_BLOB} | jq -r ".connection_capacity")

  echo "[Player ${PLAYER_ID}] Ore(${PLAYER_ORE}) Capacity(${PLAYER_CAPACITY}) ConnectionCapacity(${PLAYER_CONNECTION_CAPACITY} via ${PLAYER_SUBSTATION_ID}) Load(${PLAYER_LOAD}) StructsLoad(${PLAYER_STRUCTS_LOAD})"

  sleep $SLEEPER_LOG

  PLAYER_BLOB=$(psql $DATABASE_URL -c "SELECT to_json(player.*) FROM view.player WHERE player.player_id = '${PLAYER_ID}';" --no-align -t)
done
