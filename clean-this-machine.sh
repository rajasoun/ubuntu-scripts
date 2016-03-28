#!/usr/bin/env sh
sudo apt-get autoclean
sudo apt-get clean
sudo apt-get autoremove
sudo deborphan | xargs sudo apt-get -y remove --purge
