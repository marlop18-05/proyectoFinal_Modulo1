#!/bin/bash
# Pruebas de entrada del analizador. No modifica las capturas reales.
set -e
cd "$(dirname "$0")/.."
mkdir -p evidencias/pruebas
log="evidencias/pruebas/pruebas_c.txt"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
gcc -Wall -Wextra fuentes/sec_engine.c -o "$tmp/sec_engine"
: > "$log"

probar() {
    nombre="$1"
    esperado="$2"
    if "$tmp/sec_engine" "$tmp/entrada.txt" "$tmp/informe.txt" > "$tmp/salida.txt" 2>&1; then
        estado=0
    else
        estado=$?
    fi
    if [ "$esperado" = "correcto" ] && [ "$estado" -eq 0 ]; then
        resultado="BIEN"
    elif [ "$esperado" = "error" ] && [ "$estado" -ne 0 ]; then
        resultado="BIEN"
    else
        resultado="FALLO"
    fi
    echo "$nombre | esperado: $esperado | codigo: $estado | $resultado" | tee -a "$log"
    cat "$tmp/salida.txt" >> "$log"
    if [ -f "$tmp/informe.txt" ]; then cat "$tmp/informe.txt" >> "$log"; fi
    echo "---------------------" >> "$log"
    rm -f "$tmp/informe.txt"
    [ "$resultado" = "BIEN" ]
}

cat > "$tmp/entrada.txt" <<'EOF'
AuditoriaCursoC
9
DISCO 62
PROCESOS 8
PERMISOS 0
DISCO 82
PROCESOS 11
PERMISOS 1
DISCO 78
PROCESOS 10
PERMISOS 0
EOF
probar "Ejemplo de 9 registros" correcto
# Verificar que las estadisticas del ejemplo sean las esperadas.
cat > "$tmp/entrada.txt" <<'EOF'
AuditoriaCursoC
6
DISCO 0
DISCO 100
PROCESOS 0
PROCESOS 2000
PERMISOS 0
PERMISOS 200
EOF
probar "Valores frontera" correcto
cat > "$tmp/entrada.txt" <<'EOF'
AuditoriaCursoC
2
DISCO 50
PROCESOS 10
EOF
probar "Categoria sin observaciones" correcto
printf 'AuditoriaCursoC\n0\n' > "$tmp/entrada.txt"
probar "Cero registros" correcto
cat > "$tmp/entrada.txt" <<'EOF'
AuditoriaCursoC
1
DISCO 101
EOF
probar "Valor fuera de rango" error
cat > "$tmp/entrada.txt" <<'EOF'
AuditoriaCursoC
1
OTRA 5
EOF
probar "Categoria desconocida" error
cat > "$tmp/entrada.txt" <<'EOF'
AuditoriaCursoC
15
DISCO 62
PROCESOS 8
PERMISOS 0
DISCO 82
PROCESOS 11
PERMISOS 1
DISCO 78
PROCESOS 10
PERMISOS 0
EOF
probar "Cabecera mayor que datos" error
sed -i '2s/15/3/' "$tmp/entrada.txt"
probar "Cabecera menor que datos" error
printf 'AuditoriaCursoC\n1\nDISCO 50\nTEXTO\n' > "$tmp/entrada.txt"
probar "Registro adicional" error
if "$tmp/sec_engine" "$tmp/no_existe.txt" "$tmp/informe.txt" > "$tmp/salida.txt" 2>&1; then
    echo "Archivo inexistente | FALLO" | tee -a "$log"
    exit 1
else
    echo "Archivo inexistente | BIEN" | tee -a "$log"
fi
chmod 640 "$log"
echo "Pruebas de C registradas en $log"
