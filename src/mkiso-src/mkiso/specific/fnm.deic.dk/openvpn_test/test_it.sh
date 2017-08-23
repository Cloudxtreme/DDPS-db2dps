#!/bin/sh

echo "My external ip address is:"
dig +short myip.opendns.com @resolver1.opendns.com
