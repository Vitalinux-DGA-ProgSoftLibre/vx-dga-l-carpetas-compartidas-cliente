#!/bin/bash
# Autor: Arturo Martín Romero - amartinromero@gmail.com - programa de software libre

# El script puede recibir las etiquetas en la llamada...sino, las solicitamos
## Comenzamos importando y definiendo las variables que usaremos posteriormente:

. /etc/default/vx-dga-variables/vx-dga-variables-general.conf

NFSRECURSOS="/usr/share/vitalinux/nfs-compartir/nfs-recursos"
NFSAGREGADOS="/usr/share/vitalinux/nfs-compartir/nfs-agregados"
LOG="/var/log/vitalinux/nfs-cliente.log"
AGREGAR=0

if [ -n "$1" ]; then
	ETIQUETAS="$1"
elif test -f /usr/bin/migasfree-tags ; then
	ETIQUETAS="$(migasfree-tags -g | tr -s '"' ' ')"
fi

if test -f ${NFSAGREGADOS} ; then
	for AGREGADO in $(cat ${NFSAGREGADOS} | sed "/^#.*/d" | sed "/^$/d" | tr -s " " "*") ; do
		RECURSO="$(echo $AGREGADO | tr -s '*' ' ')"
		RECURSOREMOTO="$(echo $RECURSO | cut -d':' -f1)"
		CARPETAMONTAJE="$(echo $RECURSO | cut -d':' -f2)"
		CENTROAFECTADO="$(echo $RECURSO | cut -d':' -f7)"
		if ( test "${CENTROAFECTADO}" = "ALL" ) || \
			( echo "${ETIQUETAS}" | grep "${CENTROAFECTADO}" &> /dev/null ) ; then
			if ! ( cat ${NFSRECURSOS} | grep "^${RECURSOREMOTO}:${CARPETAMONTAJE}" &> /dev/null ) ; then
				AGREGAR=1
				echo "$(date) - Se va a agregar un nuevo recurso: \"${RECURSO}\"" | tee -a ${LOG}
				echo "${RECURSO}" | cut -d":" -f1,2,3,4,5,6 >> ${NFSRECURSOS}
			fi
		fi
	done
	if test "${AGREGAR}" -eq 0 ; then
		echo "$(date) - No hay ningún nuevo recurso que agregar ..." | tee -a ${LOG}
	fi
fi
