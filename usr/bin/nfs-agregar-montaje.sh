#!/bin/bash
# Autor: Arturo Martín Romero - amartinromero@gmail.com - programa de software libre

## Comenzamos importando y definiendo las variables que usaremos posteriormente:
. /etc/default/vx-dga-variables/vx-dga-variables-general.conf

NFSRECURSOS="/usr/share/vitalinux/nfs-compartir/nfs-recursos"
NFSAGREGADOS="/usr/share/vitalinux/nfs-compartir/nfs-agregados"
if test -f ${NFSAGREGADOS} ; then
	for AGREGADO in $(cat ${NFSAGREGADOS} | sed "/^#.*/d" | sed "/^$/d" | tr -s " " "*") ; do
		RECURSO="$(echo $AGREGADO | tr -s '*' ' ')"
		RECURSOREMOTO="$(echo $RECURSO | cut -d':' -f1)"
		CARPETAMONTAJE="$(echo $RECURSO | cut -d':' -f2)"
		if ! ( cat /etc/fstab | grep "^$IPCACHE:$RECURSOREMOTO" &> /dev/null ) ; then
			echo "$IPCACHE:$RECURSOREMOTO $CARPETAMONTAJE nfs \
actimeo=1800,noatime,nolock,bg,nfsvers=3,tcp,rw,noauto,user,hard,intr,defaults,exec 0 0" >> /etc/fstab
			echo "${RECURSO}" >> ${NFSRECURSOS}
		fi
	done
fi
