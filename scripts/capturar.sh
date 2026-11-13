
#!/bin/bash

# Captura de tres indicadores del servidor.
# Se ejecuta desde la raiz de sec_guard.

salida="capturas/telemetria_raw.log"
fecha=$(date '+%Y-%m-%d_%H:%M:%S')

# Porcentaje usado en el sistema de archivos del proyecto.
disco=$(df -P . | awk 'NR==2 {gsub(/%/, "", $5); print $5}')

# Cantidad de procesos pertenecientes al usuario.
procesos=$(ps -u "$(whoami)" -o pid= | wc -l)

# Archivos regulares con escritura para grupo u otros.
permisos=$(find . -type f \( -perm /020 -o -perm /002 \) | wc -l)

# Comprobar que las capturas contienen numeros.
case "$disco" in
    ''|*[!0-9]*) echo "Error al capturar DISCO"; exit 1 ;;
esac

case "$procesos" in
    ''|*[!0-9]*) echo "Error al capturar PROCESOS"; exit 1 ;;
esac

case "$permisos" in
    ''|*[!0-9]*) echo "Error al capturar PERMISOS"; exit 1 ;;
esac

# Rangos definidos para el proyecto.
if (( disco > 100 || procesos > 2000 || permisos > 200 )); then
    echo "Error: una medicion supera su rango."
    exit 1
fi

{
    echo "$fecha DISCO $disco"
    echo "$fecha PROCESOS $procesos"
    echo "$fecha PERMISOS $permisos"
} >> "$salida" || exit 1

chmod 640 "$salida"
echo "Captura registrada: $fecha"

