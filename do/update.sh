#!/bin/bash
sudo apt update
export DEBIAN_FRONTEND=noninteractive 
sudo apt upgrade -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" -y 
sudo apt autoremove -y 
sudo apt autoclean -y 