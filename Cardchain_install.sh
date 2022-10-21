#!/bin/bash -i
set -e

echo -n "Enter your validator name: "
read NODE_MONIKER
CHAIN_ID=Testnet3
PEERS="56d11635447fa77163f31119945e731c55e256a4@45.136.28.158:26658, 72b662370d2296a22cad1eecbe447012dd3c2a89@65.21.151.93:36656,b17b995cf2fcff579a4b4491ca8e05589c2d8627@195.54.41.130:36656,d692726a2bdeb0e371b42ef4fa6dfaa47a1c5ad4@38.242.250.15:26656,f1d8bede57e24cb6e5258da1e4f17b1c5b0a0ca3@173.249.45.161:26656,959f9a742058ff591a5359130a392bcccf5f11a5@5.189.165.127:18656,56ff9898493787bf566c68ede80febb76a45eedc@23.88.77.188:20004,96821b39e381e293a251c860c58a2d9e85435363@49.12.245.142:13656,638240b94ac3da7d8c8df8ae4da72a7d920acf2a@173.212.245.44:26656,b41f7ce40c863ee7e20801e6cd3a97237a79114a@65.21.53.39:16656,5d2bb1fed3f93aed0ba5c96bff4b0afb31d9501d@130.185.119.10:26656"

echo  "Downloading Binary..."
wget https://github.com/DecentralCardGame/Cardchain/releases/download/v0.81/Cardchain_latest_linux_amd64.tar.gz
tar xzf Cardchain_latest_linux_amd64.tar.gz
chmod 775 Cardchaind
sudo mv Cardchaind /usr/local/bin/
sudo rm Cardchain_latest_linux_amd64.tar.gz

echo "Installing jq"
sudo apt-get install jq

echo  "Initializing Cardchain..."
Cardchaind config chain-id $CHAIN_ID
Cardchaind init $NODE_MONIKER --chain-id $CHAIN_ID

echo  "Getting Genesis file..."
cp $HOME/Testnet/genesis.json $HOME/.Cardchain/config/genesis.json


echo "Seting persistent peers..."
sed -i -e "/persistent_peers =/ s/= .*/= \"$PEERS\"/"  $HOME/.Cardchain/config/config.toml

Cardchaind unsafe-reset-all

echo "Creating Service..."
sudo tee <<EOF >/dev/null /etc/systemd/system/Cardchaind.service
[Unit]
Description=Cardchain Daemon
After=network-online.target
[Service]
User=$USER
ExecStart=$(which Cardchaind) start
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
