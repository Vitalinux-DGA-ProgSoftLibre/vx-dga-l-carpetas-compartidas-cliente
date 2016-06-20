#!/bin/bash
# Autor: Arturo Martín Romero - amartinromero@gmail.com - programa de software libre

## Comenzamos importando y definiendo las variables que usaremos posteriormente:
. /etc/default/vx-dga-variables/vx-dga-variables-general.conf

if test -f /usr/share/vitalinux/nfs-compartir/unidades-nfs ; then
	RUTAMONTAJES=/usr/share/vitalinux/nfs-compartir/unidades-nfs
else
	exit 1
fi

USUARIO=$(who | grep " :0 " | cut -d" " -f1)
## Para evitar ante errores imprevistos que se reproduzcan los mensajes de error periodicamente:
# Se define un array de errores donde cada posición esta asociada a un punto de montaje
# La variable CONTADOR se encargará de determinar en que punto de montaje estamos
ERRORES=(0 0 0 0 0 0 0)

while true ; do
	CONTADOR=0
	# Comprobamos si el servidor Caché esta presente y da servicio NFS
	if ping -c 1 $IPCACHE &> /dev/null && nc -zv $IPCACHE 2049 &> /dev/null ; then
		for LINEA in $(cat $RUTAMONTAJES | tr -s " " "*") ; do
			RECURSO=$(echo $LINEA | tr -s "*" " ")
			RECURSOREMOTO=$(echo $RECURSO | cut -d":" -f1)
			CARPETAMONTAJE=$(echo $RECURSO | cut -d":" -f2)
			MENSAJEOK=$(echo $RECURSO | cut -d":" -f3)
			MENSAJEERROR=$(echo $RECURSO | cut -d":" -f4)
			MODOMONTAJE=$(echo $RECURSO | cut -d":" -f5)
			if (showmount -e $IPCACHE | grep $RECURSOREMOTO &> /dev/null) \
				&& ! (grep ^$IPCACHE:$RECURSOREMOTO /etc/mtab &> /dev/null) \
				&& ! (echo $RECURSOREMOTO | grep privado &> /dev/null) ; then
					if mount $CARPETAMONTAJE ; then
						notify-send -i /usr/share/pixmaps/vx-dga-correcto.png "$MENSAJEOK"
						ERRORES[$CONTADOR]=0
					else
						if test ${ERRORES[$CONTADOR]} -eq 0 ; then
							notify-send -i /usr/share/pixmaps/vx-dga-incorrecto.png \
							"No se han podido montar las Unidades de Red. Ha aparecido un error inesperado"
							ERRORES[$CONTADOR]=1
						fi
					fi
			fi
			# En el caso del recurso compartido deberá ser un usuario administrador
			if (showmount -e $IPCACHE | grep $RECURSOREMOTO &> /dev/null) \
				&& ! (grep ^$IPCACHE:$RECURSOREMOTO /etc/mtab &> /dev/null) \
				&& (echo $RECURSOREMOTO | grep privado &> /dev/null) \
				&& (id $USUARIO | grep adm &> /dev/null) ; then
					if mount $CARPETAMONTAJE ; then
						notify-send -i /usr/share/pixmaps/vx-dga-correcto.png "$MENSAJEOK"
						ERRORES[$CONTADOR]=0
					else
						if test ${ERRORES[$CONTADOR]} -eq 0 ; then
							notify-send -i /usr/share/pixmaps/vx-dga-incorrecto.png \
							"No se han podido montar las Unidades de Red. Ha aparecido un error inesperado"
							ERRORES[$CONTADOR]=1
						fi
					fi
			fi
			CONTADOR=$(expr $CONTADOR + 1)
		done
	fi
	# Por si se produjera una desconexión inesperada, cada 10 segundos lo revisamos
	sleep 10
done
