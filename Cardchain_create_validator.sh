#!/bin/bash -i

echo -n "Enter your validator name: "
read NODE_MONIKER
CHAIN_ID=cardtestnet-9

echo "Create Validator..."
cardchaind tx staking create-validator \
  --from=validator \
  --amount=1000000ubpf \
  --moniker=$NODE_MONIKER \
  --chain-id=$CHAIN_ID \
  --commission-rate=0.1 \
  --commission-max-rate=0.5 \
  --commission-max-change-rate=0.1 \
  --min-self-delegation=1 \
  --pubkey=$(cardchaind tendermint show-validator) \
  --details="" \
  --yes
