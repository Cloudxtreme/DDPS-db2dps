#!/bin/bash

exec /usr/bin/socat stdout pipe:/var/run/exabgp/exabgp.cmd,perm-late=664
