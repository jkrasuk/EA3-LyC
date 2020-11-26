#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

void generarAssembler(ast *_pProg, t_tabla *tablaTS);
void generaHeader(FILE *);
void crearSeccionData(FILE *, t_tabla *);
void crearSeccionCode(FILE *);
void generaFooter(FILE *);
void recorrerArbol(ast *, FILE *);
void generarAssemblerAsignacion(ast *root, FILE *archAssembler);
void generarAssemblerAsignacionSimple(ast *root, FILE *archAssembler);

int branchN = 0, branchElementoNoEncontrado = 0, branchPivotMenorAUno = 0;

void generarAssembler(ast *_pProg, t_tabla *tablaTS)
{
    FILE *file = fopen("Final.asm", "w");
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
    bool fueAsignacion = false;
    bool fueValidacionListaVacia = false;

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
            fueValidacionListaVacia = true;
            t_simbolo *lexema = getLexema(root->right->right->value);

            fprintf(archAssembler, "fld %s\n", lexema->data.nombreASM); //cargo el lado derecho
            lexema = getLexema(root->right->left->value);
            fprintf(archAssembler, "fstp %s\n", lexema->data.nombreASM); //lo guardo en la variable del lado izquierdo
        }
    }
    else if (strcmp(root->value, WRITE_NODE) == 0)
    {
        t_simbolo *lexema = getLexema(root->right->value);
        if (strcmp(lexema->data.tipo, CONST_STR) == 0)
        {
            fprintf(archAssembler, "displayString %s\nNEWLINE\n", lexema->data.nombreASM);
            if (branchElementoNoEncontrado)
            {
                branchElementoNoEncontrado = 0;
                fprintf(archAssembler, "JMP FOOTER\nNEWLINE\n");
                fprintf(archAssembler, "branch%d:\n", branchN); //aca cae si dio false
                branchN++;
            }
            else if (branchPivotMenorAUno)
            {
                branchPivotMenorAUno = 0;
                fprintf(archAssembler, "JMP FOOTER\nNEWLINE\n");
                fprintf(archAssembler, "branch%d:\n", branchN); //aca cae si dio false
                branchN++;
            }
        }
        else
        {
            fprintf(archAssembler, "fld %s\n", lexema->data.nombreASM);  //cargo el lado derecho
            fprintf(archAssembler, "fld _1\n");                          //cargo el lado derecho
            fprintf(archAssembler, "FADD\n");                            //Sumo
            fprintf(archAssembler, "fstp %s\n", lexema->data.nombreASM); //Sumo
            fprintf(archAssembler, "DisplayFloat %s,1\nNEWLINE\n", lexema->data.nombreASM);
        }
    }
    else if (strcmp(root->value, READ_NODE) == 0)
    {
        t_simbolo *lexema = getLexema(root->right->value);
        fprintf(archAssembler, "GetFloat %s\nNEWLINE\n", lexema->data.nombreASM); //directamente levanto un float porque sino rompe la division
    }
    else if (strcmp(root->value, "=") == 0)
    {
        fueAsignacion = true;

        if (strcmp(root->right->value, VALOR_NO_DETERMINADO) == 0)
        {
            fprintf(archAssembler, "\n;Validacion de elemento no encontrado\n");
            t_simbolo *lexemaI = getLexema(root->left->value);
            fprintf(archAssembler, "fld %s\n", lexemaI->data.nombreASM);
            fprintf(archAssembler, "fstp @ifI\n");
            t_simbolo *lexemaD = getLexema(root->right->value);
            fprintf(archAssembler, "fld %s\n", lexemaD->data.nombreASM);
            fprintf(archAssembler, "fstp @ifD\n");
            fprintf(archAssembler, "fld @ifI\n");              //carga @ifI
            fprintf(archAssembler, "fld @ifD\n");              //carga @ifD
            fprintf(archAssembler, "fxch\n");                  //intercambia las posiciones 0 y 1
            fprintf(archAssembler, "fcom \n");                 //compara
            fprintf(archAssembler, "fstsw AX\nsahf\n");        //no se si porque sentencia es necesaria
            fprintf(archAssembler, "jne branch%d\n", branchN); // si dio false, salteate lo siguiente
            branchElementoNoEncontrado = 1;
        }
        else if (strcmp(root->right->value, "=") == 0)
        {
            //cuando el maximo contiene un solo elemento es mas facil poner el codigo aca que llamar a las otras funciones.
            t_simbolo *lexema = getLexema(root->right->right->value);
            fprintf(archAssembler, "fld %s\n", lexema->data.nombreASM); //cargo el lado derecho
            lexema = getLexema(root->left->value);
            fprintf(archAssembler, "fstp %s\n", lexema->data.nombreASM); //lo guardo en la variable del lado izquierdo
        }
        else if (strcmp(root->right->value, PUNTO_Y_COMA) == 0)
        {
            generarAssemblerAsignacion(root->right, archAssembler);
            t_simbolo *lexema = getLexema(root->left->value);
            fprintf(archAssembler, "fstp %s\n", lexema->data.nombreASM);
        }
        else
        {
            generarAssemblerAsignacionSimple(root, archAssembler);
        }
    }
    else if (strcmp(root->value, "<") == 0)
    {
        if (strcmp(root->right->value, "_1") == 0)
        {
            fprintf(archAssembler, "\n;Validacion de pivot mayor o igual a 1\n");
            t_simbolo *lexemaI = getLexema(root->left->value);
            fprintf(archAssembler, "fld %s\n", lexemaI->data.nombreASM);
            fprintf(archAssembler, "fstp @ifI\n");
            t_simbolo *lexemaD = getLexema(root->right->value);
            fprintf(archAssembler, "fld %s\n", lexemaD->data.nombreASM);
            fprintf(archAssembler, "fstp @ifD\n");
            fprintf(archAssembler, "fld @ifI\n");              //carga @ifI
            fprintf(archAssembler, "fld @ifD\n");              //carga @ifD
            fprintf(archAssembler, "fxch\n");                  //intercambia las posiciones 0 y 1
            fprintf(archAssembler, "fcom \n");                 //compara
            fprintf(archAssembler, "fstsw AX\nsahf\n");        //no se si porque sentencia es necesaria
            fprintf(archAssembler, "JAE branch%d\n", branchN); // si dio false, salteate lo siguiente
            branchPivotMenorAUno = 1;
        }
    }

    if ((root->right != NULL) && !(fueAsignacion) && !(fueValidacionListaVacia))
    {
        recorrerArbol(root->right, archAssembler);
    }
}

void generarAssemblerAsignacionSimple(ast *root, FILE *archAssembler)
{
    t_simbolo *lexema = getLexema(root->right->value);

    fprintf(archAssembler, "fld %s\n", lexema->data.nombreASM); //cargo el lado derecho
    lexema = getLexema(root->left->value);
    fprintf(archAssembler, "fstp %s\n", lexema->data.nombreASM); //lo guardo en la variable del lado izquierdo
}

void generarAssemblerMax(ast *root, FILE *archAssembler)
{
    if (strcmp(root->value, "=") == 0)
    {
        if (strcmp(root->right->value, VALOR_NO_DETERMINADO) == 0)
        {
            fprintf(archAssembler, "\n;Comienza el codigo de posicion\n");
            generarAssemblerAsignacionSimple(root, archAssembler);
        }
    }
    else
    {

        if (root->left != NULL)
        {
            generarAssemblerMax(root->left, archAssembler);
        }
        if (strcmp(root->value, IF) == 0)
        {
            fprintf(archAssembler, "\n;Codigo if\n");
            // printf("izq izq es %s", root->left->left->value  );
            t_simbolo *lexemaI = getLexema(root->left->left->value);
            fprintf(archAssembler, "fld %s\n", lexemaI->data.nombreASM);
            fprintf(archAssembler, "fstp @ifI\n");
            // printf("izq der es %s", root->left->right->value  );
            t_simbolo *lexemaD = getLexema(root->left->right->value);
            fprintf(archAssembler, "fld %s\n", lexemaD->data.nombreASM);
            fprintf(archAssembler, "fstp @ifD\n");
            fprintf(archAssembler, "fld @ifI\n");                         //carga @ifI
            fprintf(archAssembler, "fld @ifD\n");                         //carga @ifD
            fprintf(archAssembler, "fxch\n");                             //intercambia las posiciones 0 y 1
            fprintf(archAssembler, "fcom \n");                            //compara
            fprintf(archAssembler, "fstsw AX\nsahf\n");                   //no se si porque sentencia es necesaria
            fprintf(archAssembler, "jne branch%d\n", branchN);            // si dio false, salteate lo siguiente
            generarAssemblerAsignacionSimple(root->right, archAssembler); //como se que siempre va ser una asignacion ya le llamo esto
            fprintf(archAssembler, "branch%d:\n", branchN);               //aca cae si dio false
            branchN++;                                                    //sumo el numero de branch
        }
        else if (root->right != NULL)
        {
            generarAssemblerMax(root->right, archAssembler);
        }
    }
}

void crearSeccionData(FILE *archAssembler, t_tabla *tablaTS)
{
    t_simbolo *aux;
    t_simbolo *tablaSimbolos = tablaTS->primero;

    fprintf(archAssembler, "%s\n\n", ".DATA");

    while (tablaSimbolos)
    {
        aux = tablaSimbolos;
        tablaSimbolos = tablaSimbolos->next;
        if (strcmp(aux->data.tipo, "INT") == 0)
        {
            fprintf(archAssembler, "%-50s%-15s%-15s\n", aux->data.nombre, "dd", "?");
        }
        else if (strcmp(aux->data.tipo, "FLOAT") == 0)
        {
            fprintf(archAssembler, "%-50s%-15s%-15s\n", aux->data.nombreASM, "dd", "?");
        }
        else if (strcmp(aux->data.tipo, "STRING") == 0)
        {
            fprintf(archAssembler, "%-50s%-15s%-15s\n", aux->data.nombreASM, "db", "?");
        }
        else if (strcmp(aux->data.tipo, CONST_INT) == 0)
        {
            char valor[50];
            sprintf(valor, "%d.0", aux->data.valor.valor_int);
            fprintf(archAssembler, "%-50s%-15s%-15s\n", aux->data.nombreASM, "dd", valor);
        }
        else if (strcmp(aux->data.tipo, "CONST_REAL") == 0)
        {
            char valor[50];
            sprintf(valor, "%g", aux->data.valor.valor_double);
            fprintf(archAssembler, "%-50s%-15s%-15s\n", aux->data.nombreASM, "dd", valor);
        }
        else if (strcmp(aux->data.tipo, CONST_STR) == 0)
        {
            char valor[200];
            sprintf(valor, "%s, '$', %d dup (?)", aux->data.valor.valor_str, strlen(aux->data.valor.valor_str) - 2);
            fprintf(archAssembler, "%-50s%-15s%-15s\n", aux->data.nombreASM, "db", valor);
        }
    }
    fprintf(archAssembler, "%-50s%-15s%-15s%-15s\n", "@ifI", "dd", "?", "; Variable para condición izquierda");
    fprintf(archAssembler, "%-50s%-15s%-15s%-15s\n", "@ifD", "dd", "?", "; Variable para condición derecha");
}

void generarAssemblerAsignacion(ast *root, FILE *archAssembler)
{
    generarAssemblerMax(root, archAssembler);
    fprintf(archAssembler, "fld @resultado\n");
}

void crearSeccionCode(FILE *archAssembler)
{
    fprintf(archAssembler, "\n%s\n\n%s\n\n", ".CODE", "inicio:");
    fprintf(archAssembler, "%-30s%-30s\n", "mov AX,@DATA", "; Inicializa el segmento de datos");
    fprintf(archAssembler, "%-30s\n%-30s\n\n", "mov DS,AX", "mov ES,AX");
}
void generaFooter(FILE *archAssembler)
{
    fprintf(archAssembler, "FOOTER:");
    fprintf(archAssembler, "\n%-30s\n", "mov AX,4C00h");
    fprintf(archAssembler, "%s\n\n%s", "int 21h", "END inicio");
}