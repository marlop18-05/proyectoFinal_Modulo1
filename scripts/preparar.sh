#!/bin/bash
# Preparar los tres archivos de auditoria extraidos.
set -e
origen="capturas/extraidos"
destino="preparados"
for archivo in sshd_config secure.log net_traffic.log; do
    if [ ! -f "$origen/$archivo" ]; then
        echo "Error: falta $origen/$archivo" >&2
        exit 1
    fi
done

# Activar Port 8080 y HostKey antes de quitar comentarios.
sed -E \
    -e 's/^[[:space:]]*#?[[:space:]]*Port[[:space:]]+[0-9]+/Port 8080/' \
    -e 's/^[[:space:]]*#[[:space:]]*(HostKey[[:space:]]+)/\1/' \
    -e '/^[[:space:]]*#/d' \
    -e '/^[[:space:]]*$/d' \
    "$origen/sshd_config" > "$destino/sshd_activo.txt"

# Campos de useradd: nombre, UID, GID.
awk -F '[ ,=]+' '/useradd\[[0-9]+\]: new user:/ {print $9, $11, $13}' \
    "$origen/secure.log" > "$destino/usuarios_creados.txt"

# El ejercicio pide cuatro octetos IPv4 y los dos puertos.
# No se eliminan lineas repetidas: son eventos distintos.
awk '
/Flags \[S\]/ && $1 == "IP" {
    origen = $2
    destino = $4
    sub(/:$/, "", destino)
    if (origen ~ /^([0-9]+\.){4}[0-9]+$/ && destino ~ /^([0-9]+\.){4}[0-9]+$/) {
        puerto_origen = origen
        puerto_destino = destino
        sub(/^.*\./, "", puerto_origen)
        sub(/^.*\./, "", puerto_destino)
        sub(/\.[0-9]+$/, "", origen)
        sub(/\.[0-9]+$/, "", destino)
        print origen, puerto_origen, destino, puerto_destino
    }
}' "$origen/net_traffic.log" > "$destino/conexiones_syn.txt"

for archivo in sshd_activo.txt usuarios_creados.txt conexiones_syn.txt; do
    if [ ! -s "$destino/$archivo" ]; then
        echo "Error: no se generaron datos en $archivo" >&2
        exit 1
    fi
done
chmod 640 "$destino/sshd_activo.txt" "$destino/usuarios_creados.txt" "$destino/conexiones_syn.txt"
echo "Archivos de auditoria preparados."
