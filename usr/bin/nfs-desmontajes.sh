#!/bin/bash

## Comenzamos importando y definiendo las variables que usaremos posteriormente:
. /etc/default/vx-dga-variables/vx-dga-variables-general.conf

for RECURSO in $( cat /etc/mtab | grep "^${IPCACHE}" | cut -d" " -f2) ; do
	if sudo umount -lf ${RECURSO} ; then
		rmdir --ignore-fail-on-non-empty ${RECURSO}
	fi
done

# Paramos el servicio nfs-cliente
##start-stop-daemon --stop --oknodo --name "nfs-cliente.sh" --pidfile /run/nfs-cliente.pid

# Matamos el proceso encargado del montaje de las unidades de red NFS si esta activo
if PIDNFS=$(pgrep nfs-cliente) ; then
	pgrep nfs-cliente | xargs kill -1
	pgrep nfs-cliente | xargs kill -9
fi
#if ps -auxf | grep nfs-cliente.sh &> /dev/null ;  then
#	killall nfs-cliente.sh
#fi

# Eliminamos los puntos de montaje del fstab
RUTAMONTAJES="/usr/share/vitalinux/nfs-compartir/nfs-recursos"
if test -f ${RUTAMONTAJES} ; then
	for LINEA in $(cat $RUTAMONTAJES | sed "/^#.*/d" | sed "/^$/d" | tr -s " " "*") ; do
		RECURSO=$(echo $LINEA | tr -s "*" " ")
		RECURSOREMOTO=$(echo $RECURSO | cut -d":" -f1)
		CARPETAMONTAJE=$(echo $RECURSO | cut -d":" -f2)
		MODOMONTAJE=$(echo $RECURSO | cut -d":" -f5)
		if ( test "${MODOMONTAJE}" = "fstab" ) \
			&& (grep "^$IPCACHE:$RECURSOREMOTO" /etc/fstab &> /dev/null) ; then
			sed --follow-symlinks -i "\#^${IPCACHE}:${RECURSOREMOTO}.*#d" /etc/fstab
		fi
	done
	# Limpiamos el /etc/fstab
	sed --follow-symlinks -i "/^$/d" /etc/fstab
	sed --follow-symlinks -i "/.*\/nfs\/alumnos.*/d" /etc/fstab
	sed --follow-symlinks -i "/.*\/nfs\/profesor.*/d" /etc/fstab
	sed --follow-symlinks -i "/.*\/nfs\/privado.*/d" /etc/fstab
	sed --follow-symlinks -i "/.*\/nfs\/perfiles.*/d" /etc/fstab
fi
