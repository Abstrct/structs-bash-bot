#!/usr/bin/env bash


SLEEPER_SQUAD_LEADER_INIT=20
SLEEPER_LOG=60



SQUAD_LEADER_PLAYER_ID=$(cat ~/.structs_bash_bot/squad_leader_player_id)
until [[ $SQUAD_LEADER_PLAYER_ID == 1-* ]];
do
  echo "Waiting for Squad Leader Initialization"
  sleep $SLEEPER_SQUAD_LEADER_INIT
  SQUAD_LEADER_PLAYER_ID=$(cat ~/.structs_bash_bot/squad_leader_player_id)
done



SQUAD_LEADER_BLOB=$(psql $DATABASE_URL -c "SELECT to_json(player.*) FROM view.player WHERE player.player_id = '${SQUAD_LEADER_PLAYER_ID}';" --no-align -t)

SQUAD_LEADER_GUILD_ID=$(echo ${SQUAD_LEADER_BLOB} | jq -r ".guild_id")
SQUAD_LEADER_USERNAME=$(echo ${SQUAD_LEADER_BLOB} | jq -r ".username")
SQUAD_LEADER_ADDRESS=$(echo ${SQUAD_LEADER_BLOB} | jq -r ".primary_address")
SQUAD_LEADER_ROLE_ID=$(psql $DATABASE_URL -c "SELECT id FROM signer.role WHERE role.player_id = '${SQUAD_LEADER_PLAYER_ID}';" --no-align -t)

echo "[Squad Leader] PLAYER_ID(${SQUAD_LEADER_PLAYER_ID}) ROLE_ID(${SQUAD_LEADER_ROLE_ID})  GUILD_ID(${SQUAD_LEADER_GUILD_ID}) USERNAME(${SQUAD_LEADER_USERNAME}) ${SQUAD_LEADER_ADDRESS}"


# Loading Guild Details...
GUILD_BLOB=$(psql $DATABASE_URL -c "SELECT to_json(guild.*) FROM structs.guild WHERE guild.id = '${SQUAD_LEADER_GUILD_ID}';" --no-align -t)
GUILD_ENTRY_SUBSTATION_ID=$(echo ${GUILD_BLOB} | jq -r ".entry_substation_id")
GUILD_PRIMARY_REACTOR_ID=$(echo ${GUILD_BLOB} | jq -r ".primary_reactor_id")



# Start the Monitors
monitor-player.sh ${SQUAD_LEADER_PLAYER_ID} &
monitor-reactor.sh ${GUILD_PRIMARY_REACTOR_ID} &
monitor-substation.sh ${GUILD_ENTRY_SUBSTATION_ID} &

# Build new agents
squad-growth.sh &

# Manage Squad Members - run squad-member.sh on available
squad-manager.sh &

# Manage Work
grunt-manager.sh &


while true
do
  echo "[Squad Leader] Doin things...."
  sleep $SLEEPER_LOG
done
