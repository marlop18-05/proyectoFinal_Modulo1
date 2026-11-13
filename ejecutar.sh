
#!/bin/bash

# Ejecucion general del proyecto sec_guard.

set -e

paquete="capturas/estaticos/paquete_auditoria.tar.gz"
extraidos="capturas/extraidos"

echo "INICIO DEL PROYECTO SEC_GUARD"

# Evitar utilizar resultados anteriores.
rm -f resultados/informe_seguridad.txt
rm -f fuentes/sec_engine
rm -f preparados/mediciones_sec.txt
rm -f capturas/telemetria_raw.log

# Verificar el paquete original.
if [ ! -f "$paquete" ]; then
    echo "Error: no se encontro el paquete de auditoria."
    exit 1
fi

if ! tar -tzf "$paquete" > /dev/null; then
    echo "Error: el paquete esta dañado."
    exit 1
fi

# Extraer nuevamente los archivos.
mkdir -p "$extraidos"
rm -f "$extraidos/secure.log" \
      "$extraidos/net_traffic.log" \
      "$extraidos/sshd_config"

tar -xzf "$paquete" -C "$extraidos"

for archivo in secure.log net_traffic.log sshd_config
do
    if [ ! -f "$extraidos/$archivo" ]; then
        echo "Error: falta $archivo"
        exit 1
    fi
done

echo "Paquete verificado y extraido."

# Procesar los registros originales.
./scripts/preparar.sh
echo "Registros preparados."

# Obtener tres capturas reales.
for i in 1 2 3
do
    ./scripts/capturar.sh
done

# Generar el archivo que leera C.
./scripts/normalizar.sh

# Compilar y ejecutar el programa.
gcc -Wall -Wextra fuentes/sec_engine.c -o fuentes/sec_engine

./fuentes/sec_engine \
    preparados/mediciones_sec.txt \
    resultados/informe_seguridad.txt

# Comprobar que existe un informe nuevo.
if [ ! -s resultados/informe_seguridad.txt ]; then
    echo "Error: no se genero el informe."
    exit 1
fi

chmod 640 resultados/informe_seguridad.txt

echo "PROYECTO FINALIZADO CORRECTAMENTE"
echo "Informe: resultados/informe_seguridad.txt"

