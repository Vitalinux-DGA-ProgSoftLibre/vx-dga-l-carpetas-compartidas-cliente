#!/bin/bash
# Autor: Arturo Martín Romero - amartinromero@gmail.com - programa de software libre

# Exportamos variables útiles
. /etc/default/vx-dga-variables/vx-dga-variables-general.conf

# Se crean los directorios de montaje en función del usuario gráfico
# Al montar sobre /media se creará un "shortcut" en el Escritorio de los usuarios
CARPETAMONTAJE="$1"
RECURSOREMOTO="$2"
MODOMONTAJE="$3"
if ! test -d ${CARPETAMONTAJE} ; then
	if mkdir ${CARPETAMONTAJE} ; then
		if test "${MODOMONTAJE}" = "fstab" \
			&& ! (grep ^$IPCACHE:$RECURSOREMOTO /etc/fstab &> /dev/null) ; then
			if echo "$IPCACHE:$RECURSOREMOTO $CARPETAMONTAJE nfs \
actimeo=1800,noatime,nolock,bg,nfsvers=3,tcp,rw,noauto,user,hard,intr,defaults,exec 0 0" >> /etc/fstab ; then
				exit 0
			else
				exit 1
			fi
		else
			exit 0
		fi
	else
		exit 1
	fi
else
	exit 0
fi
