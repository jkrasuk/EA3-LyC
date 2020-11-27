#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

typedef struct
{
    char *nombre;
    char *nombreASM;
    char *tipo;
    union Valor
    {
        int valor_int;
        double valor_double;
        char *valor_str;
    } valor;
    int longitud;
} t_data;

typedef struct s_simbolo
{
    t_data data;
    struct s_simbolo *next;
} t_simbolo;

typedef struct
{
    t_simbolo *primero;
} t_tabla;

void crearTablaTS();
void inicializarTS();
char *limpiarString(char *, const char *);
int insertarTS(const char *, const char *, const char *, int, double);
t_data *crearDatos(const char *, const char *, const char *, int, double);
void guardarTS();
t_simbolo *getLexema(const char *);
char *reemplazarString(char *, const char *);
t_tabla *obtenerTablaTS();
t_tabla tablaTS;

int contadorString = 0;

t_tabla *obtenerTablaTS()
{
    return &(tablaTS);
}
void inicializarTS()
{
    crearTablaTS();
    insertarTS("_elemento_no_encontrado", CONST_STR, ELEMENTO_NO_ENCONTRADO, 0, 0);
    insertarTS("_valor_menor_a_1", CONST_STR, "\"El valor debe ser >= 1\"", 0, 0);
    insertarTS("_lista_vacia", CONST_STR, LISTA_VACIA, 0, 0);
    // Utilizado para comparar si el valor es mayor o igual a 1
    insertarTS("_1", CONST_INT, "", 1, 0);
    insertarTS(VALOR_NO_DETERMINADO, CONST_INT, "", -1, 0);
}
void crearTablaTS()
{
    t_data *data = (t_data *)malloc(sizeof(t_data));
    data = crearDatos("@resultado", TIPO_INT, "", 0, 0);

    if (data == NULL)
    {
        return;
    }

    t_simbolo *nuevo = (t_simbolo *)malloc(sizeof(t_simbolo));

    if (nuevo == NULL)
    {
        return;
    }

    nuevo->data = *data;
    nuevo->next = NULL;
    tablaTS.primero = nuevo;
}

int insertarTS(const char *nombre, const char *tipo, const char *valString, int valInt, double valDouble)
{
    printf("nombre: %s - valString %s - valInt %d", nombre, valString, valInt);
    t_simbolo *tabla = tablaTS.primero;
    char nombreCTE[300] = "_";
    strcat(nombreCTE, nombre);

    while (tabla)
    {
        if (strcmp(tabla->data.nombre, nombre) == 0 || strcmp(tabla->data.nombre, nombreCTE) == 0)
        {
            return 1;
        }
        else if (strcmp(tabla->data.tipo, CONST_STR) == 0)
        {

            if (strcmp(tabla->data.valor.valor_str, valString) == 0)
            {
                return 1;
            }
        }
        else if (strcmp(tabla->data.tipo, CONST_INT) == 0 && strcmp(tipo, CONST_INT) == 0)
        {

            if (tabla->data.valor.valor_int == valInt)
            {
                return 1;
            }
        }

        if (tabla->next == NULL)
        {
            break;
        }
        tabla = tabla->next;
    }
    t_data *data = (t_data *)malloc(sizeof(t_data));
    data = crearDatos(nombre, tipo, valString, valInt, valDouble);

    if (data == NULL)
    {
        return 1;
    }

    t_simbolo *nuevo = (t_simbolo *)malloc(sizeof(t_simbolo));

    if (nuevo == NULL)
    {
        return 2;
    }

    nuevo->data = *data;
    nuevo->next = NULL;

    if (tablaTS.primero == NULL)
    {
        tablaTS.primero = nuevo;
    }
    else
    {
        tabla->next = nuevo;
    }

    return 0;
}
t_data *crearDatos(const char *nombre, const char *tipo, const char *valString, int valInt, double valDouble)
{
    char full[200] = "_";
    char aux[200];

    t_data *data = (t_data *)calloc(1, sizeof(t_data));
    if (data == NULL)
    {
        return NULL;
    }

    data->tipo = (char *)malloc(sizeof(char) * (strlen(tipo) + 1));
    strcpy(data->tipo, tipo);
    if (strcmp(tipo, TIPO_STRING) == 0 || strcmp(tipo, TIPO_INT) == 0 || strcmp(tipo, TIPO_FLOAT) == 0)
    {
        data->nombre = (char *)malloc(sizeof(char) * (strlen(nombre) + 1));
        strcpy(data->nombre, nombre);
        data->nombreASM = (char *)malloc(sizeof(char) * (strlen(nombre) + 1));
        strcpy(data->nombreASM, nombre);

        //printf("\n\t\t el nombreASM de %s es %s", data->nombreASM, data->nombre);
        return data;
    }
    else
    {
        if (strcmp(tipo, CONST_STR) == 0)
        {
            contadorString++;

            data->valor.valor_str = (char *)malloc(sizeof(char) * (strlen(valString) + 1));
            strcpy(data->valor.valor_str, valString);

            char auxString[200];
            strcpy(full, "");
            reemplazarString(auxString, nombre);
            strcat(full, auxString); // "S_<nombre>"
            char numero[10];
            sprintf(numero, "_%d", contadorString);
            strcat(full, numero); // "S_<nombre>_#"

            data->nombre = (char *)malloc(sizeof(char) * (strlen(full) + 1));
            data->nombreASM = (char *)malloc(sizeof(char) * (strlen(full) + 1));
            strcpy(data->nombre, full);
            strcpy(data->nombreASM, data->nombre);
        }
        if (strcmp(tipo, CONST_INT) == 0)
        {
            if (valInt == -1)
            {
                sprintf(aux, "%s", "valorNoDeterminado");
                strcat(full, aux);
            }
            else
            {
                sprintf(aux, "%d", valInt);
                strcat(full, aux);
            }
            data->nombre = (char *)malloc(sizeof(char) * (strlen(full) + 1));
            strcpy(data->nombre, full);
            data->valor.valor_int = valInt;

            data->nombreASM = (char *)malloc(sizeof(char) * (strlen(full) + 1));

            strcpy(data->nombreASM, full);
        }
        return data;
    }
    return NULL;
}

void guardarTS()
{
    FILE *arch;
    if ((arch = fopen("ts.txt", "wt")) == NULL)
    {
        printf("\nNo se pudo crear la tabla de simbolos.\n\n");
        return;
    }
    else if (tablaTS.primero == NULL)
        return;

    fprintf(arch, "%-60s%-20s%-50s%-15s\n", "NOMBRE", "TIPO DATO", "VALOR", "LONGITUD");

    t_simbolo *aux;
    t_simbolo *tabla = tablaTS.primero;
    char linea[300];

    while (tabla)
    {
        aux = tabla;
        tabla = tabla->next;

        if (strcmp(aux->data.tipo, TIPO_INT) == 0 || strcmp(aux->data.tipo, TIPO_FLOAT) == 0 || strcmp(aux->data.tipo, TIPO_STRING) == 0)
        {
            sprintf(linea, "%-60s%-20s%-50s%-15s\n", aux->data.nombre, aux->data.tipo, "-", "-");
        }
        else if (strcmp(aux->data.tipo, CONST_INT) == 0)
        {
            sprintf(linea, "%-60s%-20s%-50d%-15d\n", aux->data.nombre, aux->data.tipo, aux->data.valor.valor_int, strlen(aux->data.nombre) - 1);
        }
        else if (strcmp(aux->data.tipo, CONST_STR) == 0)
        {
            sprintf(linea, "%-60s%-20s%-50s%-15d\n", aux->data.nombre, aux->data.tipo, aux->data.valor.valor_str, strlen(aux->data.valor.valor_str) - 2);
        }
        fprintf(arch, "%s", linea);
        free(aux);
    }
    fclose(arch);
}

t_simbolo *getLexema(const char *valor)
{
    t_simbolo *lexema;
    t_simbolo *tablaSimbolos = tablaTS.primero;

    char nombreLimpio[32];
    limpiarString(nombreLimpio, valor);
    char nombreCTE[32] = "_";
    strcat(nombreCTE, nombreLimpio);
    int esID, esCTE, esASM, esValor = -1;
    char valorFloat[32];
    while (tablaSimbolos)
    {
        esID = strcmp(tablaSimbolos->data.nombre, nombreLimpio);
        esCTE = strcmp(tablaSimbolos->data.nombre, nombreCTE);
        esASM = strcmp(tablaSimbolos->data.nombreASM, valor);
        if (strcmp(tablaSimbolos->data.tipo, CONST_STR) == 0)
        {
            esValor = strcmp(valor, tablaSimbolos->data.valor.valor_str);
        }
        if (esID == 0 || esCTE == 0 || esASM == 0 || esValor == 0)
        {
            lexema = tablaSimbolos;
            return lexema;
        }
        tablaSimbolos = tablaSimbolos->next;
    }
    printf("Hubo un error en la declaracion de datos, falto declarar %s", nombreLimpio);
    return NULL;
}

char *limpiarString(char *dest, const char *cad)
{
    int i, longitud, j = 0;
    longitud = strlen(cad);
    for (i = 0; i < longitud; i++)
    {
        if (cad[i] != '"')
        {
            dest[j] = cad[i];
            j++;
        }
    }
    dest[j] = '\0';
    return dest;
}

char *reemplazarString(char *dest, const char *cad)
{
    int i, longitud;
    longitud = strlen(cad);

    for (i = 0; i < longitud; i++)
    {
        if ((cad[i] >= 'a' && cad[i] <= 'z') || (cad[i] >= 'A' && cad[i] <= 'Z') || (cad[i] >= '0' && cad[i] <= '9'))
        {
            dest[i] = cad[i];
        }
        else
        {
            dest[i] = '_';
        }
    }
    dest[i] = '\0';

    return dest;
}