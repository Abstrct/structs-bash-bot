#!/usr/bin/env bash

SUBSTATION_ID=$1
SLEEPER_LOG=60


while true
do
  SUBSTATION_LOAD=`echo ${SUBSTATION_BLOB} | jq -r ".Substation.load"`
  SUBSTATION_CAPACITY=`echo ${SUBSTATION_BLOB} | jq -r ".Substation.energy"`
  SUBSTATION_CONNECTION_CAPACITY=`echo ${SUBSTATION_BLOB} | jq -r ".Substation.playerConnectionAllocation"`
  SUBSTATION_CONNECTION_COUNT=$()
   load | capacity | connection_capacity | connection_count

  echo "[Substation ${SUBSTATION_ID}]  Load / Energy: $SUBSTATION_LOAD / $SUBSTATION_ENERGY"
  echo "[Substation ${SUBSTATION_ID}]  Player Allocation Size: $SUBSTATION_PLAYER_ALLOCATION"

  sleep $SLEEPER_LOG
done
