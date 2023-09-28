#!/usr/bin/env bash

# What should be the player name prefix
# read -r -e -p "Player Account Prefix:" -i "botplayer" PLAYER_ACCOUNT_PREFIX
PLAYER_ACCOUNT_PREFIX="guildlbotplayer"

# Minimum Alpha Amount to hold
#read -r -e -p "Minimum Alpha to Hold:" -i "3" ALPHA_MINIMUM_HOLD
ALPHA_MINIMUM_HOLD=300

# Minimum Infusion Size
#read -r -e -p "Minimum Infusion Size:" -i "5" ALPHA_MINIMUM_INFUSION
ALPHA_MINIMUM_INFUSION=5

# Which account is the guild leader?
#read -r -e -p "Guild Leader Account:" -i "guildleader" GUILD_LEADER_ACCOUNT
GUILD_LEADER_ACCOUNT="guildl"

# check the guild leader address
echo "Looking up the Guild Leader"
GUILD_LEADER_ACCOUNT_BLOB=`structsd keys show ${GUILD_LEADER_ACCOUNT} --output json`
GUILD_LEADER_ADDRESS=`echo ${GUILD_LEADER_ACCOUNT_BLOB} | jq -r ".address"`
echo "[Guild Leader] Player Address: $GUILD_LEADER_ADDRESS"

echo "Loading Guild Leader Player Account"
GUILD_LEADER_PLAYER_BLOB=`structsd query structs show-player --address ${GUILD_LEADER_ADDRESS} --output json`

GUILD_LEADER_PLAYER_ID=`echo ${GUILD_LEADER_PLAYER_BLOB} | jq -r ".Player.id"`
echo "[Guild Leader] Player ID: $GUILD_LEADER_PLAYER_ID"

echo "Loading Guild Details..."
GUILD_ID=`echo ${GUILD_LEADER_PLAYER_BLOB} | jq -r ".Player.guildId"`
GUILD_BLOB=`structsd query structs show-guild ${GUILD_ID} --output json`
GUILD_PRIMARY_REACTOR_ID=`echo ${GUILD_BLOB} | jq -r ".Guild.primaryReactorId"`
GUILD_ENTRY_SUBSTATION_ID=`echo ${GUILD_BLOB} | jq -r ".Guild.entrySubstationId"`

REACTOR_BLOB=`structsd query structs show-reactor ${GUILD_PRIMARY_REACTOR_ID} --output json`
REACTOR_ADDRESS=`echo ${REACTOR_BLOB} | jq -r ".Reactor.validator"`


echo "[Guild] ID: $GUILD_ID"
echo "[Guild] Reactor ID: $GUILD_PRIMARY_REACTOR_ID"
echo "[Guild] Reactor Address: $REACTOR_ADDRESS"
echo "[Guild] Substation ID: $GUILD_ENTRY_SUBSTATION_ID"

echo "Looking up Substation state"
SUBSTATION_BLOB=`structsd query structs show-substation ${GUILD_ENTRY_SUBSTATION_ID} --output json`
SUBSTATION_LOAD=`echo ${SUBSTATION_BLOB} | jq -r ".Substation.load"`
SUBSTATION_ENERGY=`echo ${SUBSTATION_BLOB} | jq -r ".Substation.energy"`
SUBSTATION_PLAYER_ALLOCATION=`echo ${SUBSTATION_BLOB} | jq -r ".Substation.playerConnectionAllocation"`

echo "[Substation] Load / Energy: $SUBSTATION_LOAD / $SUBSTATION_ENERGY"
echo "[Substation] Player Allocation Size: $SUBSTATION_PLAYER_ALLOCATION"


p=1000
# play loop
while true
do

  # check energy balance
  NEW_DESIRED_LOAD=$((SUBSTATION_LOAD+SUBSTATION_PLAYER_ALLOCATION));
  # can we fit a new player?
  if (( NEW_DESIRED_LOAD < SUBSTATION_ENERGY ))
     then
        p=$((p+1))

        # create the new player account locally
        NEW_PLAYER_ACCOUNT="$PLAYER_ACCOUNT_PREFIX$p"
        NEW_PLAYER_ACCOUNT_BLOB=`structsd keys add ${NEW_PLAYER_ACCOUNT} --output json`
        NEW_PLAYER_ADDRESS=`echo ${NEW_PLAYER_ACCOUNT_BLOB} | jq -r ".address"`
        NEW_PLAYER_MNEMONIC=`echo ${NEW_PLAYER_ACCOUNT_BLOB} | jq -r ".mnemonic"`
        echo $NEW_PLAYER_MNEMONIC >> ~/.droid_mnemonics

        echo "New Player Created"
        # create the new player account via proxy
        structsd tx structs player-create-proxy $NEW_PLAYER_ADDRESS --from $GUILD_LEADER_ACCOUNT --gas auto --yes
        sleep 10

        NEW_PLAYER_BLOB=`structsd query structs show-player --address ${NEW_PLAYER_ADDRESS} --output json`
        NEW_PLAYER_ID=`echo ${NEW_PLAYER_BLOB} | jq -r ".Player.id"`

        echo "[Player] ID: $NEW_PLAYER_ID"
        echo "[Player] Address: $NEW_PLAYER_ADDRESS"

        # pass off new player account to subdroidinate
        bash subdroidinate.sh "$NEW_PLAYER_ACCOUNT" "$NEW_PLAYER_ID" "$NEW_PLAYER_ADDRESS" "$GUILD_LEADER_ADDRESS" &
        sleep 10
  fi


  # check alpha balance
  ALPHA_BALANCE=`structsd query bank balances ${GUILD_LEADER_ADDRESS} --output json | jq -r ".balances[0].amount"`
  ALPHA_BALANCE_REQUIRED=$((ALPHA_MINIMUM_HOLD+ALPHA_MINIMUM_INFUSION))
  if (( ALPHA_BALANCE > ALPHA_BALANCE_REQUIRED ))
  then
      # delegate new amount to reactor
      DELEGATE_AMOUNT=$((ALPHA_BALANCE-ALPHA_MINIMUM_HOLD))"alpha"
      echo "Found $DELEGATE_AMOUNT, throwing it in the Reactor"
      structsd tx staking delegate $REACTOR_ADDRESS $DELEGATE_AMOUNT --from $GUILD_LEADER_ACCOUNT --gas auto --yes
      sleep 10
  fi

  SUBSTATION_BLOB=`structsd query structs show-substation ${GUILD_ENTRY_SUBSTATION_ID} --output json`
  SUBSTATION_LOAD=`echo ${SUBSTATION_BLOB} | jq -r ".Substation.load"`
  SUBSTATION_ENERGY=`echo ${SUBSTATION_BLOB} | jq -r ".Substation.energy"`
  SUBSTATION_PLAYER_ALLOCATION=`echo ${SUBSTATION_BLOB} | jq -r ".Substation.playerConnectionAllocation"`

  sleep 10

done
