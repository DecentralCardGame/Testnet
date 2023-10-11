#!/bin/bash -i
set -e

echo -n "Enter your validator name: "
read NODE_MONIKER
NODE_HOME=~/.cardchain
CHAIN_ID=cardtestnet-4
# CHAIN_REPO_URL='https://github.com/DecentralCardGame/Cardchain'
CHAIN_BINARY_URL='https://github.com/DecentralCardGame/Cardchain/releases/download/v0.9.0/Cardchaind'
# CHAIN_VERSION=
CHAIN_BINARY='cardchaind'
GENESIS_URL='http://45.136.28.158:3000/genesis.json'
SEEDS=""
PEERS="1ed98c796bcdd0faf5a7ad8793d229e3c7d89543@lxgr.xyz:26656"
SNAP_RPC="http://lxgr.xyz:26657"

# Install go 1.20.2
# echo "Installing go..."
# wget -q -O - https://git.io/vQhTU | bash -s -- --remove
# wget -q -O - https://git.io/vQhTU | bash -s -- --version 1.20.2
# source $shell_profile

# install from source
# echo "Installing build-essential..."
# sudo apt install build-essential -y
# echo "Installing Cardchain..."
# rm -rf Cardchain
# git clone $CHAIN_REPO_URL
# cd Cardchain
# git checkout $CHAIN_VERSION
# make install

echo  "Downloading Binary..."
wget $CHAIN_BINARY_URL -O $HOME/go/bin/$CHAIN_BINARY
chmod 775 $HOME/go/bin/$CHAIN_BINARY

export PATH=$PATH:$HOME/go/bin

echo "Installing jq"
sudo apt-get install jq

echo  "Initializing Cardchain..."
rm -rf $NODE_HOME
$CHAIN_BINARY config chain-id $CHAIN_ID
$CHAIN_BINARY init $NODE_MONIKER --chain-id $CHAIN_ID --home $NODE_HOME

echo  "Copy Genesis file..."
wget $GENESIS_URL -O $NODE_HOME/config/genesis.json

echo "Seting persistent peers..."
sed -i -e "/persistent_peers =/ s/= .*/= \"$PEERS\"/"  $NODE_HOME/config/config.toml

echo "Setting up cosmovisor..."
mkdir -p $NODE_HOME/cosmovisor/genesis/bin
cp $(which $CHAIN_BINARY) $NODE_HOME/cosmovisor/genesis/bin
chmod 775 $NODE_HOME/cosmovisor/genesis/bin/$CHAIN_BINARY

echo "Installing cosmovisor..."
export BINARY=$NODE_HOME/cosmovisor/genesis/bin/$CHAIN_BINARY
export GO111MODULE=on
go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0

#sudo rm /etc/systemd/system/cosmovisor.service
sudo touch /etc/systemd/system/cosmovisor.service

echo "[Unit]"                               | sudo tee /etc/systemd/system/cosmovisor.service
echo "Description=Cosmovisor service"       | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/cosmovisor.service -a
echo ""                                     | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "[Service]"                            | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "User=$USER"                            | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "ExecStart=$HOME/go/bin/cosmovisor start --x-crisis-skip-assert-invariants --home $NODE_HOME" | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "Restart=always"                       | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "RestartSec=3"                         | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "Environment='DAEMON_NAME=$CHAIN_BINARY'"      | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "Environment='DAEMON_HOME=$NODE_HOME'" | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "Environment='DAEMON_ALLOW_DOWNLOAD_BINARIES=true'" | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "Environment='DAEMON_RESTART_AFTER_UPGRADE=true'" | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "Environment='DAEMON_LOG_BUFFER_SIZE=512'" | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "Environment='UNSAFE_SKIP_BACKUP=true'" | sudo tee /etc/systemd/system/cosmovisor.service -a
echo ""                                     | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "[Install]"                            | sudo tee /etc/systemd/system/cosmovisor.service -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/cosmovisor.service -a

echo "Setting up statesync..."
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
echo $LATEST_HEIGHT
BLOCK_HEIGHT=$((LATEST_HEIGHT)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
echo -e "\033[0;36mlatest height: $LATEST_HEIGHT \nblock height: $BLOCK_HEIGHT \ntrust hash: $TRUST_HASH \033[0m"

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $NODE_HOME/config/config.toml; \

echo "Configuring pruning"
indexer="null"
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"

sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $NODE_HOME/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $NODE_HOME/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $NODE_HOME/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $NODE_HOME/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $NODE_HOME/config/app.toml

echo "Starting cosmovisor.service..."
sudo systemctl daemon-reload
sudo systemctl start cosmovisor.service
sudo systemctl restart systemd-journald

while [ "$(curl -s localhost:26657/status | jq ".result.sync_info.catching_up")" != "false" ]
do
	echo "Catching up. Sleeping for 1 minute."
	sleep 60
done

echo "Synchonized."

echo "Creating wallet..."
$CHAIN_BINARY config keyring-backend test
($CHAIN_BINARY keys add validator) 2>&1 | tee $NODE_HOME/config/validator_mnemonic

echo "Please use the faucet on our website to get some funds. Afterwards run ./Testnet/Cardchain_create_validator.sh to create your Validator."
