#!/bin/bash

/usr/bin/nfs-detener.sh

# Anterior...:
## Matamos el proceso
#/sbin/start-stop-daemon --oknodo --stop --name "nfs-cliente.sh" --retry=TERM/10/KILL/5

## Desmontamos las unidades de red (no sería necesario ya que se produce al salir antes)
#/usr/bin/nfs-desmontajes.sh
