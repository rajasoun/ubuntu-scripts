#!/usr/bin/env sh

# Ask for the user password
# Script only works if sudo caches the password for a few minutes
sudo true

# Install kernel extra's to enable docker aufs support
sudo apt-get -y install linux-image-extra-$(uname -r)

# Install docker
sudo bash -c "curl -sSL https://get.docker.com/"

# Install docker-compose
sudo sh -c "curl -L https://github.com/docker/compose/releases/download/1.4.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
sudo chmod +x /usr/local/bin/docker-compose
sudo sh -c "curl -L https://raw.githubusercontent.com/docker/compose/1.4.0/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose"

# Install docker-machine
sudo sh -c "curl -L https://github.com/docker/machine/releases/download/v0.4.0/docker-machine_linux-amd64 > /usr/local/bin/docker-machine"
sudo chmod +x /usr/local/bin/docker-machine

# Install docker-cleanup command
cd /tmp
git clone https://gist.github.com/76b450a0c986e576e98b.git
cd 76b450a0c986e576e98b
sudo mv docker-cleanup /usr/local/bin/docker-cleanup
sudo chmod +x /usr/local/bin/docker-cleanup
