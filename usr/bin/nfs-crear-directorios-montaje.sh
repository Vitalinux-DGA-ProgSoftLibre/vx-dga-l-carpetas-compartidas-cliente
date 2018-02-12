#!/bin/bash
# Autor: Arturo Martín Romero - amartinromero@gmail.com - programa de software libre

# Exportamos variables útiles
. /etc/default/vx-dga-variables/vx-dga-variables-general.conf

# Se crean los directorios de montaje en función del usuario gráfico
# Al montar sobre /media se creará un "shortcut" en el Escritorio de los usuarios
CARPETAMONTAJE="$1"
#RECURSOREMOTO="$2"
#MODOMONTAJE="$3"
LOG="/var/log/vitalinux/nfs-cliente.log"

if [ ! -d "${CARPETAMONTAJE}" ]; then
	if mkdir "${CARPETAMONTAJE}" ; then
		echo "$(date) - Se ha creado la carpeta: $CARPETAMONTAJE" | tee -a ${LOG}
	else
		echo "$(date) - Problemas al crear carpeta $CARPETAMONTAJE" | tee -a ${LOG}
		exit 1
	fi
else
	echo "=> $(date) - El directorio \"${CARPETAMONTAJE}\" ya existe ... se montará encima de los datos existentes" | tee -a ${LOG}
fi
