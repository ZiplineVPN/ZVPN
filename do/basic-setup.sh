#!/bin/bash
read -p "Username: " uservar #Read username
sudo adduser "$uservar" #Create the user
sudo adduser "$uservar" sudo #Add them to the sudo group
sshDir="/home/$uservar/.ssh" #declare their ssh dir
sudo mkdir -p "$sshDir" #create their ssh dir
sudo chmod 700 "$sshDir" #set the perms for their ssh dir
sudo chown -R "$uservar:$uservar" "$sshDir" #make sure they own their own ssh dir
#Import my ssh public key
sudo echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCb21rB7wz6sIOnPDX9YVzR7L+FfbN4l9fnvbE5bz1WdWi1841eklO4mEexU0ndcs9g9EoSiz3OPiXhDkAC6xFCFV74YRnAUEhsQaeCATFC9r3U19tetKSR9d1DrT8xyDGAzbhLnrv3ouhh/RfeGQPfuP7jiXT/99qmlYaBYUMrYA5jGPDN1QqLrULt73ZGGG9Ewn1WLMWasya9NG9ZAR5tkei9sLhz4K1RaKMVyrIoKCWniU9kVUO4jBwMXaKFhtJ48ohD/USU+T2ez7vo+kZoXNq/I1q3OtYoh2d3gb3pmr1gJTLinuRAf4dyTfAtpLmpBZJ0PU3sinB4u2d7jGqm9szvcH7i0yayEGH1wrapfRduJJXYbObf5noSPiceBla1dNCHYrnJCFxozteerztVP86kH6TdEHByEgNzNtWV1VPYbhMJ5zhydEUYwRRpZKSjwTfaYwTiHiLPMEcv76l9q1R3TYppEzaTc9sf9IQDrXZhQzj9cmXvLEDhA/3Ux7s= nackloose@nackbuntu" >> "$sshDir/authorized_keys"
#Disable password based ssh logins part 1
sudo sed -E -i 's|^#?(PasswordAuthentication)\s.*|\1 no|' /etc/ssh/sshd_config
#Disable part 2
if ! grep '^PasswordAuthentication\s' /etc/ssh/sshd_config; then echo 'PasswordAuthentication no' | sudo tee -a /etc/ssh/sshd_config; fi
#Update the system.
sudo nnw do update