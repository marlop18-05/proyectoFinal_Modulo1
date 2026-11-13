#!/bin/bash
# Controlar solo un proceso propio de prueba.
set -e
salida="evidencias/pruebas/admin_process.txt"
mkdir -p evidencias/pruebas
sleep 300 &
pid=$!
# Si se interrumpe el script, no dejar el proceso de prueba activo.
trap 'kill -CONT "$pid" 2>/dev/null || true; kill -TERM "$pid" 2>/dev/null || true' EXIT
{
    echo "ADMINISTRACION DE PROCESO"
    echo "Fecha: $(date)"
    echo "Usuario: $(whoami)"
    echo "Proceso: sleep 300"
    echo "PID: $pid"
} > "$salida"
kill -STOP "$pid"
echo "Senal STOP enviada" >> "$salida"
ps -o pid,stat,comm -p "$pid" >> "$salida"
kill -CONT "$pid"
echo "Senal CONT enviada" >> "$salida"
ps -o pid,stat,comm -p "$pid" >> "$salida"
kill -TERM "$pid"
echo "Senal TERM enviada" >> "$salida"
wait "$pid" 2>/dev/null || true
if kill -0 "$pid" 2>/dev/null; then
    echo "Error: proceso aun activo" >> "$salida"
    exit 1
fi
echo "Proceso terminado" >> "$salida"
chmod 640 "$salida"
trap - EXIT
