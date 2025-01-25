#!/usr/bin/env bash

SLEEPER_LOG=60
SLEEPER_ROLE_CREATION=60

SQUAD_LEADER_PLAYER_ID=$1
GUILD_ID=$2
SUBSTATION_ID=$3


while true
do
  # Check on Substation levels
  GROWN_CONNECTION_CAPACITY=$(psql $DATABASE_URL -c "SELECT capacity / (connection_count + 1) FROM view.substation WHERE substation_id = '${SUBSTATION_ID}' ;" --no-align -t)

  CONNECTION_CAPACITY_MINIMUM=$(cat ~/.structs_bash_bot/connection_capacity_minimum)
  if [[ $GROWN_CONNECTION_CAPACITY > $CONNECTION_CAPACITY_MINIMUM ]]; then

    echo "[Squad Growth] Creating new Employee"

    # find an acceptable name
    NAME_POSTFIX=$(head /dev/urandom | tr -dc A-Z0-9 | head -c4)
    until [[ $(psql $DATABASE_URL -c "SELECT COUNT(1) FROM structs.player_meta WHERE player_meta.guild_id='${GUILD_ID}' AND player_meta.username='INT-${NAME_POSTFIX}';" --no-align -t) == 0 ]];
    do
      NAME_POSTFIX=$(head /dev/urandom | tr -dc A-Z0-9 | head -c4)
    done

    # Create a new player
    PLAYER_PENDING_ROLE_ID=$(psql $DATABASE_URL -c "insert into structs.player_internal_pending(username, guild_id) values ('INT-${NAME_POSTFIX}', '${GUILD_ID}') returning role_id;" --no-align -t)

    # wait for play to exist
    until [[ $(psql $DATABASE_URL -c "SELECT COUNT(1) FROM structs.player_meta WHERE player_meta.guild_id='${GUILD_ID}' AND player_meta.username='INT-${NAME_POSTFIX}';" --no-align -t) == 0 ]];
    do
      sleep $SLEEPER_ROLE_CREATION
    done

    PLAYER_ID=$(psql $DATABASE_URL -c "SELECT player_meta.id FROM structs.player_meta WHERE player_meta.guild_id='${GUILD_ID}' AND player_meta.username='INT-${NAME_POSTFIX}';" --no-align -t)

    echo "[Squad Growth] Adding Squad Leader (${SQUAD_LEADER_PLAYER_ID}) to Player Permissions (${PLAYER_ID})"
    # Add Squad Leader Permissions
    psql $DATABASE_URL -c "SELECT signer.CREATE_TRANSACTION('${PLAYER_ID}', 127, 'permission-grant-on-object', jsonb_build_array('${PLAYER_ID}','${SQUAD_LEADER_PLAYER_ID}',127), jsonb_build_array());" --no-align -t)


    # Explore Planet
    echo "[Squad Growth] Exploring Planet for new Player (${PLAYER_ID})"
    psql $DATABASE_URL -c "SELECT signer.CREATE_TRANSACTION('${PLAYER_ID}', 1, 'planet-explore', jsonb_build_array(), jsonb_build_array());" --no-align -t)

  fi

  sleep $SLEEPER_LOG
done
