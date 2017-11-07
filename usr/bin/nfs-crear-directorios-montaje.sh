#!/bin/bash
# Autor: Arturo Martín Romero - amartinromero@gmail.com - programa de software libre

# Exportamos variables útiles
. /etc/default/vx-dga-variables/vx-dga-variables-general.conf

# Se crean los directorios de montaje en función del usuario gráfico
# Al montar sobre /media se creará un "shortcut" en el Escritorio de los usuarios
CARPETAMONTAJE="$1"
RECURSOREMOTO="$2"
MODOMONTAJE="$3"
LOG="/var/log/vitalinux/nfs-cliente.log"

if ! test -d ${CARPETAMONTAJE} ; then
	if mkdir ${CARPETAMONTAJE} ; then
		echo "=> $(date) - Se ha creado la carpeta para el recurso: $RECURSOREMOTO" | tee -a ${LOG}
	else
		echo "=> $(date) - Problemas al crear carpeta para el recurso: $IPCACHE:$RECURSOREMOTO" | tee -a ${LOG}
		exit 1
	fi
else
	echo "=> $(date) - El directorio \"${CARPETAMONTAJE}\" ya existe ... pasamos a montarlo ..." | tee -a ${LOG}
fi

if test "${MODOMONTAJE}" = "fstab" \
	&& ! (grep ^$IPCACHE:$RECURSOREMOTO /etc/fstab &> /dev/null) ; then
	echo "=> $(date) - Se va configurar en fstab: $IPCACHE:$RECURSOREMOTO"
	if echo "$IPCACHE:$RECURSOREMOTO $CARPETAMONTAJE nfs \
actimeo=25,noatime,bg,nfsvers=3,tcp,rw,noauto,user,hard,intr,defaults,exec 0 0" >> /etc/fstab ; then
		exit 0
	else
		echo "=> $(date) - Problemas al configurar fstab para: $IPCACHE:$RECURSOREMOTO" | tee -a ${LOG}
		exit 1
	fi
else
	echo "=> $(date) - Recurso no fstab: $IPCACHE:$RECURSOREMOTO $MODOMONTAJE" | tee -a ${LOG}
	exit 0
fi
