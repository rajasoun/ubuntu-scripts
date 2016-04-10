#!/usr/bin/env sh
ip addr show eth0 | grep inet | grep global | awk '{ print $2; }' | sed 's/\/.*$//'
