#!/bin/bash
# Autor: Arturo Martín Romero - amartinromero@gmail.com - programa de software libre

is_in_group() {

	USU="$1"
	GRUPO="$2"
	if id -Gn "$USU" | grep "$GRUPO" >/dev/null 2>&1 ; then
		return 0
	else
		return 1
	fi
}

## Comenzamos importando y definiendo las variables que usaremos posteriormente:
. /etc/default/vx-dga-variables/vx-dga-variables-general.conf
# En el caso de salir de forma inespearada desmontamos lo que haya montado
trap '/usr/bin/nfs-desmontajes.sh; exit' INT TERM EXIT

LOG="/var/log/vitalinux/nfs-cliente.log"

NFSRECURSOS="/usr/share/vitalinux/nfs-compartir/nfs-recursos"
if ! test -f ${NFSRECURSOS} ; then
	exit 1
fi
NFSEXCLUIDOS="/usr/share/vitalinux/nfs-compartir/nfs-excluidos"


USUARIO=$(vx-usuario-grafico)


if test -f /usr/bin/migasfree-tags ; then
	ETIQUETAS="$(migasfree-tags -g | tr -s '"' ' ')"
	echo "--> Las etiquetas Migasfree del equipo son: ${ETIQUETAS}"
fi

if test -f /usr/bin/nfs-agregar-montaje.sh ; then
	echo "--> Comprobamos si hay algún nuevo recurso compartido que haya que agregar ..."
	/usr/bin/nfs-agregar-montaje.sh "${ETIQUETAS}"
fi

## **** Modificar el programa para que si el recurso no es montable (excluido) no haga nada antes...


# Variable encargada de decidir si se muestran mensajes para evitar mensajes recurrentes:
MOSTRAR_MENSAJE=1

while true ; do

	# Comprobamos si el servidor Caché esta presente y da servicio NFS cada xx segundos por si hay caída
	if ( ping -c 1 "${IPCACHE}" && echo >/dev/tcp/"${IPCACHE}"/2049 ) >/dev/null 2>&1 ; then
		for LINEA in $(cat ${NFSRECURSOS} | sed "/^#.*/d" | tr -s " " "*") ; do
			RECURSO="$(echo "${LINEA}" | tr -s '*' ' ')"
			RECURSOREMOTO=$(echo "${RECURSO}" | cut -d":" -f1)
			CARPETAMONTAJE=$(echo "${RECURSO}" | cut -d":" -f2)
			MENSAJEOK=$(echo "${RECURSO}" | cut -d":" -f3)
			MENSAJEERROR=$(echo "${RECURSO}" | cut -d":" -f4)
			MODOMONTAJE=$(echo "${RECURSO}" | cut -d":" -f5)
			TIPOUSUARIO=$(echo "${RECURSO}" | cut -d":" -f6)
			
			FLAGMONTAR=1
			# Solo los usuarios administradores de la máquina pueden montar recursos marcados como ADM
			if [ "${TIPOUSUARIO}" = "ADM" ] && ! is_in_group "${USUARIO}" "sudo" ; then
				FLAGMONTAR=0
				break
			fi
			# Si el recurso está excluido directamente no se monta
			if [ -n "${ETIQUETAS}" ] ; then
				for LINEA in $(cat ${NFSEXCLUIDOS} | sed "/^#.*/d" | sed "/^$/d") ; do
					CENTROEXCLUIDO=$(echo ${LINEA} | cut -d":" -f1)
					MONTAJESEXCLUIDOS=$(echo ${LINEA} | cut -d":" -f2)
					GRUPOEXCLUIDOS=$(echo ${LINEA} | cut -d":" -f3)
					if ( echo "${ETIQUETAS}" | grep "${CENTROEXCLUIDO}" &> /dev/null ) ; then
						echo "--> Este centro tiene excluidos: ${CENTROEXCLUIDO} -- ${ETIQUETAS}"
						if [ "${GRUPOEXCLUIDOS}" = "ALL" ] \
							|| (is_in_group "${USUARIO}" "${GRUPOEXCLUIDOS}") ; then
							echo "--> El usuario tiene exclusiones de grupo: ${USUARIO} -- ${GRUPOEXCLUIDOS}"
							if [ "${MONTAJESEXCLUIDOS}" = "ALL" ] \
								|| ( echo "${MONTAJESEXCLUIDOS}" | grep "${CARPETAMONTAJE}" &> /dev/null ); then
								echo "--> Recurso excluido: ${CARPETAMONTAJE} -- ${MONTAJESEXCLUIDOS}"
								FLAGMONTAR=0
								break
							fi
						fi
					fi
				done
			fi
			# Montamos los recursos compartidos configurados si no están montados, comprobando si esta excluido o no
			if [ ${FLAGMONTAR} -eq 1 ] && ! (grep "^${IPCACHE}:${RECURSOREMOTO}" /etc/mtab &> /dev/null) \
				&&  (showmount -e ${IPCACHE} | grep ${RECURSOREMOTO} &> /dev/null) ; then
				if /usr/bin/nfs-crear-directorios-montaje.sh "${CARPETAMONTAJE}" "${RECURSOREMOTO}" "${MODOMONTAJE}" ; then
					if su ${USUARIO} -c "mount ${CARPETAMONTAJE}" --login ; then
						echo "$(date) - Se monta el recurso ${RECURSOREMOTO}" | tee -a ${LOG} && \
						[ "${MOSTRAR_MENSAJE}" = "1" ] && notify-send -i vx-dga-correcto "${MENSAJEOK}"
					else
						echo "$(date) - Error al montar el recurso ${RECURSOREMOTO}" | tee -a ${LOG} && \
						[ "${MOSTRAR_MENSAJE}" = "1" ] && notify-send -i vx-dga-incorrecto "${MENSAJEERROR}"
					fi
				fi
			
			fi
			
		done
	else
		# Se ha perdido el acceso al servidor caché...Desmontamos en el caso de estar montados
		# Sería conveniente un flag que salte ésta parte para mayor celeridad
		MENSAJE_PERDIDA_CONEXION="Perdida la conexión con los recursos compartidos del servidor caché. Se intentará reconectar en breve"
		[ "$(/usr/bin/nfs-desmontajes.sh)" = "DESMONTA" ] && \
			echo "$(date) - Se desmontan los recursos" | tee -a ${LOG} && \
			[ "${MOSTRAR_MENSAJE}" = "1" ] && \
			notify-send -i vx-dga-incorrecto "${MENSAJE_PERDIDA_CONEXION}" && \
			MOSTRAR_MENSAJE=0 && TEMPORIZADOR1="$(date +%s)" && TEMPORIZADOR2="$((${TEMPORIZADOR1} + (15 * 60)))"
	fi

	# Por si se produjera una desconexión inesperada, cada 15 segundos lo revisamos
	sleep 15

	# Comprobamos si se ha evitado mostrar mensajes durante los últimos 15 minutos
	if [ "${MOSTRAR_MENSAJE}" = "0" ] ; then
		TEMPORIZADOR1="$(date +%s)"
		if [[ "${TEMPORIZADOR1}" > "${TEMPORIZADOR2}" ]] ; then
			MOSTRAR_MENSAJE=1
		fi
	fi

done
