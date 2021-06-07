#!/bin/bash
sudo echo "server {
    listen 80;
    server_name git.nicknet.works;

    location / {
        proxy_pass http://localhost:3000;
    }
}" > /etc/nginx/sites-available/git.nicknet.works
sudo ln -s /etc/nginx/sites-available/git.nicknet.works/ /etc/nginx/sites-enabled/