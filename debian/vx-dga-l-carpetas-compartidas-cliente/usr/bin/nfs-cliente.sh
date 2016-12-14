#!/bin/bash
# Autor: Arturo Martín Romero - amartinromero@gmail.com - programa de software libre

## Comenzamos importando y definiendo las variables que usaremos posteriormente:
. /etc/default/vx-dga-variables/vx-dga-variables-general.conf

NFSRECURSOS="/usr/share/vitalinux/nfs-compartir/nfs-recursos"
if ! test -f ${NFSRECURSOS} ; then
	exit 1
fi
NFSEXCLUIDOS="/usr/share/vitalinux/nfs-compartir/nfs-excluidos"

# Para determinar el usuario gráfico:
# if ! test -z ${XAUTHORITY} ; then
# 	USUARIO=$(getent passwd | grep ${XAUTHORITY//\/.Xauthority/} | cut -d":" -f1)
# else
# 	USUARIO=$(who | grep "(:0" | tr -s " " " " | cut -d" " -f1 | uniq)
# fi


#SEAT_ACTIVO=$(loginctl list-seats | sed -e '/^$/d' | grep -v SEAT | grep -v "seats listed")
SEAT_ACTIVO="seat0"
SESION_ACTIVA=$(loginctl show-seat ${SEAT_ACTIVO} | grep 'ActiveSession' | cut -d'=' -f2)
USUARIO=$(loginctl list-sessions | grep "${SEAT_ACTIVO}" | grep "${SESION_ACTIVA}" | tr -s ' ' ' ' | cut -d' ' -f4)

if test -f /usr/bin/migasfree-cid ; then
	CID="$(migasfree-cid)"
	echo "--> El CID del equipo es: ${CID} ..."
fi
if test -f /usr/bin/migasfree-tags ; then
	ETIQUETAS="$(sudo migasfree-tags -g | tr -s '"' ' ')"
	echo "--> Las etiquetas Migasfree del equipo son: ${ETIQUETAS}"
fi

## Para evitar ante errores imprevistos que se reproduzcan los mensajes de error periodicamente:
# Se define un array de errores donde cada posición esta asociada a un punto de montaje
# La variable CONTADOR se encargará de determinar en que punto de montaje estamos
ERRORES=(0 0 0 0 0 0 0)

while true ; do
	CONTADOR=0
	# Comprobamos si el servidor Caché esta presente y da servicio NFS
	if ping -c 1 $IPCACHE &> /dev/null && nc -zv $IPCACHE 2049 &> /dev/null ; then
		for LINEA in $(cat ${NFSRECURSOS} | sed "/^#.*/d" | tr -s " " "*") ; do
			RECURSO="$(echo $LINEA | tr -s '*' ' ')"
			RECURSOREMOTO=$(echo $RECURSO | cut -d":" -f1)
			CARPETAMONTAJE=$(echo $RECURSO | cut -d":" -f2)
			MENSAJEOK=$(echo $RECURSO | cut -d":" -f3)
			MENSAJEERROR=$(echo $RECURSO | cut -d":" -f4)
			MODOMONTAJE=$(echo $RECURSO | cut -d":" -f5)
			TIPOUSUARIO=$(echo $RECURSO | cut -d":" -f6)
			# Montamos los recursos compartidos configurados comprobando si esta excluido o no
			if (showmount -e $IPCACHE | grep $RECURSOREMOTO &> /dev/null) \
				&& ! (grep "^$IPCACHE:$RECURSOREMOTO" /etc/mtab &> /dev/null) ; then
				# && ( grep "^$IPCACHE:$RECURSOREMOTO" /etc/fstab &> /dev/null ); then

					FLAGMONTAR=1

					if test "${TIPOUSUARIO}" = "ADM" \
						&& ! ( id ${USUARIO} | grep "4(adm)" &> /dev/null ) ; then
							FLAGMONTAR=0
					fi

					#if ( echo $RECURSOREMOTO | grep privado &> /dev/null ) \
					#	&& ! ( id $USUARIO | grep adm &> /dev/null ) ; then
					#	FLAGMONTAR=0
					#fi

					if ! test -z "${ETIQUETAS}" ; then
						for LINEA in $(cat ${NFSEXCLUIDOS} | sed "/^#.*/d" | sed "/^$/d") ; do
							CENTROEXCLUIDO=$(echo ${LINEA} | cut -d":" -f1)
							MONTAJESEXCLUIDOS=$(echo ${LINEA} | cut -d":" -f2)
							USUARIOSEXCLUIDOS=$(echo ${LINEA} | cut -d":" -f3)
							if (echo "${ETIQUETAS}" | grep "${CENTROEXCLUIDO}" &> /dev/null) ; then
								echo "--> Este equipo tiene excluidos: ${CENTROEXCLUIDO} -- ${ETIQUETAS}"
								if (echo "${USUARIOSEXCLUIDOS}" | grep "${USUARIO}"  &> /dev/null) \
									|| ( test "${USUARIOSEXCLUIDOS}" = "ALL") ; then
									echo "--> El usuario tiene exclusiones: ${USUARIO} -- ${USUARIOSEXCLUIDOS}"
									if ( echo "${MONTAJESEXCLUIDOS}" | grep "${CARPETAMONTAJE}" &> /dev/null ) \
										|| ( test "${MONTAJESEXCLUIDOS}" = "ALL" ); then
										echo "--> Recurso excluido: ${CARPETAMONTAJE} -- ${MONTAJESEXCLUIDOS}"
										FLAGMONTAR=0
									fi
								fi
							fi
						done
					fi

					if test ${FLAGMONTAR} -eq 1  ; then
						if sudo /usr/bin/nfs-crear-directorios-montaje.sh "$CARPETAMONTAJE" "$RECURSOREMOTO" "$MODOMONTAJE" ; then
							if mount $CARPETAMONTAJE ; then
								notify-send -i vx-dga-correcto "$MENSAJEOK"
								ERRORES[$CONTADOR]=0
							else
								if test ${ERRORES[$CONTADOR]} -eq 0 ; then
									notify-send -i vx-dga-incorrecto \
									"No se han podido montar las Unidades de Red. Ha aparecido un error inesperado"
									ERRORES[$CONTADOR]=1
								fi
							fi
						fi
					fi
			fi
			
			CONTADOR=$(expr $CONTADOR + 1)
		done
	fi
	# Por si se produjera una desconexión inesperada, cada 10 segundos lo revisamos
	sleep 10
done
