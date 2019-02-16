#!/bin/bash

# create a new user
sudo adduser --home /home/newuser newuser

# limit internet access of the new user
sudo iptables -A OUTPUT -m owner --uid-owner 1001 -s 192.168.0.0/255 -j ACCEPT
sudo iptables -A OUTPUT -m owner --uid-owner 1001 -s 127.0.0.0/8 -j ACCEPT
sudo iptables -A OUTPUT -m owner --uid-owner 1001 -j DROP
sudo iptables -A INPUT -m owner --uid-owner 1001 -s 192.168.0.0/255 -j ACCEPT
sudo iptables -A INPUT -m owner --uid-owner 1001 -s 127.0.0.0/8 -j ACCEPT
sudo iptables -A INPUT -m owner --uid-owner 1001 -j DROP

# save configuration
sudo iptables-save > /etc/iptables.conf

# use saved configuration after reboot
sudo iptables-restore < /etc/iptables.conf
