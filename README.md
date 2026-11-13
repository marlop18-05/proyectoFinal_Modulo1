# Proyecto final del módulo 1: sec_guard

## Introducción

En este proyecto desarrollé un programa para obtener algunas mediciones de un servidor Linux y generar un informe a partir de ellas. La idea fue relacionar los comandos que vimos en el módulo con los scripts de Bash y con un programa en C. Para organizarlo, separé los archivos originales, los datos preparados, el código y los resultados.

Las tres mediciones que utilicé son DISCO, PROCESOS y PERMISOS. También trabajé con un paquete de auditoría que contiene registros de usuarios, tráfico de red y una configuración de SSH. Estos archivos se procesan como texto; el programa no modifica el servicio SSH del servidor.

## Organización del proyecto

- `capturas/`: paquete original en `estaticos/`, archivos descomprimidos temporalmente en `extraidos/` y `telemetria_raw.log`.
- `preparados/`: configuración SSH depurada, usuarios creados, conexiones TCP SYN y mediciones normalizadas.
- `fuentes/`: programa `sec_engine.c` y su ejecutable compilado.
- `scripts/`: scripts de preparación, captura, normalización, administración de procesos y pruebas.
- `resultados/`: informe de seguridad generado en C.
- `evidencias/`: documentación de permisos, enlaces y resultados de pruebas.
- `ejecutar.sh`: script principal que coordina el procedimiento desde la raíz.

Dentro de `capturas` agregué `extraidos/` para conservar el paquete comprimido sin mezclarlo con los archivos que se obtienen al descomprimirlo. Esta carpeta se vuelve a generar en cada ejecución.

## Requisitos y ejecución

Trabajé dentro de mi cuenta del servidor Linux, sin usar `sudo`. Para reproducir el proyecto se necesitan Bash, `tar`, `grep`, `sed`, `awk`, `df`, `ps`, `find`, `wc`, `stat` y GCC.

Desde la carpeta `sec_guard`:

```bash
chmod 750 ejecutar.sh scripts/*.sh
./ejecutar.sh
```

El script comprueba el paquete `capturas/estaticos/paquete_auditoria.tar.gz`, lo descomprime, procesa los registros, realiza tres capturas, normaliza los datos, compila el programa con `gcc -Wall -Wextra` y genera `resultados/informe_seguridad.txt`. Al final ejecuta una prueba de señales sobre un proceso propio. Si alguna etapa falla, la ejecución se detiene y no debe quedar un informe anterior como si fuera nuevo.

También se puede compilar y ejecutar el programa C por separado:

```bash
gcc -Wall -Wextra fuentes/sec_engine.c -o fuentes/sec_engine
./fuentes/sec_engine preparados/mediciones_sec.txt resultados/informe_seguridad.txt
```

El archivo de entrada debe tener una etiqueta de hasta 31 caracteres sin espacios, un total de 0 a 200 registros y, después, un par `CATEGORIA VALOR` por línea.

## Decisiones que tomé

**Permisos.** Elegí permisos `750` para directorios y scripts, y `640` para archivos de texto. El propietario puede trabajar con ellos, el grupo puede consultar lo necesario y otros usuarios no reciben acceso. Los directorios necesitan permiso de búsqueda (`x`) para poder entrar a ellos; los archivos de datos no necesitan ejecutarse. El detalle está en `evidencias/permissions.txt`.

**Enlaces.** En `evidencias/pruebas/` creé un archivo con `uname -a`, un enlace duro llamado `hardlink.txt` y cambié el nombre del archivo original a `prueba_renombrada.txt`. Los dos nombres conservaron el mismo inodo. También creé `acceso_prueba` como enlace simbólico a ese directorio. Guardé los resultados de `stat` en `evidencias/link_record.txt`.

**Preparación con sed y awk.** En `sshd_config` primero activo `Port 8080` y las líneas `HostKey`, y después quito comentarios y líneas vacías. Si quitara los comentarios antes de activar `HostKey`, perdería esas líneas. Para `secure.log` utilicé `awk -F '[ ,=]+'`, porque los datos están separados por espacios, comas y signos igual. En las conexiones TCP SYN busco `Flags [S]` y separo los puertos usando el último punto del campo. Conservo los eventos repetidos, pero para el reporte de cuatro octetos considero solo los pares IPv4; las líneas IPv6 no se pueden representar como cuatro octetos.

**Capturas.** Utilicé `df` para obtener el porcentaje del sistema de archivos donde está mi directorio personal, `ps` para contar mis procesos y `find` para contar archivos regulares con escritura para grupo u otros usuarios. El `find` usa una condición OR para no contar dos veces un archivo que tenga ambos permisos. Si un comando falla, el script debe detenerse en lugar de registrar un cero inventado.

**Normalización.** Dejé el registro original con fecha y hora. En otro archivo coloqué la etiqueta, la cantidad de mediciones y los pares categoría-valor. No eliminé datos repetidos porque corresponden a observaciones distintas.

**Programa C.** Definí una estructura `Medicion` para cada lectura y otra estructura `Resumen` para las estadísticas de cada categoría. Reservé memoria con `malloc` de acuerdo con el total declarado, comprobé su resultado y liberé la memoria con `free`. Separé la búsqueda de categorías, la lectura y el informe en funciones para revisar los errores con mayor facilidad. Las categorías no se mezclan al calcular promedios.

**Alertas.** Se cuenta una alerta si DISCO es mayor o igual que 80, PROCESOS mayor o igual que 30 o PERMISOS mayor que cero. Son umbrales del ejercicio y no una confirmación de un incidente real.

## Preguntas de la etapa 1

**1. ¿Por qué los permisos adecuados para un directorio pueden ser distintos de los necesarios para un archivo de datos?**

Porque un directorio se utiliza para entrar, buscar y organizar archivos. El permiso `x` permite atravesarlo, mientras que en un archivo de texto no necesito ejecutar nada, solo leerlo o modificarlo. Por eso utilicé `750` para los directorios y `640` para los archivos de datos.

**2. ¿Qué diferencia existe entre el archivo original y su enlace duro?**

El enlace duro no es una copia del contenido. Es otro nombre que apunta al mismo inodo. En mi prueba, `hardlink.txt` y `prueba_renombrada.txt` tenían el mismo inodo y el mismo contenido, incluso después de cambiar el nombre original.

**3. ¿Cuál es la utilidad de establecer enlaces simbólicos en el desarrollo de un sistema?**

Permiten acceder a un archivo o directorio desde otra ruta sin duplicarlo. En este proyecto utilicé `acceso_prueba` para llegar a `evidencias/pruebas/`. A diferencia del enlace duro, el simbólico guarda una ruta y puede dejar de funcionar si cambia su destino.

**4. ¿Qué información de los metadatos permite reconocer cambios en un archivo?**

Con `stat` puedo revisar tamaño, permisos, propietario, inodo y fechas. La fecha de modificación indica cambios en el contenido y la de cambio de estado permite reconocer modificaciones en metadatos, como permisos o enlaces. El inodo ayuda a comprobar si dos nombres hacen referencia al mismo archivo.

## Preguntas de la etapa 2

**1. ¿Qué transformación necesita la salida de cada utilería para convertirse en un registro del archivo normalizado?**

Primero hay que obtener solo el dato necesario: quitar `%` del porcentaje de `df`, contar los procesos con `ps` y `wc -l`, y contar los archivos que cumplen los permisos con `find`. Después guardo fecha, categoría y valor en el registro original. Finalmente `awk` selecciona la categoría y el valor para el archivo que lee C.

**2. ¿Por qué un valor cero puede ser válido y no debe confundirse con una captura fallida?**

Un cero puede significar que no encontré archivos con permisos de escritura para grupo u otros usuarios. Eso es una medición válida. Si `find` o cualquier otro comando falla, no tengo una lectura confiable y no debo guardar cero para disimular el error. Por eso reviso los códigos de salida.

**3. ¿Cómo comprobarán que la cantidad del encabezado corresponde a los registros conservados?**

Cuento las líneas del registro original con `wc -l` y escribo ese total en el encabezado. El programa en C lee exactamente esa cantidad y después intenta encontrar datos adicionales. Si faltan o sobran registros, muestra un error.

**4. ¿Por qué el orden de las instrucciones dentro del flujo de sed es estrictamente determinante al habilitar directivas y eliminar comentarios?**

Porque `sed` aplica las transformaciones en el orden escrito. Primero tengo que quitar el símbolo `#` de las directivas `Port` y `HostKey` que quiero conservar. Si elimino antes todas las líneas comentadas, esas directivas desaparecen y ya no puedo activarlas.

**5. ¿Qué estrategia se empleó para aislar el puerto sin limitar obtener correctamente los cuatro octetos de la IP?**

En el registro de red, el puerto aparece después del último punto del campo `IP.puerto`. Guardé una copia del campo y usé `sub(/^.*\./, "", ...)` para quedarme con el puerto. En el campo original quité únicamente el último punto y los dígitos del puerto con `sub(/\.[0-9]+$/, "", ...)`. Así se conserva la dirección IPv4 completa. Las direcciones IPv6 se excluyen de este reporte porque no tienen cuatro octetos.

## Preguntas de la etapa 3

**1. ¿Qué diferencia existe entre almacenar una medición y almacenar el resumen de una categoría?**

Una medición guarda una categoría y un valor de una observación específica. El resumen junta varias mediciones de la misma categoría para calcular cantidad, suma, mínimo, máximo, promedio y alertas. Por eso utilicé dos estructuras distintas.

**2. ¿Cómo evitarán una división entre cero o utilizar un mínimo que todavía no se ha inicializado?**

Antes de calcular el promedio reviso que la cantidad sea mayor que cero. Si no hay mediciones escribo `Sin datos`. Para mínimo y máximo utilizo el primer valor válido de cada categoría, en lugar de comenzar con un número inventado.

**3. Si ocurre un error después de reservar memoria y abrir un archivo, ¿qué recursos deben liberar o cerrar?**

Debo liberar el arreglo reservado con `free` y cerrar los archivos abiertos con `fclose`. También compruebo si la escritura del informe falló para no presentar un archivo incompleto como resultado correcto.

## Preguntas de la etapa 4

**1. ¿Cómo decide el script si puede continuar después de ejecutar el programa C?**

En Bash, un código de salida cero indica que el comando terminó correctamente; otro valor señala un error. Utilicé `set -e` y comprobaciones con `if` para detener el procedimiento si falla una fase. También puedo consultar el estado del último comando mediante `$?`.

**2. ¿Cómo se distinguirá un informe nuevo de uno conservado de una ejecución anterior?**

El orquestador elimina el informe anterior antes de empezar. Solo vuelve a generarlo después de validar el paquete, preparar datos, capturar, normalizar y compilar. Si ocurre un error intermedio, no debe quedar un informe viejo que parezca nuevo.

**3. ¿Qué evidencia demuestra que el informe se obtuvo mediante el flujo completo y no se elaboró manualmente?**

El registro de una ejecución completa, los archivos de entrada y salida y los resultados de las pruebas permiten comprobar el flujo. Para las señales utilizo un proceso propio `sleep 300`, guardo su PID, aplico `STOP`, `CONT` y `TERM`, y registro sus estados con `ps` en `evidencias/pruebas/admin_process.txt`. No necesito intervenir sobre procesos de otros usuarios.

## Pruebas y evidencias

Para probar el programa C sin modificar las capturas reales preparé:

```bash
./scripts/probar_c.sh
```

Este script revisa el ejemplo de nueve registros, valores frontera, una categoría vacía, cero registros, categoría desconocida, valor fuera de rango, cantidades mayores y menores que los datos reales, registros adicionales y un archivo inexistente. Guarda la salida en `evidencias/pruebas/pruebas_c.txt`.

Para comprobar los fallos del flujo completo:

```bash
./scripts/probar_fallos.sh
```

Este segundo script respalda los archivos que va a modificar, prueba un paquete corrupto, quita temporalmente el permiso de ejecución de `capturar.sh` e introduce un error de compilación en una copia temporalmente modificada del código C. Restaura los originales al terminar y registra la salida en `evidencias/pruebas/pruebas_fallos.txt`.

**Importante:** los archivos de evidencia solo deben presentarse como pruebas realizadas después de ejecutar los scripts en el servidor y revisar que indiquen `BIEN`. Para dejar el informe final actualizado, vuelvo a ejecutar `./ejecutar.sh`. La nueva captura real también es una prueba de funcionamiento.

## Control de versiones

Utilicé Git para guardar avances de las etapas del proyecto. Los cambios finales se registran después de revisar que los scripts y el programa C funcionen. Agregué `.gitignore` para no subir el ejecutable compilado ni los archivos descomprimidos temporales.

## Conclusión

Con esta práctica pude conectar la administración básica de Linux, el procesamiento de texto, los scripts y C dentro de un mismo procedimiento. La parte que consideré más importante fue comprobar los errores: no basta con que el programa produzca un informe, también debe detenerse cuando la entrada no es válida y dejar evidencia de lo que ocurrió.
