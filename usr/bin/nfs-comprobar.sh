#!/bin/bash
# Autor: Arturo Martín Romero - amartinromero@gmail.com - programa de software libre

## Comenzamos importando y definiendo las variables que usaremos posteriormente:
. /etc/default/vx-dga-variables/vx-dga-variables-general.conf

SEAT_ACTIVO="seat0"
SESION_ACTIVA=$(loginctl show-seat ${SEAT_ACTIVO} | grep 'ActiveSession' | cut -d'=' -f2)
USUARIO=$(loginctl list-sessions | grep "${SEAT_ACTIVO}" | grep "${SESION_ACTIVA}" | tr -s ' ' ' ' | cut -d' ' -f4)

if test $(showmount -e ${IPCACHE} | grep -v "Export list" | wc -l) -ge 1 ; then
	echo -e "\nListado de Recursos Compartidos por el Caché de tu Centro:\n<b><tt><span foreground='blue'>" > /tmp/listado-recursos-nfs.${USUARIO}
	showmount -e ${IPCACHE} | grep -v "Export list" >> /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "</span></tt></b>" >> /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "\nDe los recursos compartidos anteriores estan accesibles en este momento:" >> /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "<b><tt><span foreground='blue'>" >> /tmp/listado-recursos-nfs.${USUARIO}
	cat /etc/mtab | grep "^$IPCACHE" | cut -d" " -f1,2 | awk -F" " '{print $1 " -> " $2}' >> /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "</span></tt></b>" >> /tmp/listado-recursos-nfs.${USUARIO}
else
	echo -e "\nListado de Recursos Compartidos por el Caché de tu Centro:<b><tt><span foreground='blue'>" > /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "¡¡Problemas!! No se detectan Recursos Compartidos ..." >> /tmp/listado-recursos-nfs.${USUARIO}
	echo "IP del Servidor Caché configurado: $IPCACHE" >> /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "</span></tt></b>" >> /tmp/listado-recursos-nfs.${USUARIO}
fi

if PIDNFS=$(pgrep nfs-cliente) &> /dev/null ; then
	yad --center --title "Estado del Servicio NFS" \
		--width 660 \
		--image nfs-servicio \
		--window-icon=/usr/share/lxpanel/images/vitalinux.svg \
		--text "El <b>Servicio de Carpetas Compartidas</b> esta <b>Activo</b> ... \n $(cat /tmp/listado-recursos-nfs.${USUARIO})" \
		--text-align center \
		--button="Cerrar Ventana":0
else
	if yad --center --title "Estado del Servicio NFS" \
		--image nfs-servicio \
		--width 660 \
		--text-align center \
		--window-icon=/usr/share/lxpanel/images/vitalinux.svg \
		--text "El Servicio de Carpetas Compartidas no esta activo. \n La razón es desconocida. \n <b>¿Quieres activar el Servicio?</b>" \
		--button="Activar Servicio":0 --button="Dejarlo Desactivado":1 ; then
		if test -f /usr/bin/nfs-cliente.sh ; then
			/usr/bin/nfs-cliente.sh &
		fi
	fi
fi



