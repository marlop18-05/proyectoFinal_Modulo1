#!/bin/bash
# Una captura real de DISCO, PROCESOS y PERMISOS.
set -o pipefail
salida="capturas/telemetria_raw.log"
fecha=$(date '+%Y-%m-%d_%H:%M:%S') || exit 1

disco=$(df -P "$HOME" | awk 'NR==2 {gsub(/%/, "", $5); print $5}') || { echo "Error en df" >&2; exit 1; }
procesos=$(ps -u "$(whoami)" -o pid= | wc -l) || { echo "Error en ps" >&2; exit 1; }
permisos=$(find . -type f \( -perm /020 -o -perm /002 \) | wc -l) || { echo "Error en find" >&2; exit 1; }

for dato in "$disco" "$procesos" "$permisos"; do
    case "$dato" in
        ''|*[!0-9]*) echo "Error: medicion no numerica" >&2; exit 1 ;;
    esac
done
if (( disco > 100 || procesos > 2000 || permisos > 200 )); then
    echo "Error: una medicion esta fuera de rango" >&2
    exit 1
fi

# Solo se escribe cuando las tres lecturas fueron correctas.
{
    echo "$fecha DISCO $disco"
    echo "$fecha PROCESOS $procesos"
    echo "$fecha PERMISOS $permisos"
} >> "$salida" || exit 1
chmod 640 "$salida" || exit 1
echo "Captura registrada: $fecha"
