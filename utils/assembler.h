#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

void generarAssembler(ast *_pProg, t_tabla *tablaTS);
void generaHeader(FILE *);
void crearSeccionData(FILE *, t_tabla *);
void crearSeccionCode(FILE *);
void generaFooter(FILE *);
void recorrerArbol(ast *, FILE *);
void generarAssemblerAsignacion(ast *root, FILE *archAssembler);
void generarAssemblerAsignacionSimple(ast *root, FILE *archAssembler);

int branchN = 0, branchElementoNoEncontrado = 0, branchPivotMenorAUno = 0, resulAsignadoConValorNoDeterminado = 0;
char tempBufferResultado[800];

void generarAssembler(ast *_pProg, t_tabla *tablaTS)
{
    FILE *file = fopen(NOMBRE_ARCHIVO_ASM, "w");
    if (file == NULL)
    {
        printf("No se pudo crear el archivo final.asm \n");
        exit(1);
    }
    generaHeader(file);
    crearSeccionData(file, tablaTS);
    crearSeccionCode(file);
    recorrerArbol(_pProg, file);
    generaFooter(file);
    fclose(file);
}
void generaHeader(FILE *f)
{
    fprintf(f, "include macros.asm\n");
    fprintf(f, "include macros2.asm\n");
    fprintf(f, "include number.asm\n\n");
    fprintf(f, ".MODEL LARGE\n");
    fprintf(f, ".386\n");
    fprintf(f, ".STACK 200h\n");
    fprintf(f, "\n");
}

void recorrerArbol(ast *root, FILE *archAssembler)
{
    int fueAsignacion = 0, fueValidacionListaVacia = 0;

    // En caso de que exista un nodo por izquierda, se sigue el recorrido (de forma recursiva)
    if (root->left != NULL)
    {
        recorrerArbol(root->left, archAssembler);
    }

    if ((strcmp(root->value, PUNTO_Y_COMA) == 0))
    {
        // Caso utilizado
        if (root->right && root->right->right && root->right->right->value && strcmp(root->right->right->value, VALOR_NO_DETERMINADO) == 0)
        {
            fueValidacionListaVacia = 1;
            t_simbolo *lexema = getLexema(root->right->right->value);

            // Cargo el lado derecho (con el valor no determinado)
            fprintf(archAssembler, "FLD %s\n", lexema->data.nombreASM);
            lexema = getLexema(root->right->left->value);
            // Lo guardo en @resultado..
            fprintf(archAssembler, "FSTP %s\n", lexema->data.nombreASM);
        }
    }
    else if (strcmp(root->value, WRITE_NODE) == 0)
    {
        t_simbolo *lexema = getLexema(root->right->value);
        if (strcmp(lexema->data.tipo, CONST_STR) == 0)
        {
            // Utilizo el macro para mostrar strings
            fprintf(archAssembler, "displayString %s\nNEWLINE\n", lexema->data.nombreASM);

            // En caso de que me encuentre en el write correspondiente a "Elemento no encontrado"
            if (branchElementoNoEncontrado)
            {
                branchElementoNoEncontrado = 0;
                // Realizo un salto incondicional al final del programa
                fprintf(archAssembler, "JMP FOOTER\nNEWLINE\n");
                fprintf(archAssembler, "branch%d:\n", branchN); //aca cae si dio false
                branchN++;
            }
            // En caso de que me encuentre en el write correspondiente a "Pivot menor a uno"
            else if (branchPivotMenorAUno)
            {
                branchPivotMenorAUno = 0;
                // Realizo un salto incondicional al final del programa
                fprintf(archAssembler, "JMP FOOTER\nNEWLINE\n");
                fprintf(archAssembler, "branch%d:\n", branchN); //aca cae si dio false
                branchN++;
            }
            else if (strcmp(lexema->data.valor.valor_str, LISTA_VACIA) == 0)
            {
                // Realizo un salto incondicional al final del programa
                fprintf(archAssembler, "JMP FOOTER\nNEWLINE\n");
                fprintf(archAssembler, "branch%d:\n", branchN); //aca cae si dio false
                branchN++;
            }
        }
        else
        {
            // Caso que se utiliza al imprimir las variables
            fprintf(archAssembler, "FLD %s\n", lexema->data.nombreASM);
            // Debo agregar el 1, de forma tal que se sume al valor cargado en la linea anterior
            // De esta forma, se podra visualizar los resultados con el numero sin indice arrancando en 0.
            fprintf(archAssembler, "FLD _1\n");
            fprintf(archAssembler, "FADD\n");
            // Lo almaceno en la variable que ya tenia
            fprintf(archAssembler, "FSTP %s\n", lexema->data.nombreASM);
            // Muestro la posición en la cual se encontró el pivot
            fprintf(archAssembler, "DisplayFloat %s,1\nNEWLINE\n", lexema->data.nombreASM);
        }
    }
    else if (strcmp(root->value, READ_NODE) == 0)
    {
        t_simbolo *lexema = getLexema(root->right->value);
        // En el caso de estar en un nodo READ, debo leer un numero de tipo FLOAT
        fprintf(archAssembler, "GetFloat %s\nNEWLINE\n", lexema->data.nombreASM);
    }
    else if (strcmp(root->value, "=") == 0)
    {
        fueAsignacion = 1;

        // Solamente entro aca si ya entre al menos una vez al codigo de posicion
        // De esta forma, puedo asignar correctamente la variable resul
        if (strcmp(root->right->value, VALOR_NO_DETERMINADO) == 0 && resulAsignadoConValorNoDeterminado)
        {
            // Cargo el lado izquierdo en la variable @ifI
            t_simbolo *lexemaI = getLexema(root->left->value);
            fprintf(archAssembler, "FLD %s\n", lexemaI->data.nombreASM);
            fprintf(archAssembler, "FSTP @ifI\n");

            // Cargo el lado derecho en la variable @ifD
            t_simbolo *lexemaD = getLexema(root->right->value);
            fprintf(archAssembler, "FLD %s\n", lexemaD->data.nombreASM);
            fprintf(archAssembler, "FSTP @ifD\n");

            // Cargo ambos valores
            fprintf(archAssembler, "FLD @ifI\n");
            fprintf(archAssembler, "FLD @ifD\n");

            // Intercambio posiciones, comparo y paso las flags
            fprintf(archAssembler, "FXCH\n");
            fprintf(archAssembler, "FCOM \n");
            fprintf(archAssembler, "FSTSW AX\nSAHF\n");

            // En caso de que no sea igual (es decir, el elemento analizado no es igual al pivot) debo realizar un salto
            fprintf(archAssembler, "JNE branch%d\n", branchN);

            // En la proxima iteración, se arma el código para "Elemento no encontrado"
            branchElementoNoEncontrado = 1;
        }
        else if (strcmp(root->right->value, "=") == 0)
        {
            // Cargo la variable derecha
            t_simbolo *lexema = getLexema(root->right->right->value);
            fprintf(archAssembler, "FLD %s\n", lexema->data.nombreASM);

            // La almaceno en la izquierda
            lexema = getLexema(root->left->value);
            fprintf(archAssembler, "FSTP %s\n", lexema->data.nombreASM);
        }
        else if (strcmp(root->right->value, PUNTO_Y_COMA) == 0)
        {
            generarAssemblerAsignacion(root->right, archAssembler);
            // Luego de generar el codigo para asignación, almaceno en el nodo izquierdo
            t_simbolo *lexema = getLexema(root->left->value);
            fprintf(archAssembler, "FSTP %s\n", lexema->data.nombreASM);
        }
        else
        {
            if (strcmp(root->right->value, VALOR_NO_DETERMINADO) == 0)
            {
                resulAsignadoConValorNoDeterminado = 1;
            }
            generarAssemblerAsignacionSimple(root, archAssembler);
        }
    }
    else if (strcmp(root->value, "<") == 0)
    {
        if (strcmp(root->right->value, "_1") == 0)
        {
            // Cargo el lado izquierdo en la variable @ifI
            t_simbolo *lexemaI = getLexema(root->left->value);
            fprintf(archAssembler, "FLD %s\n", lexemaI->data.nombreASM);
            fprintf(archAssembler, "FSTP @ifI\n");

            // Cargo el lado derecho en la variable @ifD
            t_simbolo *lexemaD = getLexema(root->right->value);
            fprintf(archAssembler, "FLD %s\n", lexemaD->data.nombreASM);
            fprintf(archAssembler, "FSTP @ifD\n");

            // Cargo ambos valores
            fprintf(archAssembler, "FLD @ifI\n");
            fprintf(archAssembler, "FLD @ifD\n");

            // Intercambio posiciones, comparo y paso las flags
            fprintf(archAssembler, "FXCH\n");
            fprintf(archAssembler, "FCOM \n");
            fprintf(archAssembler, "FSTSW AX\nSAHF\n");

            // En caso de que sea mayor o igual a 1 debo realizar un salto
            fprintf(archAssembler, "JAE branch%d\n", branchN);

            // En la proxima iteración, se arma el código para "Pivot menor a uno"
            branchPivotMenorAUno = 1;
        }
    }

    // En caso de tener nodo a derecha y que actualmente no tengo asignacion o validacion de lista vacia, continuo explorando el arbol
    if ((root->right != NULL) && !(fueAsignacion) && !(fueValidacionListaVacia))
    {
        recorrerArbol(root->right, archAssembler);
    }
}

void generarAssemblerAsignacionSimple(ast *root, FILE *archAssembler)
{
    t_simbolo *lexema = getLexema(root->right->value);

    // Cargo la variable del lado derecho
    fprintf(archAssembler, "FLD %s\n", lexema->data.nombreASM);
    lexema = getLexema(root->left->value);
    // La almaceno del lado izquierdo
    fprintf(archAssembler, "FSTP %s\n", lexema->data.nombreASM);

    // En caso de ser una de las variables @resultado..
    if (strstr(lexema->data.nombreASM, "__@resultado"))
    {
        // Debo actualizar el buffer temporal con el string
        // De esta forma, en las siguientes iteraciones sé a que @resultado debo asignar los resultados del proceso
        sprintf(tempBufferResultado, "%s", strstr(lexema->data.nombreASM, "__@resultado"));
    }
}

void generarAssemblerPosicion(ast *root, FILE *archAssembler)
{
    if (strcmp(root->value, "=") == 0)
    {
        if (strcmp(root->right->value, VALOR_NO_DETERMINADO) == 0)
        {
            resulAsignadoConValorNoDeterminado = 1;
            generarAssemblerAsignacionSimple(root, archAssembler);
        }
    }
    else
    {
        if (root->left != NULL)
        {
            generarAssemblerPosicion(root->left, archAssembler);
        }
        if (strcmp(root->value, IF) == 0)
        {
            // Cargo el lado izquierdo en la variable @ifI
            t_simbolo *lexemaI = getLexema(root->left->left->value);
            fprintf(archAssembler, "FLD %s\n", lexemaI->data.nombreASM);
            fprintf(archAssembler, "FSTP @ifI\n");

            // Cargo el lado derecho en la variable @ifD
            t_simbolo *lexemaD = getLexema(root->left->right->value);
            fprintf(archAssembler, "FLD %s\n", lexemaD->data.nombreASM);
            fprintf(archAssembler, "FSTP @ifD\n");

            // Cargo ambos valores
            fprintf(archAssembler, "FLD @ifI\n");
            fprintf(archAssembler, "FLD @ifD\n");

            // Intercambio posiciones, comparo y paso las flags
            fprintf(archAssembler, "FXCH\n");
            fprintf(archAssembler, "FCOM \n");
            fprintf(archAssembler, "FSTSW AX\nSAHF\n");

            // En caso de que no sea igual (es decir, el elemento analizado no es igual al pivot) debo realizar un salto
            fprintf(archAssembler, "JNE branch%d\n", branchN);

            // Si son iguales, entonces asigno el valor a mi variable @resultado..
            generarAssemblerAsignacionSimple(root->right, archAssembler);

            // Continuo, en caso de que sea falso
            fprintf(archAssembler, "branch%d:\n", branchN);

            // Aumento el contador de branch
            branchN++;
        }
        else if (root->right != NULL)
        {
            generarAssemblerPosicion(root->right, archAssembler);
        }
    }
}

void crearSeccionData(FILE *archAssembler, t_tabla *tablaTS)
{
    t_simbolo *aux;
    t_simbolo *tablaSimbolos = tablaTS->primero;

    fprintf(archAssembler, "%s\n\n", ".DATA");

    // Tomo la tabla de simbolos y voy armando el codigo para cada entrada
    while (tablaSimbolos)
    {
        aux = tablaSimbolos;
        tablaSimbolos = tablaSimbolos->next;
        if (strcmp(aux->data.tipo, TIPO_INT) == 0)
        {
            fprintf(archAssembler, "%-50s%-15s%-15s\n", aux->data.nombre, "dd", "?");
        }
        else if (strcmp(aux->data.tipo, TIPO_FLOAT) == 0)
        {
            fprintf(archAssembler, "%-50s%-15s%-15s\n", aux->data.nombreASM, "dd", "?");
        }
        else if (strcmp(aux->data.tipo, TIPO_STRING) == 0)
        {
            fprintf(archAssembler, "%-50s%-15s%-15s\n", aux->data.nombreASM, "db", "?");
        }
        else if (strcmp(aux->data.tipo, CONST_INT) == 0)
        {
            char valor[50];
            sprintf(valor, "%d.0", aux->data.valor.valor_int);
            fprintf(archAssembler, "%-50s%-15s%-15s\n", aux->data.nombreASM, "dd", valor);
        }
        else if (strcmp(aux->data.tipo, CONST_STR) == 0)
        {
            char valor[200];
            sprintf(valor, "%s, '$', %d dup (?)", aux->data.valor.valor_str, strlen(aux->data.valor.valor_str) - 2);
            fprintf(archAssembler, "%-50s%-15s%-15s\n", aux->data.nombreASM, "db", valor);
        }
    }

    // Utilizaré dos variables auxiliares para hacer de forma más práctica las comparaciones
    fprintf(archAssembler, "%-50s%-15s%-15s%-15s\n", "@ifI", "dd", "?", "; Variable para condición izquierda");
    fprintf(archAssembler, "%-50s%-15s%-15s%-15s\n", "@ifD", "dd", "?", "; Variable para condición derecha");
}

void generarAssemblerAsignacion(ast *root, FILE *archAssembler)
{
    generarAssemblerPosicion(root, archAssembler);
    fprintf(archAssembler, "FLD %s\n", tempBufferResultado);
}

void crearSeccionCode(FILE *archAssembler)
{
    fprintf(archAssembler, "\n%s\n\n%s\n\n", ".CODE", "inicio:");
    fprintf(archAssembler, "%-30s\n", "MOV AX,@DATA");
    fprintf(archAssembler, "%-30s\n%-30s\n\n", "MOV DS,AX", "MOV ES,AX");
}
void generaFooter(FILE *archAssembler)
{
    fprintf(archAssembler, "FOOTER:");
    fprintf(archAssembler, "\n%s\n", "MOV AX,4C00h");
    fprintf(archAssembler, "%s\n\n%s", "INT 21h", "END inicio");
}