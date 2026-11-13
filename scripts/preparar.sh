#!/bin/bash

# Procesamiento de los archivos de auditoria.

origen="capturas/extraidos"
destino="preparados"

# Configuracion SSH: activar Port y HostKey.
sed -E \
    -e 's/^[[:space:]]*#?[[:space:]]*Port[[:space:]]+[0-9]+/Port 8080/' \
    -e 's/^[[:space:]]*#[[:space:]]*(HostKey[[:space:]]+)/\1/' \
    -e '/^[[:space:]]*#/d' \
    -e '/^[[:space:]]*$/d' \
    "$origen/sshd_config" > "$destino/sshd_activo.txt" || exit 1

# Usuarios creados: nombre, UID y GID.
awk -F '[ ,=]+' \
    '/useradd\[[0-9]+\]: new user:/ {print $9, $11, $13}' \
    "$origen/secure.log" > "$destino/usuarios_creados.txt" || exit 1


# Solicitudes TCP SYN: IP origen, puerto origen, IP destino, puerto destino.
awk '
/Flags \[S\]/ {
    origen = $2
    destino = $4
    sub(/:$/, "", destino)

    puerto_origen = origen
    puerto_destino = destino

    sub(/^.*\./, "", puerto_origen)
    sub(/^.*\./, "", puerto_destino)

    sub(/\.[0-9]+$/, "", origen)
    sub(/\.[0-9]+$/, "", destino)

    print origen, puerto_origen, destino, puerto_destino
}' "$origen/net_traffic.log" > "$destino/conexiones_syn.txt" || exit 1

chmod 640 "$destino/sshd_activo.txt" \
          "$destino/usuarios_creados.txt" \
          "$destino/conexiones_syn.txt"

echo "Archivos de auditoria preparados."

