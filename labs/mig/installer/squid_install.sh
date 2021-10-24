#! /bin/bash
sudo apt-get update
sudo apt-get install -y squid
sudo sed -i 's:#\(http_access allow localnet\):\1:' /etc/squid/squid.conf
sudo sed -i 's:#\(http_access deny to_localhost\):\1:' /etc/squid/squid.conf
sudo sed -i 's:#\(acl localnet src 10.0.0.0/8.*\):\1:' /etc/squid/squid.conf
sudo sed -i 's:#\(acl localnet src 172.16.0.0/12.*\):\1:' /etc/squid/squid.conf
sudo sed -i 's:#\(acl localnet src 192.168.0.0/16.*\):\1:' /etc/squid/squid.conf
sudo sed -i 's:#\(http_access allow all):\1:' /etc/squid/squid.conf
sudo service squid start