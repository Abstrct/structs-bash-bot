#!/usr/bin/env bash

SLEEPER_LOG=60

GUILD_ID=$1
SUBSTATION_ID=$2


while true
do
  # Check on Substation levels
  #$GROWN_CONNECTION_CAPACITY = Capacity / (Connect Count + 1)

  CONNECTION_CAPACITY_MINIMUM=$(cat ~/.structs_bash_bot/connection_capacity_minimum)
  if [[ $GROWN_CONNECTION_CAPACITY > $CONNECTION_CAPACITY_MINIMUM ]]; then


    # Create a new player

    insert into player_internal_pending(username, guild_id) values ('blahface', '0-1') returning *;
 username | guild_id | pfp | primary_address | role_id |          created_at           |          updated_at
----------+----------+-----+-----------------+---------+-------------------------------+-------------------------------
 blahface | 0-1      |     |                 |    1040 | 2025-01-24 21:18:00.935149+00 | 2025-01-24 21:18:00.935149+00

    # wait for play to exist

    # explore their planet


  fi

  sleep $SLEEPER_LOG
done
