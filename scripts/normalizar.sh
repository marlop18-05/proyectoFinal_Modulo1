#!/bin/bash
# Pasar fecha categoria valor a categoria valor, sin quitar repetidos.
set -e
entrada="capturas/telemetria_raw.log"
salida="preparados/mediciones_sec.txt"
if [ ! -f "$entrada" ]; then
    echo "Error: falta telemetria_raw.log" >&2
    exit 1
fi
cantidad=$(wc -l < "$entrada")
if (( cantidad < 0 || cantidad > 200 )); then
    echo "Error: cantidad de mediciones fuera de rango" >&2
    exit 1
fi
# Comprobar que cada linea tenga fecha, categoria y valor valido.
if ! awk '
NF != 3 {exit 1}
$2 != "DISCO" && $2 != "PROCESOS" && $2 != "PERMISOS" {exit 1}
$3 !~ /^[0-9]+$/ {exit 1}
$2 == "DISCO" && $3 > 100 {exit 1}
$2 == "PROCESOS" && $3 > 2000 {exit 1}
$2 == "PERMISOS" && $3 > 200 {exit 1}
' "$entrada"; then
    echo "Error: formato incorrecto en telemetria" >&2
    exit 1
fi
{
    echo "AuditoriaCursoC"
    echo "$cantidad"
    awk '{print $2, $3}' "$entrada"
} > "$salida"
chmod 640 "$salida"
echo "Mediciones normalizadas: $cantidad"
