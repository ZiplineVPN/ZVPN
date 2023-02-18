#!/bin/bash
read -p "Username: " uservar #Read username
sudo adduser "$uservar" #Create the user
sudo adduser "$uservar" sudo #Add them to the sudo group
sshDir="/home/$uservar/.ssh" #declare their ssh dir
sudo mkdir -p "$sshDir" #create their ssh dir
sudo chmod 700 "$sshDir" #set the perms for their ssh dir
sudo chown -R "$uservar:$uservar" "$sshDir" #make sure they own their own ssh dir
#Disable password based ssh logins part 1
sudo sed -E -i 's|^#?(PasswordAuthentication)\s.*|\1 no|' /etc/ssh/sshd_config
#Disable part 2
if ! grep '^PasswordAuthentication\s' /etc/ssh/sshd_config; then echo 'PasswordAuthentication no' | sudo tee -a /etc/ssh/sshd_config; fi
#Update the system.
sudo nnw do update