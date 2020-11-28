%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h> 
#include "./utils/tools.h"
#include "./utils/tree.h"
#include "./utils/list.h"
#include "./utils/ts.h"
#include "./utils/assembler.h"
#define YYDEBUG 0

extern int yylex();
extern int yyparse();
void yyerror(const char *s);
extern FILE* yyin;
extern int yylineno;
extern int yyleng;
extern char *yytext;
void crearNodosValidacion(int, int, int);
void validarVariablePivot(char *);
void validarVariable(char *);
void insertarEnTS(char *bufferTS, char *puntBufferTs, char* cad, char* tipo);

char bufferTS[800], bufferNombrePivot[800], bufferPosicion[800];
char *puntBufferTs, *puntBufferNombrePivot, *puntBufferPosicion;
int indicePosicion = 0, i = 0, funcionPosicion = 0, funcionRead = 0, existeLista = 0;
ast *_pWrite, *_pRead, *_pAsig, *_pPosicion, *_pCondPosicion, *_pNodoComprobacionValidacion, *_pNodoMensajeValidacion, *_pProg, *_pSent;
%}
%token id cte cte_s
%token asigna
%token para parc ca cc pyc coma
%token write read
%token posicion

%type <intVal> cte
%type <strVal> cte_s
%type <strVal> id

%start S

%union
{
    int intVal;
    float floatVal;
    char strVal[50];
    char* auxLogicOperator;
}
%%

S: 
  {
    printf("Inicia COMPILADOR\n");
}
  PROG {
        printf("\n Regla 0: S -> PROG \n");
        generarAssembler(_pProg, obtenerTS()); 
        guardarTS();
        generarArbolTXT(_pProg); 
        generarGraphviz(_pProg);
        printf("\n COMPILACION EXITOSA \n");
  }
  ;

PROG: PROG SENT {
    _pProg = newNode(PUNTO_Y_COMA, _pProg, _pSent); 
    crearNodosValidacion(funcionPosicion, funcionRead, existeLista);
    printf("\n Regla 2: PROG -> PROG SENT \n");
    }
  | SENT { _pProg = _pSent; 
          crearNodosValidacion(funcionPosicion, funcionRead, existeLista);
          printf("\n Regla 1: PROG -> SENT \n");}
  ;

SENT: READ {_pSent = _pRead; printf("\n Regla 3: SENT -> READ \n");}
  | WRITE {_pSent = _pWrite; printf("\n Regla 3: SENT -> WRITE \n");}
  | ASIG {_pSent = _pAsig; printf("\n Regla 3: SENT -> ASIG \n");}
  ;

READ: read id {
                insertarEnTS(bufferTS, puntBufferTs, $2, TIPO_INT);
                _pRead = newNode(READ_NODE, NULL ,newLeaf(puntBufferTs));
                printf("\n Regla 4: READ -> read id \n");
                funcionPosicion = 0;
                funcionRead = 1;
                }
  ;

ASIG: id asigna POSICION {
                          insertarEnTS(bufferTS, puntBufferTs, $1, TIPO_INT);
                          _pAsig = newNode("=", newLeaf(puntBufferTs) , _pPosicion );                                 
                          printf("\n Regla 5: ASIG -> id asigna POSICION \n");
                          funcionPosicion = 1;
                          funcionRead = 0;
                          }
  ;

POSICION: 
  posicion para id pyc ca {
      validarVariablePivot($3);
    } LISTA cc parc {
                      existeLista = 1;
                      aumentarContadorVariableResultado();
                      limpiarLista();
                      printf("\n Regla 6: POSICION -> posicion para id pyc ca LISTA cc parc \n");
                      }
  | posicion para id pyc ca {
                              validarVariablePivot($3);
                              } cc parc {
                                          existeLista = 0;

                                          // Pongo una hoja "valor no determinado", la cual luego sera comprobada
                                          // para determinar si la lista está vacía
                                          _pPosicion = newLeaf(VALOR_NO_DETERMINADO);

                                          printf("\n Regla 7: POSICION -> posicion para id pyc ca cc parc \n");
                                          }
  ;

LISTA: cte {
                // Inicializo la posicion en 0
                indicePosicion = 0;

                // Formateo el CTE_INT y lo inserto en la tabla de simbolos
                sprintf(bufferTS,"%d", $1);
                puntBufferTs = strtok(bufferTS,";\n");
                int numero = atoi(bufferTS);
                insertarTS(puntBufferTs, CONST_INT, "", numero, 0);

                // Inserto en la lista el lugar de ocurrencia, y dicho numero lo inserto en la TS
                sprintf(bufferPosicion,"%d", insertarLista(numero, indicePosicion));
                puntBufferPosicion = strtok(bufferPosicion,";\n");
                insertarTS(puntBufferPosicion, CONST_INT, "", insertarLista(numero, indicePosicion), 0);

                // Voy a crear la variable auxiliar @resultado..
                insertarTS(obtenerStringVariableResultado(), CONST_INT, "", 0, 0);
                
                // Nodo en el cual se verifica si el pivot coincide con el valor cte
                // En caso verdadero, entonces se deberá asignar la posicion a la variable resultado
                _pCondPosicion = newNode( IF,
                 newNode("=", newLeaf(puntBufferNombrePivot) , newLeaf( puntBufferTs )) ,
                 newNode("=", newLeaf(obtenerStringVariableResultadoTS()) , newLeaf( puntBufferPosicion ))
                 );

                // Creo un nuevo nodo                        
                _pPosicion = newNode(PUNTO_Y_COMA, newNode("=", newLeaf(obtenerStringVariableResultadoTS()) , newLeaf( VALOR_NO_DETERMINADO )), _pCondPosicion);

                printf("\n Regla 8: LISTA -> cte \n");
                }
  | LISTA coma cte {
                        // Aumento la posicion
                        indicePosicion++;

                        // Formateo el CTE_INT y lo inserto en la tabla de simbolos
                        sprintf(bufferTS,"%d", $3);
                        puntBufferTs = strtok(bufferTS,";\n");
                        int numero = atoi(bufferTS);
                        insertarTS(puntBufferTs, CONST_INT, "", numero, 0);
                                               
                        // Agrego el elemento de la posicion la TS (para luego poder utilizarlo)
                        sprintf(bufferPosicion,"%d", insertarLista(numero, indicePosicion));
                        puntBufferPosicion = strtok(bufferPosicion,";\n");
                        insertarTS(puntBufferPosicion, CONST_INT, "", insertarLista(numero, indicePosicion), 0);
                        
                        // Nodo en el cual se verifica si el pivot coincide con el valor cte
                        // En caso verdadero, entonces se deberá asignar la posicion a la variable resultado
                        _pCondPosicion = newNode( IF, newNode("=", newLeaf(puntBufferNombrePivot) , newLeaf( puntBufferTs ) ) , newNode("=", newLeaf(obtenerStringVariableResultadoTS()) , newLeaf( puntBufferPosicion ) ));

                        // Creo un nuevo nodo
                        _pPosicion = newNode(PUNTO_Y_COMA, _pPosicion , _pCondPosicion );

                        printf("\n Regla 9: LISTA -> LISTA coma cte \n");
                        }
  ;

WRITE: write cte_s {
                            sprintf(bufferTS,"%s", $2);
                            puntBufferTs = strtok(bufferTS,";\n");
                            insertarTS(puntBufferTs, CONST_STR, puntBufferTs, 0, 0);
                            _pWrite = newNode(WRITE_NODE, NULL, newLeaf(puntBufferTs));
                            printf("\n Regla 10: WRITE -> write cte_s \n");
                            funcionPosicion = 0;
                            funcionRead = 0;
                          }
  | write id {
                validarVariable($2);
                _pWrite = newNode(WRITE_NODE, NULL, newLeaf(puntBufferTs));
                printf("\n Regla 11: WRITE -> write id \n");
                funcionPosicion = 0;
                funcionRead = 0;
              }
  ;

%%

int main(int argc, char *argv[])
{
    if ((yyin = fopen(argv[1], "rt")) == NULL)
    {
        printf("\nNo se puede abrir el archivo: %s\n", argv[1]);
    }
    else
    {
        inicializarTS();
        yyparse();
    }

    fclose(yyin);

    return 0;
}

void yyerror(const char *str)
{
    fprintf(stderr, "Error: %s en la linea %d\n", str, yylineno);
    system("Pause");
    exit(1);
}

void crearNodosValidacion(int funcionPosicion, int funcionRead, int existeLista)
{
    if (funcionPosicion)
    {
        _pNodoComprobacionValidacion = newNode("=", newLeaf(puntBufferTs), newLeaf(VALOR_NO_DETERMINADO));
        if (existeLista)
        {
            _pNodoMensajeValidacion = newNode(WRITE_NODE, NULL, newLeaf(ELEMENTO_NO_ENCONTRADO));
        }
        else
        {
            _pNodoMensajeValidacion = newNode(WRITE_NODE, NULL, newLeaf(LISTA_VACIA));
        }

        _pProg = newNode(PUNTO_Y_COMA, _pProg, newNode(IF, _pNodoComprobacionValidacion, _pNodoMensajeValidacion));
    }
    else if (funcionRead)
    {
        _pNodoComprobacionValidacion = newNode("<", newLeaf(puntBufferTs), newLeaf("_1"));

        _pNodoMensajeValidacion = newNode(WRITE_NODE, NULL, newLeaf(EL_VALOR_DEBE_SER_MAYOR_O_IGUAL_A_1));

        _pProg = newNode(PUNTO_Y_COMA, _pProg, newNode(IF, _pNodoComprobacionValidacion, _pNodoMensajeValidacion));
    }
}

void validarVariablePivot(char *cad)
{
    sprintf(bufferNombrePivot, "%s", cad);
    puntBufferNombrePivot = strtok(bufferNombrePivot, " ;\n");

    // En caso de que no exista el pivot, debo detener la ejecución
    if (insertarTS(puntBufferNombrePivot, TIPO_INT, "", 0, 0) == 0)
    {
        fprintf(stdout, "%s%s%s", "\nError: la variable '", puntBufferNombrePivot, "' no fue declarada\n");
        system("Pause");
        exit(1);
    }
}

void validarVariable(char *cad)
{
    sprintf(bufferTS, "%s", cad);
    puntBufferTs = strtok(bufferTS, " ;\n");

    // En caso de que no exista el pivot, debo detener la ejecución
    if (insertarTS(puntBufferTs, TIPO_INT, "", 0, 0) == 0)
    {
        fprintf(stdout, "%s%s%s", "\nError: la variable '", puntBufferTs, "' no fue declarada\n");
        system("Pause");
        exit(1);
    }
}

void insertarEnTS(char *buffer, char *puntBuffer, char *cad, char *tipo)
{
    sprintf(bufferTS, "%s", cad);
    puntBuffer = strtok(bufferTS, " ;\n");

    if (strcmp(tipo, TIPO_INT) == 0)
    {
        if (insertarTS(puntBuffer, tipo, "", 0, 0) != 0)
        {
            fprintf(stdout, "%s%s%s", "Error: la variable '", puntBuffer, "' ya fue declarada");
        }
    }
}