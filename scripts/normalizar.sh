
#!/bin/bash

entrada="capturas/telemetria_raw.log"
salida="preparados/mediciones_sec.txt"

if [ ! -f "$entrada" ]; then
    echo "No existe el archivo de telemetria."
    exit 1
fi

cantidad=$(wc -l < "$entrada")

if (( cantidad > 200 )); then
    echo "Se supero el limite de 200 mediciones."
    exit 1
fi

{
    echo "AuditoriaCursoC"
    echo "$cantidad"
    awk '{print $2, $3}' "$entrada"
} > "$salida" || exit 1

chmod 640 "$salida"
echo "Mediciones normalizadas: $cantidad"

