#!/bin/bash

## Matamos el proceso
/sbin/start-stop-daemon --stop --name "nfs-cliente.sh"
#pkill nfs-cliente

## Desmontamos las unidades de red
/usr/bin/nfs-desmontajes.sh
