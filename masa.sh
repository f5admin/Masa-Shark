#!/bin/bash

. <(wget -qO- https://raw.githubusercontent.com/f5nodes/logo/main/logo-shark.sh)

sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu net-tools -y

gover="1.17.2"
cd $HOME
wget "https://golang.org/dl/go$gover.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$gover.linux-amd64.tar.gz"
rm "go$gover.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version

cd $HOME
rm -rf masa-node-v1.0
git clone https://github.com/masa-finance/masa-node-v1.0

cd masa-node-v1.0/src
git checkout v1.03
make all

cd $HOME/masa-node-v1.0/src/build/bin
sudo cp * /usr/local/bin

cd $HOME/masa-node-v1.0
geth --datadir data init ./network/testnet/genesis.json

read -p 'Nodename: ' MASA_NODENAME

tee $HOME/masad.service > /dev/null <<EOF
[Unit]
Description=MASA103
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which geth) \
  --identity ${MASA_NODENAME} \
  --datadir $HOME/masa-node-v1.0/data \
  --port 30300 \
  --syncmode full \
  --verbosity 5 \
  --emitcheckpoints \
  --istanbul.blockperiod 10 \
  --mine \
  --miner.threads 1 \
  --networkid 190260 \
  --http --http.corsdomain "*" --http.vhosts "*" --http.addr 127.0.0.1 --http.port 8545 \
  --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul \
  --maxpeers 50 \
  --bootnodes enode://136ae18de4e57e15e7dc70b03d59db11e77ae45de8ba89a243734b911b94477a3fa515d8a494c1ea79b97e134a17f04db9ff4e90e09e1c2bdba3e9aa061bf6ae@185.167.120.159:30300
Restart=on-failure
RestartSec=10
LimitNOFILE=4096
Environment="PRIVATE_CONFIG=ignore"
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/masad.service /etc/systemd/system

sudo systemctl daemon-reload
sudo systemctl enable masad
sudo systemctl restart masad

echo -e "\n\e[93mMasa Finance Testnet\e[0m\n"
echo -e "Подивитись логи ноди \e[92mjournalctl -u masad -f -o cat\e[0m"
echo -e "\e[92mCTRL + C\e[0m щоб вийти з логів\n"
echo -e "Зайти в меню ноди \e[92mgeth attach ipc:$HOME/masa-node-v1.0/data/geth.ipc\e[0m"
echo -e "Параметри меню:"
echo -e "\e[92meth.syncing\e[0m - подивитись статус синхронізації"
echo -e "\e[92mnet.peerCount\e[0m - подивитись кількість пірів"
echo -e "\e[92mCTRL + D\e[0m щоб вийти з меню"
