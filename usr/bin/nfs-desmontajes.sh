#!/bin/bash
# Código de estado que devuelve:
# 0: si ha desmontado algún recurso y todo ha funcionado bien
# Devolverá en la salida estándar si ha desmontado algo o no mediante la cadena DESMONTA

. /etc/default/vx-dga-variables/vx-dga-variables-general.conf

LOG="/var/log/vitalinux/nfs-cliente.log"

DESMONTA=0
RUTAMONTAJES="/usr/share/vitalinux/nfs-compartir/nfs-recursos"
while IFS= read -r LINEA ; do
	RECURSO=$(echo "${LINEA}" | cut -d":" -f2)
	# Chequeamos que el recurso está montado, asociado a nfs y a nuestro servidor caché
	! ( grep "^${IPCACHE}.* nfs .*" /proc/mounts | grep "$RECURSO" > /dev/null 2>&1 ) && continue
	# Confirmamos el recurso con el dato existente en mounts
	#RECURSO=$( < /proc/mounts grep "^${IPCACHE}.* nfs .*" | cut -d" " -f2)
	echo "$(date) - Se va a desmontar el recurso: $RECURSO" >> ${LOG}
	if umount -lf "${RECURSO}" ; then
		[ -z "$(ls -A "${RECURSO}" )" ] && rmdir --ignore-fail-on-non-empty "${RECURSO}"
		echo "$(date) - Desmontado: $RECURSO" >> ${LOG}
		DESMONTA=1
	fi
done < <(grep -v '^ *[ #]' $RUTAMONTAJES | grep -v '^$')

[ "$DESMONTA" = "1" ] && echo "DESMONTA"
exit 0
