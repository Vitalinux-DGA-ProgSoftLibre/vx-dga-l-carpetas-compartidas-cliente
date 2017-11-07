#!/bin/bash
# Código de estado que devuelve:
# 0: si ha desmontado algún recurso y todo ha funcionado bien
# 1: si no ha desmontado nada, pero todo ha funcionado bien
# X: no sabemos que ha podido ocurrir...error dado por los comandos.
## Comenzamos importando y definiendo las variables que usaremos posteriormente:
. /etc/default/vx-dga-variables/vx-dga-variables-general.conf

DESMONTA=0
for RECURSO in $( cat /etc/mtab | grep "^${IPCACHE}" | cut -d" " -f2) ; do
	if umount -lf ${RECURSO} ; then
		rmdir --ignore-fail-on-non-empty ${RECURSO}
		DESMONTA=1
	fi
done


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
[ "$DESMONTA" = 1 ] && echo "DESMONTA"
exit 0
