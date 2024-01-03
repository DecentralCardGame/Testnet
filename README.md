# Cardchain Testnet 8


## Installation

Execute the command below to join Testnet6. You only have to input your moniker into the console when promted to do so:

```
git clone https://github.com/DecentralCardGame/Testnet && chmod +x ./Testnet/Cardchain_install.sh && chmod +x ./Testnet/Cardchain_create_validator.sh && chmod +x ./Testnet/Cardchain_remove.sh && ./Testnet/Cardchain_install.sh
```

## Remove Cardchain

The following script will stop the systemd service, remove the Cardchain folder as well as the Cardchain binary:

```
./Testnet/Cardchain_remove.sh
```
