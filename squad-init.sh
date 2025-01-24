#!/usr/bin/env bash



# Check to see if a squad exists
# a squad being a fairly prvileged roll that is
  # Guild - Association
  #


# Load Squad Details

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
