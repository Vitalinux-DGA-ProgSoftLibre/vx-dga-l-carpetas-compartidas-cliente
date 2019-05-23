#!/bin/bash
# Autor: Arturo Martín Romero - amartinromero@gmail.com - programa de software libre

## Comenzamos importando y definiendo las variables que usaremos posteriormente:
. /etc/default/vx-dga-variables/vx-dga-variables-general.conf

USUARIO=$(vx-usuario-grafico)
if ! ( ping -c 1 "$IPCACHE" && echo >/dev/tcp/"${IPCACHE}"/2049 ) >/dev/null 2>&1 ; then
	echo -e "\nListado de Recursos Compartidos por el Caché de tu Centro:<b><tt><span foreground='blue'>" > /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "No se puede alcanzar al Servidor Cache!" >> /tmp/listado-recursos-nfs.${USUARIO}
	echo "IP del Servidor Caché configurado: $IPCACHE" >> /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "</span></tt></b>" >> /tmp/listado-recursos-nfs.${USUARIO}
elif test $(showmount -e ${IPCACHE} | grep -v "Export list" | wc -l) -ge 1 ; then
	echo -e "\nListado de Recursos Compartidos por el Caché de tu Centro:\n<b><tt><span foreground='blue'>" > /tmp/listado-recursos-nfs.${USUARIO}
	showmount -e ${IPCACHE} | grep -v "Export list" >> /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "</span></tt></b>" >> /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "\nDe los recursos compartidos anteriores estan accesibles en este momento:" >> /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "<b><tt><span foreground='blue'>" >> /tmp/listado-recursos-nfs.${USUARIO}
	grep "^$IPCACHE" /proc/mounts | cut -d" " -f1,2 | awk -F" " '{print $1 " -> " $2}' >> /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "</span></tt></b>" >> /tmp/listado-recursos-nfs.${USUARIO}
else
	echo -e "\nListado de Recursos Compartidos por el Caché de tu Centro:<b><tt><span foreground='blue'>" > /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "¡¡Problemas!! No se detectan Recursos Compartidos ..." >> /tmp/listado-recursos-nfs.${USUARIO}
	echo "IP del Servidor Caché configurado: $IPCACHE" >> /tmp/listado-recursos-nfs.${USUARIO}
	echo -e "</span></tt></b>" >> /tmp/listado-recursos-nfs.${USUARIO}
fi

if start-stop-daemon --status --name nfs-cliente.sh ; then
	yad --center --title "Estado del Servicio NFS" \
		--width 660 \
		--image nfs-servicio \
		--window-icon vitalinux \
		--text "El <b>Servicio de Carpetas Compartidas</b> esta <b>Activo</b> ... \n $(cat /tmp/listado-recursos-nfs.${USUARIO})" \
		--text-align center \
		--button="Cerrar Ventana":0
else
	if yad --center --title "Estado del Servicio NFS" \
		--image nfs-servicio \
		--width 660 \
		--text-align center \
		--window-icon vitalinux \
		--text "El Servicio de Carpetas Compartidas <b>no esta activo</b>. \n $(cat /tmp/listado-recursos-nfs.${USUARIO}) \n <b>¿Quieres activar el Servicio?</b>" \
		--button="Activar Servicio":0 --button="Dejarlo Desactivado":1 ; then
		if [ -f /usr/bin/nfs-cliente.sh ] ; then
			sudo /sbin/start-stop-daemon --start --quiet -m --name nfs-cliente.sh --pidfile /run/nfs-cliente.pid -b -a /usr/bin/nfs-cliente.sh
		fi
	fi
fi



