#!/bin/bash -i
set -e

read -p "This will delete your priv_validator_key and wallet. Continue (y)? " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

echo "Stopping/Removing Service"
sudo systemctl stop cosmovisor.service
sudo rm /etc/systemd/system/cosmovisor.service

echo "Deleting .Cardchain folder"
sudo rm -r $HOME/.cardchaind/

echo "Deleting binary"
sudo rm /go/bin/cardchaind

