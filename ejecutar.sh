#!/bin/bash
# Ejecucion general del proyecto sec_guard, desde la raiz.
set -e
cd "$(dirname "$0")"
paquete="capturas/estaticos/paquete_auditoria.tar.gz"
extraidos="capturas/extraidos"
echo "INICIO DEL PROYECTO SEC_GUARD"

# No conservar un informe anterior si alguna fase falla.
rm -f resultados/informe_seguridad.txt fuentes/sec_engine preparados/mediciones_sec.txt capturas/telemetria_raw.log
rm -rf "$extraidos"
if [ ! -f "$paquete" ] || ! tar -tzf "$paquete" >/dev/null 2>&1; then
    echo "Error: paquete ausente o danado" >&2
    exit 1
fi
mkdir -p "$extraidos"
tar -xzf "$paquete" -C "$extraidos"
for archivo in secure.log net_traffic.log sshd_config; do
    if [ ! -f "$extraidos/$archivo" ]; then
        echo "Error: falta $archivo" >&2
        exit 1
    fi
done
echo "Paquete verificado y extraido."
./scripts/preparar.sh

# Tres observaciones separadas por un segundo.
for i in 1 2 3; do
    ./scripts/capturar.sh
    if [ "$i" -lt 3 ]; then sleep 1; fi
done
./scripts/normalizar.sh

./scripts/proceso.sh

# Compilar de nuevo y nunca reutilizar el binario viejo.
gcc -Wall -Wextra fuentes/sec_engine.c -o fuentes/sec_engine
./fuentes/sec_engine preparados/mediciones_sec.txt resultados/informe_seguridad.txt
if [ ! -s resultados/informe_seguridad.txt ]; then
    echo "Error: no se genero el informe" >&2
    exit 1
fi
chmod 640 resultados/informe_seguridad.txt

echo "PROYECTO FINALIZADO CORRECTAMENTE"
echo "Informe: resultados/informe_seguridad.txt"
