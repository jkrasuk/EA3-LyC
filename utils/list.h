#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

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

// Utilizado para saber la primera aparición de un número en el vector de valores
int insertarLista(const int cte, const int posicion)
{
    t_simbolo_list *lista = listaSimb.primero;

    // Primero, recorro la lista para ver si ya existe
    while (lista)
    {
        // En caso de que el numero ya este archivado en la lista, retorno la propiedad "posicion"
        if (lista->data.indice == cte)
        {
            return lista->data.posicion;
        }

        if (lista->next == NULL)
        {
            break;
        }

        lista = lista->next;
    }

    // Si no lo encontre, procedo a la creacion
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
        lista->next = nuevo;
    }

    return posicion;
}

// Una vez que ya termine todo el procesamiento, debo vaciar la lista
// De esta forma, si hay alguna otra funcion posicion, no se retornan los indices viejos
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