
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

int main(int argc, char *argv[]) {
    FILE *entrada;
    FILE *salida;
    struct Medicion *datos = NULL;
    struct Resumen resumen[3] = {
        {"DISCO", 0, 0, 0, 0, 0},
        {"PROCESOS", 0, 0, 0, 0, 0},
        {"PERMISOS", 0, 0, 0, 0, 0}
    };

    char etiqueta[32];
    char categoria[32];
    char adicional;
    int cantidad;
    int valor;
    int total_alertas = 0;

    if (argc != 3) {
        fprintf(stderr, "Uso: %s entrada salida\n", argv[0]);
        return 1;
    }

    entrada = fopen(argv[1], "r");

    if (entrada == NULL) {
        fprintf(stderr, "No se pudo abrir el archivo de entrada.\n");
        return 1;
    }

    if (fscanf(entrada, " %31s", etiqueta) != 1 ||
        fscanf(entrada, " %d", &cantidad) != 1 ||
        cantidad < 0 || cantidad > 200) {
        fprintf(stderr, "Encabezado incorrecto.\n");
        fclose(entrada);
        return 1;
    }

    if (cantidad > 0) {
        datos = malloc((size_t)cantidad * sizeof *datos);

        if (datos == NULL) {
            fprintf(stderr, "No se pudo reservar memoria.\n");
            fclose(entrada);
            return 1;
        }
    }

    for (int i = 0; i < cantidad; i++) {
        if (fscanf(entrada, " %31s %d", categoria, &valor) != 2) {
            fprintf(stderr, "Faltan mediciones o hay datos incorrectos.\n");
            free(datos);
            fclose(entrada);
            return 1;
        }

        int tipo = -1;

        for (int j = 0; j < 3; j++) {
            if (strcmp(categoria, resumen[j].nombre) == 0) {
                tipo = j;
                break;
            }
        }

        if (tipo == -1) {
            fprintf(stderr, "Categoria desconocida: %s\n", categoria);
            free(datos);
            fclose(entrada);
            return 1;
        }

        int limite = 2000;

        if (tipo == 0) limite = 100;
        if (tipo == 2) limite = 200;

        if (valor < 0 || valor > limite) {
            fprintf(stderr, "Valor fuera de rango: %s %d\n",
                    categoria, valor);
            free(datos);
            fclose(entrada);
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
            total_alertas++;
        }
    }

    if (fscanf(entrada, " %c", &adicional) == 1 ||
        ferror(entrada)) {
        fprintf(stderr, "Existen datos adicionales.\n");
        free(datos);
        fclose(entrada);
        return 1;
    }

    if (fclose(entrada) != 0) {
        fprintf(stderr, "Error al cerrar la entrada.\n");
        free(datos);
        return 1;
    }

    salida = fopen(argv[2], "w");

    if (salida == NULL) {
        fprintf(stderr, "No se pudo crear el informe.\n");
        free(datos);
        return 1;
    }

    fprintf(salida, "INFORME DE SEGURIDAD - SEC_GUARD\n");
    fprintf(salida, "Etiqueta: %s\n", etiqueta);
    fprintf(salida, "Total de mediciones: %d\n\n", cantidad);

    for (int i = 0; i < 3; i++) {
        struct Resumen r = resumen[i];

        fprintf(salida, "CATEGORIA: %s\n", r.nombre);
        fprintf(salida, "Cantidad: %d\n", r.cantidad);

        if (r.cantidad == 0) {
            fprintf(salida, "Sin datos\n");
        } else {
            fprintf(salida, "Suma: %d\n", r.suma);
            fprintf(salida, "Minimo: %d\n", r.minimo);
            fprintf(salida, "Maximo: %d\n", r.maximo);
            fprintf(salida, "Promedio: %.2f\n",
                    (double)r.suma / r.cantidad);
        }

        fprintf(salida, "Alertas: %d\n\n", r.alertas);
    }

    fprintf(salida, "TOTAL DE ALERTAS: %d\n", total_alertas);

    if (fclose(salida) != 0) {
        fprintf(stderr, "Error al guardar el informe.\n");
        free(datos);
        return 1;
    }

    free(datos);
    printf("Informe generado: %s\n", argv[2]);

    return 0;
}

