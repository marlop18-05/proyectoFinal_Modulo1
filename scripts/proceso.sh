
#!/bin/bash

salida="evidencias/pruebas/admin_process.txt"

{
    echo "ADMINISTRACION DE PROCESO"
    echo "Fecha: $(date)"
    echo "Usuario: $(whoami)"
} > "$salida"

sleep 300 &
pid=$!

echo "Proceso: sleep 300" >> "$salida"
echo "PID: $pid" >> "$salida"

kill -STOP "$pid" || exit 1
echo "Senal STOP enviada" >> "$salida"
ps -o pid,stat,comm -p "$pid" >> "$salida"

kill -CONT "$pid" || exit 1
echo "Senal CONT enviada" >> "$salida"
ps -o pid,stat,comm -p "$pid" >> "$salida"

kill -TERM "$pid" || exit 1
echo "Senal TERM enviada" >> "$salida"

wait "$pid" 2>/dev/null || true

if kill -0 "$pid" 2>/dev/null; then
    echo "Error: el proceso sigue activo" >> "$salida"
    exit 1
fi

echo "Proceso terminado" >> "$salida"
chmod 640 "$salida"

