#!/bin/bash -i
set -e

echo -n "Enter your validator name: "
read NODE_MONIKER
CHAIN_ID=Cardchain

PEERS="56d11635447fa77163f31119945e731c55e256a4@45.136.28.158:26658"

echo  "Downloading Binary..."
curl https://get.ignite.com/DecentralCardGame/Cardchain@v0.81! | sudo bash

echo "Installing jq"
sudo apt-get install jq

echo  "Initializing Cardchain..."
Cardchain config chain-id $CHAIN_ID
Cardchain init $NODE_MONIKER --chain-id $CHAIN_ID

echo  "Getting Genesis file..."
cp $HOME/Testnet/genesis.json $HOME/.Cardchain/config/genesis.json


echo "Seting persistent peers..."
sed -i -e "/persistent_peers =/ s/= .*/= \"$PEERS\"/"  $HOME/.Cardchain/config/config.toml

Cardchain unsafe-reset-all

echo "Creating Service..."
sudo tee <<EOF >/dev/null /etc/systemd/system/Cardchaind.service
[Unit]
Description=Cardchain Daemon
After=network-online.target
[Service]
User=$USER
ExecStart=$(which Cardchain) start
Restart=always
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable Cardchaind
sudo systemctl restart Cardchaind

while [ "$(curl -s localhost:26657/status | jq ".result.sync_info.catching_up")" != "false" ]
do
	echo "Catching up. Sleeping for 1 minute."
	sleep 60
done

echo "Synchonized."

echo "Creating wallet..."
Cardchain config keyring-backend test
(Cardchain keys add validator) 2>&1 | tee $HOME/.Cardchain/config/validator_mnemonic

echo "Please ask in the validator channel in discrod for funds. Afterwards run ./Testnet/Cardchain_create_validator.sh to create your Validator."
