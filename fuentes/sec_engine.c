#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct Medicion {
    char categoria[16];
    int valor;
};

struct Resumen {
    char nombre[16];
    int cantidad;
    int suma;
    int minimo;
    int maximo;
    int alertas;
};

/* Regresa el indice de la categoria, o -1 si no existe. */
int buscar_categoria(const char *nombre, struct Resumen resumen[]) {
    for (int i = 0; i < 3; i++) {
        if (strcmp(nombre, resumen[i].nombre) == 0) return i;
    }
    return -1;
}

/* Leer los registros y actualizar el resumen de cada categoria. */
int leer_mediciones(FILE *entrada, struct Medicion datos[], int cantidad,
                    struct Resumen resumen[], int *total_alertas) {
    char categoria[32];
    char adicional;
    int valor;

    for (int i = 0; i < cantidad; i++) {
        if (fscanf(entrada, " %31s %d", categoria, &valor) != 2) {
            fprintf(stderr, "Error: faltan registros o hay datos incorrectos.\n");
            return 1;
        }
        int tipo = buscar_categoria(categoria, resumen);
        if (tipo == -1) {
            fprintf(stderr, "Error: categoria desconocida: %s\n", categoria);
            return 1;
        }
        int limite = 2000;
        if (tipo == 0) limite = 100;
        if (tipo == 2) limite = 200;
        if (valor < 0 || valor > limite) {
            fprintf(stderr, "Error: valor fuera de rango: %s %d\n", categoria, valor);
            return 1;
        }
        strcpy(datos[i].categoria, categoria);
        datos[i].valor = valor;
        struct Resumen *r = &resumen[tipo];
        if (r->cantidad == 0) {
            r->minimo = valor;
            r->maximo = valor;
        }
        r->cantidad++;
        r->suma += valor;
        if (valor < r->minimo) r->minimo = valor;
        if (valor > r->maximo) r->maximo = valor;
        if ((tipo == 0 && valor >= 80) ||
            (tipo == 1 && valor >= 30) ||
            (tipo == 2 && valor > 0)) {
            r->alertas++;
            (*total_alertas)++;
        }
    }
    if (fscanf(entrada, " %c", &adicional) == 1 || ferror(entrada)) {
        fprintf(stderr, "Error: registros adicionales o lectura fallida.\n");
        return 1;
    }
    return 0;
}

/* Escribir el informe; revisar escritura y cierre. */
int escribir_informe(const char *ruta, const char *etiqueta, int cantidad,
                    struct Resumen resumen[], int total_alertas) {
    FILE *salida = fopen(ruta, "w");
    if (salida == NULL) {
        fprintf(stderr, "Error: no se pudo crear el informe.\n");
        return 1;
    }
    fprintf(salida, "INFORME DE SEGURIDAD - SEC_GUARD\n");
    fprintf(salida, "Etiqueta: %s\n", etiqueta);
    fprintf(salida, "Total de mediciones: %d\n\n", cantidad);
    for (int i = 0; i < 3; i++) {
        struct Resumen *r = &resumen[i];
        fprintf(salida, "CATEGORIA: %s\nCantidad: %d\n", r->nombre, r->cantidad);
        if (r->cantidad == 0) {
            fprintf(salida, "Sin datos\n");
        } else {
            fprintf(salida, "Suma: %d\nMinimo: %d\nMaximo: %d\n",
                    r->suma, r->minimo, r->maximo);
            fprintf(salida, "Promedio: %.2f\n", (double)r->suma / r->cantidad);
        }
        fprintf(salida, "Alertas: %d\n\n", r->alertas);
    }
    fprintf(salida, "TOTAL DE ALERTAS: %d\n", total_alertas);
    int error = ferror(salida);
    if (fclose(salida) != 0) error = 1;
    if (error) {
        fprintf(stderr, "Error: no se pudo guardar el informe completo.\n");
        remove(ruta);
        return 1;
    }
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Uso: %s entrada salida\n", argv[0]);
        return 1;
    }
    FILE *entrada = fopen(argv[1], "r");
    if (entrada == NULL) {
        fprintf(stderr, "Error: no se pudo abrir la entrada.\n");
        return 1;
    }
    char etiqueta[32];
    int cantidad;
    if (fscanf(entrada, " %31s %d", etiqueta, &cantidad) != 2 ||
        cantidad < 0 || cantidad > 200) {
        fprintf(stderr, "Error: encabezado incorrecto.\n");
        fclose(entrada);
        return 1;
    }
    struct Medicion *datos = NULL;
    if (cantidad > 0) {
        datos = malloc((size_t)cantidad * sizeof *datos);
        if (datos == NULL) {
            fprintf(stderr, "Error: no se pudo reservar memoria.\n");
            fclose(entrada);
            return 1;
        }
    }
    struct Resumen resumen[3] = {
        {"DISCO", 0, 0, 0, 0, 0},
        {"PROCESOS", 0, 0, 0, 0, 0},
        {"PERMISOS", 0, 0, 0, 0, 0}
    };
    int total_alertas = 0;
    int error = leer_mediciones(entrada, datos, cantidad, resumen, &total_alertas);
    if (fclose(entrada) != 0) {
        fprintf(stderr, "Error: no se pudo cerrar la entrada.\n");
        error = 1;
    }
    if (error) {
        free(datos);
        return 1;
    }
    error = escribir_informe(argv[2], etiqueta, cantidad, resumen, total_alertas);
    free(datos);
    if (error) return 1;
    printf("Informe generado: %s\n", argv[2]);
    return 0;
}
