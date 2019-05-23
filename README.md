# Paquete DEB vx-dga-l-carpetas-compartidas-cliente

Paquete encargado de configurar en los equipos cliente Vitalinux (de 32 y 64 bits) las carpetas compartidas o recursos compartidos vía NFS del Servidor Caché que se coloca en los centros educativos

# Usuarios Destinatarios

Profesores y alumnos que hacen uso de carpetas compartidas para tener centralizada toda la información que generan (documentos, imágenes, vídeos, etc.)

# Aspectos Interesantes:
Aunque es configurable existen por defecto tres recursos compartidos con los siguientes permisos de lectura (r), escritura (w) y acceso (x) para profesores y alumnos: **/usr/share/vitalinux/nfs-compartir/nfs-recursos**
```
alumnos: permisos (rwx) tanto para profesores como alumnos
profesores: permisos (rx) para alumnos y (rwx) para profesores
privado: ningún permiso para alumnos y (rwx) para profesores
```
A partir de la versión 3 es posible excluir determinados recursos compartidos, los cuales se indican en **/usr/share/vitalinux/nfs-compartir/nfs-excluidos**.
A parte de los recursos compartidos que hay por defecto, el paquete esta pensado para poder agregar nuevos recursos: **/usr/share/vitalinux/nfs-compartir/nfs-agregados**.
# Como Crear el paquete DEB a partir del codigo de GitHub
Para crear el paquete DEB será necesario encontrarse dentro del directorio donde localizan los directorios que componen el paquete.  Una vez allí, se ejecutará el siguiente comando (es necesario tener instalados los paquetes apt-get install debhelper devscripts):

```
apt-get install debhelper devscripts
/usr/bin/debuild --no-tgz-check -us -uc
```

En caso de no querer crear el paquete para tu distribución, puedes hacer uso del que está disponible para Vitalinux (*Lubuntu 14.04*) desde el siguiente repositorio:

[Respositorio de paquetes DEB de Vitalinux](http://migasfree.educa.aragon.es/repo/Lubuntu-14.04/STORES/base/)

# Como Instalar el paquete generado vx-dga-l-*.deb:
Para la instalación de paquetes que estan en el equipo local puede hacerse uso de ***dpkg*** o de ***gdebi***, siendo este último el más aconsejado para que se instalen también las dependencias correspondientes.
```
gdebi vx-dga-l-*.deb
```
