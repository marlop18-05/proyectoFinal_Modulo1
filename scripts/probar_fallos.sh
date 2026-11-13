#!/bin/bash
# Tres pruebas de fallo del orquestador, sin dejar cambios permanentes.
set -e
cd "$(dirname "$0")/.."
mkdir -p evidencias/pruebas
log="evidencias/pruebas/pruebas_fallos.txt"
tmp=$(mktemp -d)
paquete="capturas/estaticos/paquete_auditoria.tar.gz"
cp "$paquete" "$tmp/paquete_original.tar.gz"
cp fuentes/sec_engine.c "$tmp/sec_engine_original.c"
perm=$(stat -c '%a' scripts/capturar.sh)
restaurar() {
    cp "$tmp/paquete_original.tar.gz" "$paquete"
    cp "$tmp/sec_engine_original.c" fuentes/sec_engine.c
    chmod "$perm" scripts/capturar.sh
    rm -rf "$tmp"
}
trap restaurar EXIT
: > "$log"
probar_fallo() {
    nombre="$1"
    echo "PRUEBA: $nombre" >> "$log"
    if ./ejecutar.sh >> "$log" 2>&1; then
        echo "FALLO: el orquestador no se detuvo" | tee -a "$log"
        exit 1
    fi
    if [ -e resultados/informe_seguridad.txt ]; then
        echo "FALLO: quedo un informe anterior" | tee -a "$log"
        exit 1
    fi
    echo "BIEN: se detuvo y no quedo informe" | tee -a "$log"
}

printf 'paquete corrupto\n' > "$paquete"
probar_fallo "Paquete tar corrupto"
cp "$tmp/paquete_original.tar.gz" "$paquete"
chmod 000 scripts/capturar.sh
probar_fallo "Sin permiso de ejecucion en capturar.sh"
chmod "$perm" scripts/capturar.sh
printf '\nesto_no_es_codigo_c\n' >> fuentes/sec_engine.c
probar_fallo "Error de compilacion en C"
cp "$tmp/sec_engine_original.c" fuentes/sec_engine.c
restaurar
trap - EXIT
chmod 640 "$log"
echo "Pruebas de fallos registradas en $log"
echo "Ejecuta ./ejecutar.sh para dejar el informe final actualizado."
