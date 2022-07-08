#!/bin/bash -i
set -e

read -p "This will delete your priv_validator_key and wallet. Continue (y)? " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

echo "Stopping/Removing Service"
sudo systemctl stop Cardchaind
sudo rm /etc/systemd/system/Cardchaind.service

echo "Deleting .Cardchain folder"
sudo rm -r $HOME/.Cardchain/

echo "Deleting binary"
sudo rm /usr/local/bin/Cardchain
