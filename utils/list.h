#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

typedef struct
{
    int indice;
    int posicion;
} t_data_list;

typedef struct s_simbolo_list
{
    t_data_list data;
    struct s_simbolo_list *next;
} t_simbolo_list;

typedef struct
{
    t_simbolo_list *primero;
} t_list;

t_list listaSimb;

int insertarLista(const int cte, const int posicion);
void limpiarLista();

int insertarLista(const int cte, const int posicion)
{
    t_simbolo_list *tabla = listaSimb.primero;

    while (tabla)
    {
        if (tabla->data.indice == cte)
        {
            return tabla->data.posicion;
        }

        if (tabla->next == NULL)
        {
            break;
        }

        tabla = tabla->next;
    }

    t_data_list *data = (t_data_list *)malloc(sizeof(t_data_list));

    data->indice = cte;
    data->posicion = posicion;

    if (data == NULL)
    {
        return -1;
    }

    t_simbolo_list *nuevo = (t_simbolo_list *)malloc(sizeof(t_simbolo_list));

    if (nuevo == NULL)
    {
        return -2;
    }

    nuevo->data = *data;
    nuevo->next = NULL;

    if (listaSimb.primero == NULL)
    {
        listaSimb.primero = nuevo;
    }
    else
    {
        tabla->next = nuevo;
    }

    return posicion;
}

void limpiarLista()
{
    t_simbolo_list *pElim = listaSimb.primero;

    while (listaSimb.primero)
    {
        listaSimb.primero = listaSimb.primero->next;
        free(pElim);
        pElim = listaSimb.primero;
    }
}