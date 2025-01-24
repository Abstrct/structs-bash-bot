#!/usr/bin/env bash

# Usage [Account] [ID] [Address] [Guild Leader Address]

PLAYER_ACCOUNT=$1
PLAYER_ID=$2
PLAYER_ADDRESS=$3
GUILD_LEADER_ADDRESS=$4

echo "Subdroidinate Powering On"

HAS_MINE=false
HAS_REFINERY=false

MINE_ACTIVE=false
REFINERY_ACTIVE=false

while true
do
  sleep 10

  PLAYER_BLOB=`structsd query structs player ${PLAYER_ID} --output json`

  PLANET_ID=`echo ${PLAYER_BLOB} | jq -r ".Player.planetId"`

  if  (( PLANET_ID == 0 ))
  then

      echo "Doin a dirty hack to fix offline planet explore bug"
      structsd tx structs player-update-primary-address $PLAYER_ADDRESS --from $PLAYER_ACCOUNT --yes --gas auto
      sleep 10

      echo "Exploring a Planet..."
      structsd tx structs planet-explore --from $PLAYER_ACCOUNT --yes --gas auto
      sleep 10

      PLAYER_BLOB=`structsd query structs player ${PLAYER_ID} --output json`
      PLANET_ID=`echo ${PLAYER_BLOB} | jq -r ".Player.planetId"`
      echo "[Planet] ID: $PLANET_ID"
  fi

  if ! $HAS_MINE;
  then
    echo "Initiating Build of Mining Rig"
    structsd tx structs struct-build-initiate "Mining Rig" $PLANET_ID 1 --from $PLAYER_ACCOUNT --yes --gas auto
    sleep 10

    PLANET_BLOB=`structsd query structs planet ${PLANET_ID} --output json`
    MINE_ID=`echo ${PLANET_BLOB} | jq -r ".Planet.land[1]"`

    echo "Trying to Complete Mining Rig #$MINE_ID"
    structsd tx structs struct-build-compute $MINE_ID --difficulty_target_start 3  --from $PLAYER_ACCOUNT --yes --gas auto
    sleep 10
    HAS_MINE=true
  fi

  if ! $HAS_REFINERY;
  then
    echo "Initiating Build of Refinery"
    structsd tx structs struct-build-initiate "Refinery" $PLANET_ID 2 --from $PLAYER_ACCOUNT --yes --gas auto
    sleep 10

    PLANET_BLOB=`structsd query structs planet ${PLANET_ID} --output json`
    REFINERY_ID=`echo ${PLANET_BLOB} | jq -r ".Planet.land[2]"`

    echo "Trying to Complete Refinery #$REFINERY_ID"
    structsd tx structs struct-build-compute $REFINERY_ID --difficulty_target_start 3 --from $PLAYER_ACCOUNT --yes --gas auto
    sleep 10
    HAS_MINE=true
  fi

  PLANET_BLOB=`structsd query structs planet ${PLANET_ID} --output json`
  PLANET_ORE_REMAINING=`echo ${PLANET_BLOB} | jq -r ".Planet.OreRemaining"`

  if (( PLANET_ORE_REMAINING > 0 ))
  then
    echo "Activating the Mining Rig"
    structsd tx structs struct-mine-activate $MINE_ID --from $PLAYER_ACCOUNT --yes --gas auto
    sleep 10

    echo "Do the dig for #$MINE_ID"
    structsd tx structs struct-mine-compute $MINE_ID --difficulty_target_start 3 --from $PLAYER_ACCOUNT --yes --gas auto
    sleep 10
  fi

  PLANET_BLOB=`structsd query structs planet ${PLANET_ID} --output json`
  PLANET_ORE_STORED=`echo ${PLANET_BLOB} | jq -r ".Planet.OreStored"`

  if (( PLANET_ORE_STORED > 0 ))
  then
    echo "Activating the Refinery"
    structsd tx structs struct-refine-activate $REFINERY_ID --from $PLAYER_ACCOUNT --yes --gas auto
    sleep 10

    echo "Do the dig for #$REFINERY_ID"
    structsd tx structs struct-refine-compute $REFINERY_ID --difficulty_target_start 3 --from $PLAYER_ACCOUNT --yes --gas auto
    sleep 10
  fi

  PLANET_BLOB=`structsd query structs planet ${PLANET_ID} --output json`
  PLANET_ORE_STORED=`echo ${PLANET_BLOB} | jq -r ".Planet.OreStored"`
  PLANET_ORE_REMAINING=`echo ${PLANET_BLOB} | jq -r ".Planet.OreRemaining"`

  if (( PLANET_ORE_STORED == 0 ))
  then
    if (( PLANET_ORE_REMAINING == 0 ))
    then
        echo "Exploring a Planet..."
        structsd tx structs planet-explore --from $PLAYER_ACCOUNT --yes --gas auto
        sleep 10

        PLAYER_BLOB=`structsd query structs player ${PLAYER_ID} --output json`
        PLANET_ID=`echo ${PLAYER_BLOB} | jq -r ".Player.planetId"`
        echo "[Planet] ID: $PLANET_ID"

        HAS_MINE=false
        HAS_REFINERY=false
    fi
  fi

  ALPHA_BALANCE=`structsd query bank balances ${PLAYER_ADDRESS} --output json | jq -r ".balances[0].amount"`
  if (( ALPHA_BALANCE > 0 ))
  then
    echo "Sending Alpha to Overlord"
    SEND_AMOUNT=$((ALPHA_BALANCE))"alpha"
    structsd tx bank send $PLAYER_ACCOUNT $GUILD_LEADER_ADDRESS $SEND_AMOUNT  -y --gas auto
    sleep 10
  fi
done