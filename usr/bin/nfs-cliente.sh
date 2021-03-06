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
trap '/usr/bin/nfs-desmontajes.sh; exit' EXIT

LOG="/var/log/vitalinux/nfs-cliente.log"

NFSRECURSOS="/usr/share/vitalinux/nfs-compartir/nfs-recursos"
if ! test -f ${NFSRECURSOS} ; then
	exit 1
fi
NFSEXCLUIDOS="/usr/share/vitalinux/nfs-compartir/nfs-excluidos"

USUARIO=$(vx-usuario-grafico)

echo "$(date) - << Inicio del cliente....comprobando etiquetas >>" | tee -a ${LOG}
if [ -f "/tmp/migasfree.tags" ]; then
        ETIQUETAS=$(tr -s '"' ' ' < /tmp/migasfree.tags)
else
        CONTADOR=0
        while ! ETIQUETAS="$(migasfree-tags -g | tr -s '"' ' ')" || (( CONTADOR > 59 )) ; do
                echo "=> Esperando a obtener etiquetas ..." | tee -a ${LOG}
                ((CONTADOR++))
                sleep 1
        done
        (( CONTADOR == 60 )) && ETIQUETAS=""
fi

echo "$(date) - << Etiquetas Migasfree: ${ETIQUETAS}" | tee -a ${LOG}

if test -f /usr/bin/nfs-agregar-montaje.sh ; then
	echo "--> Comprobamos si hay algún nuevo recurso compartido que haya que agregar ..." | tee -a ${LOG}
	/usr/bin/nfs-agregar-montaje.sh "${ETIQUETAS}"
fi

# Variable encargada de decidir si se muestran mensajes para evitar mensajes "pesados":
#  * Si en algún momento se pierde conexión con el servidor caché o no hay conexión se deshabilitan los mensajes
#  * Si hay un error en algún montaje también se deshabilitan los mensajes
MOSTRAR_MENSAJE=1

# Opciones de montaje por defecto:
MNTOPTIONSDFL="actimeo=1800,noatime,bg,nfsvers=3,tcp,rw,hard,intr,nodev,nosuid,exec"

while true ; do

	# Comprobamos si el servidor Caché esta presente y da servicio NFS cada xx segundos por si hay caída
	if ( ping -c 1 "${IPCACHE}" && echo >/dev/tcp/"${IPCACHE}"/2049 ) >/dev/null 2>&1 ; then
		for LINEA in $( < "${NFSRECURSOS}" sed "/^#.*/d" | tr -s " " "*") ; do
			RECURSO="$(echo "${LINEA}" | tr -s '*' ' ')"
			RECURSOREMOTO=$(echo "${RECURSO}" | cut -d":" -f1)
			CARPETAMONTAJE=$(echo "${RECURSO}" | cut -d":" -f2)
			MENSAJEOK=$(echo "${RECURSO}" | cut -d":" -f3)
			MENSAJEERROR=$(echo "${RECURSO}" | cut -d":" -f4)
			TIPOUSUARIO=$(echo "${RECURSO}" | cut -d":" -f5)

			MNTOPTIONS=$MNTOPTIONSDFL
			
			FLAGMONTAR=1
			# Solo los usuarios administradores de la máquina pueden montar recursos marcados como ADM
			if [ "${TIPOUSUARIO}" = "ADM" ] && \
				! is_in_group "${USUARIO}" "sudo" && \
				! is_in_group "${USUARIO}" "profesor" && \
				! is_in_group "${USUARIO}" "privado" ; then
				FLAGMONTAR=0
				#break - no tiene sentido ponerlo, ya que si el recurso ADM está al principio no montaría otros.
			fi

			# Si el recurso está excluido directamente no se monta
			if [ -n "${ETIQUETAS}" ] ; then
				for LINEA in $( < ${NFSEXCLUIDOS} sed "/^#.*/d" | sed "/^$/d") ; do
					CENTROEXCLUIDO=$(echo "${LINEA}" | cut -d":" -f1)
					MONTAJESEXCLUIDOS=$(echo "${LINEA}" | cut -d":" -f2)
					GRUPOEXCLUIDOS=$(echo "${LINEA}" | cut -d":" -f3)
					if ( echo "${ETIQUETAS}" | grep "${CENTROEXCLUIDO}" &> /dev/null ) ; then
						echo "--> Este centro tiene excluidos: ${CENTROEXCLUIDO} -- ${ETIQUETAS}" | tee -a ${LOG}
						if [ "${GRUPOEXCLUIDOS}" = "ALL" ] \
							|| (is_in_group "${USUARIO}" "${GRUPOEXCLUIDOS}") ; then
							echo "--> El usuario tiene exclusiones de grupo: ${USUARIO} -- ${GRUPOEXCLUIDOS}"  | tee -a ${LOG}
							if [ "${MONTAJESEXCLUIDOS}" = "ALL" ] \
								|| ( echo "${MONTAJESEXCLUIDOS}" | grep "${CARPETAMONTAJE}" &> /dev/null ); then
								echo "--> Recurso excluido: ${CARPETAMONTAJE} -- ${MONTAJESEXCLUIDOS}"  | tee -a ${LOG}
								FLAGMONTAR=0
								break
							fi
						fi
					fi
				done
			fi
			
			# Montamos los recursos compartidos configurados si no están montados previamente
	
			# ...comprobamos si estuviera montado y no debería
			grep "^${IPCACHE}:${RECURSOREMOTO}" /proc/mounts &> /dev/null
			MONTADO=$?
			showmount -e "${IPCACHE}" | grep "${RECURSOREMOTO}" &> /dev/null
			ACCESIBLE=$?

			#if [ ${FLAGMONTAR} -eq 0 ] && (grep "^${IPCACHE}:${RECURSOREMOTO}" /proc/mounts &> /dev/null); then
			if [ ${FLAGMONTAR} -eq 0 ] && [ $MONTADO -eq 0 ]; then
				# Desmontar el recurso
				if umount -lf "${CARPETAMONTAJE}" ; then
					[ -z "$(ls -A "${CARPETAMONTAJE}" )" ] && rmdir --ignore-fail-on-non-empty "${CARPETAMONTAJE}"
					echo "$(date) - Desmontado: $CARPETAMONTAJE...no debería estar montado"| tee -a ${LOG}
				fi
			# Por último, montamos si no lo está...ojo, antes desmontamos el recurso si hay algún problema temporal con el mismo
			# ...comprobamos primero si está montado y no es accceible!
			elif [ ${FLAGMONTAR} -eq 1 ]; then
				#if (grep "^${IPCACHE}:${RECURSOREMOTO}" /proc/mounts &> /dev/null) \
				#	&&  ! (showmount -e "${IPCACHE}" | grep "${RECURSOREMOTO}" &> /dev/null) ; then
				if [ $MONTADO -eq 0 ] && [ $ACCESIBLE -ne 0 ]; then
					if umount -lf "${CARPETAMONTAJE}" ; then
						[ -z "$(ls -A "${CARPETAMONTAJE}" )" ] && rmdir --ignore-fail-on-non-empty "${CARPETAMONTAJE}"
						echo "$(date) - Desmontado: $CARPETAMONTAJE...Algo ha pasado con el recurso compartido" | tee -a ${LOG} && \
							[ "${MOSTRAR_MENSAJE}" = "1" ] && notify-send -t 1000 -i vx-dga-incorrecto "Algo ha pasado con un recurso compartido" && \
									MOSTRAR_MENSAJE=0
					fi
				#elif ! (grep "^${IPCACHE}:${RECURSOREMOTO}" /proc/mounts &> /dev/null) \
				#	&&  (showmount -e "${IPCACHE}" | grep "${RECURSOREMOTO}" &> /dev/null) ; then
				elif [ $MONTADO -ne 0 ] && [ $ACCESIBLE -eq 0 ]; then
					if /usr/bin/nfs-crear-directorios-montaje.sh "${CARPETAMONTAJE}" && \
						mount -t nfs "${IPCACHE}:${RECURSOREMOTO}" "${CARPETAMONTAJE}" -o "${MNTOPTIONS}"; then
							echo "$(date) - Se monta el recurso ${RECURSOREMOTO}" | tee -a ${LOG} && \
							[ "${MOSTRAR_MENSAJE}" = "1" ] && notify-send -t 1000 -i vx-dga-correcto "${MENSAJEOK}"
					else
							echo "$(date) - Error al montar el recurso ${RECURSOREMOTO}" | tee -a ${LOG} && \
								[ "${MOSTRAR_MENSAJE}" = "1" ] && notify-send -t 1000 -i vx-dga-incorrecto "${MENSAJEERROR}" && \
									MOSTRAR_MENSAJE=0

					fi
			
				fi
			fi			
		done
	else
		# Se ha perdido el acceso al servidor caché...Desmontamos en el caso de estar montados
		# Sería conveniente un flag que salte ésta parte para mayor celeridad
		#MENSAJE_PERDIDA_CONEXION="Perdida la conexión con los recursos compartidos del servidor caché. Se intentará reconectar en breve"
		
		# Si tenemos problemas de acceso con el servidor caché, cancelamos el mostrar mensajes a partir de ahora...
		MOSTRAR_MENSAJE=0
		[ "$(/usr/bin/nfs-desmontajes.sh)" = "DESMONTA" ] && \
			echo "$(date) - Se desmontan los recursos" | tee -a ${LOG}
			# Como se quiere limpieza en el escritorio, se omiten notifiaciones
			#echo "$(date) - Se desmontan los recursos" | tee -a ${LOG} && \
			#[ "${MOSTRAR_MENSAJE}" = "1" ] && \
			#notify-send -i vx-dga-incorrecto "${MENSAJE_PERDIDA_CONEXION}" && \
			#MOSTRAR_MENSAJE=0 && TEMPORIZADOR1="$(date +%s)" && TEMPORIZADOR2="$((${TEMPORIZADOR1} + (15 * 60)))"
	fi
	# Por si se produjera una desconexión inesperada, cada 15 segundos lo revisamos
	sleep 15

	# Comprobamos si se ha evitado mostrar mensajes durante los últimos 15 minutos...se deshabilita por limpieza
<<COMMENT
	if [ "${MOSTRAR_MENSAJE}" = "0" ] ; then
		TEMPORIZADOR1="$(date +%s)"
		if [[ "${TEMPORIZADOR1}" > "${TEMPORIZADOR2}" ]] ; then
			MOSTRAR_MENSAJE=1
		fi
	fi
COMMENT
done
