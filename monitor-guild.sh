#!/usr/bin/env bash

PLAYER_ID=$1

SLEEPER_LOG=60



# Minimum Alpha Amount to hold
ALPHA_MINIMUM_HOLD=300

# Minimum Infusion Size
ALPHA_MINIMUM_INFUSION=5

SQUAD_LEADER_ROLE_ID=$()
SQUAD_LEADER_PLAYER_ID=$()
SQUAD_LEADER_GUILD_ID=$()
SQUAD_LEADER_USERNAME=$()
SQUAD_LEADER_ADDRESS=$()

echo "[Squad Leader] PLAYER_ID(${SQUAD_LEADER_PLAYER_ID}) ROLE_ID(${SQUAD_LEADER_ROLE_ID})  GUILD_ID(${SQUAD_LEADER_GUILD_ID}) USERNAME(${SQUAD_LEADER_USERNAME}) ${SQUAD_LEADER_ADDRESS}"


# "Loading Guild Details..."


GUILD_ENTRY_SUBSTATION_ID=`echo ${GUILD_BLOB} | jq -r ".Guild.entrySubstationId"`

GUILD_PRIMARY_REACTOR_ID=`echo ${GUILD_BLOB} | jq -r ".Guild.primaryReactorId"`
GUILD_PRIMARY_REACTOR_ADDRESS=`echo ${REACTOR_BLOB} | jq -r ".Reactor.validator"`
fuel | load | capacity |                       validator



echo "[Squad Leader] Reactor ID: ${GUILD_REACTOR_ID}"
echo "[Squad Leader] Reactor Address: ${GUILD_REACTOR_ADDRESS}"



echo "[Squad Leader] Entry Substation ID: ${GUILD_ENTRY_SUBSTATION_ID}"
SUBSTATION_LOAD=`echo ${SUBSTATION_BLOB} | jq -r ".Substation.load"`
SUBSTATION_ENERGY=`echo ${SUBSTATION_BLOB} | jq -r ".Substation.energy"`
SUBSTATION_PLAYER_ALLOCATION=`echo ${SUBSTATION_BLOB} | jq -r ".Substation.playerConnectionAllocation"`
 load | capacity | connection_capacity | connection_count

echo "[Substation] Load / Energy: $SUBSTATION_LOAD / $SUBSTATION_ENERGY"
echo "[Substation] Player Allocation Size: $SUBSTATION_PLAYER_ALLOCATION"

# Start the Monitors
monitor-role.sh &
monitor-guild.sh &
monitor-reactor.sh &
monitor-substation.sh &

# Build new agents
squad-growth.sh &

# Manage Squad Members - run squad-member.sh on available
squad-Manager.sh &

while true
do
  echo "[Squad Leader] Doin things...."
  sleep $SLEEPER_LOG
done
