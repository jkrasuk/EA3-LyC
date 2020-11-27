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

char bufferTS[800], bufferNombrePivot[800], bufferPosicion[800];
char *puntBufferTs, *puntBufferNombrePivot, *puntBufferPosicion;
int indicePosicion = 0, i = 0, funcionPosicion = 0, funcionRead = 0, tengoLista = 0;
ast *_write, *_read, *_asig, *_posicion, *_condPosicion, *_nodoComprobacionValidacion, *_nodoMensajeValidacion, *_pProg, *_pSent;
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
        generarAssembler(_pProg, obtenerTablaTS()); 
        guardarTS();
        print2D(_pProg); 
        generarGraphviz(_pProg);
        printf("\n COMPILACION EXITOSA \n");
  }
  ;

PROG: PROG SENT {
    _pProg = newNode(PUNTO_Y_COMA, _pProg, _pSent); 
    
    if(funcionPosicion)
    {
        _nodoComprobacionValidacion = newNode("=", newLeaf(puntBufferTs), newLeaf(VALOR_NO_DETERMINADO));
        if(tengoLista)
        {
            _nodoMensajeValidacion = newNode(WRITE_NODE, NULL, newLeaf(ELEMENTO_NO_ENCONTRADO));
        }
        else
        {
            _nodoMensajeValidacion = newNode(WRITE_NODE, NULL, newLeaf(LISTA_VACIA));
        }

        _pProg = newNode(PUNTO_Y_COMA, _pProg, newNode(IF, _nodoComprobacionValidacion, _nodoMensajeValidacion));
    }
    else if(funcionRead)
    {
        _nodoComprobacionValidacion = newNode("<", newLeaf(puntBufferTs), newLeaf("_1"));
        _nodoMensajeValidacion = newNode(WRITE_NODE, NULL, newLeaf(EL_VALOR_DEBE_SER_MAYOR_O_IGUAL_A_1));
        _pProg = newNode(PUNTO_Y_COMA, _pProg, newNode(IF, _nodoComprobacionValidacion, _nodoMensajeValidacion));
    }

    printf("\n Regla 2: PROG -> PROG SENT \n");
    }
  | SENT {_pProg = _pSent; printf("\n Regla 1: PROG -> SENT \n");}
  ;

SENT: READ {_pSent = _read; printf("\n Regla 3: SENT -> READ \n");}
  | WRITE {_pSent = _write; printf("\n Regla 3: SENT -> WRITE \n");}
  | ASIG {_pSent = _asig; printf("\n Regla 3: SENT -> ASIG \n");}
  ;

READ: read id {
                sprintf(bufferTS,"%s", $2);
                puntBufferTs = strtok(bufferTS, " ;\n"); 
                if(insertarTS(puntBufferTs, TIPO_INT, "", 0, 0) != 0)
                {
                  fprintf(stdout, "%s%s%s", "Error: la variable '", puntBufferTs, "' ya fue declarada");
                }
                _read = newNode(READ_NODE, NULL ,newLeaf(puntBufferTs));
                printf("\n Regla 4: READ -> read id \n");
                funcionPosicion = 0;
                funcionRead = 1;
                }
  ;

ASIG: id asigna POSICION {
                          sprintf(bufferTS,"%s", $1);
                          puntBufferTs = strtok(bufferTS, " ;\n"); 
                          if(insertarTS(puntBufferTs, TIPO_INT, "", 0, 0) != 0)
                          {
                            fprintf(stdout, "%s%s%s", "Error: la variable '", puntBufferTs, "' ya fue declarada");
                          }
                          _asig = newNode("=", newLeaf(puntBufferTs) , _posicion );                                 
                          printf("\n Regla 5: ASIG -> id asigna POSICION \n");
                          funcionPosicion = 1;
                          funcionRead = 0;
                          }
  ;

POSICION: 
  posicion para id pyc ca {sprintf(bufferNombrePivot,"%s", $3); puntBufferNombrePivot = strtok(bufferNombrePivot, " ;\n");} LISTA cc parc {
    tengoLista = 1; aumentarContadorVariableResultado(); limpiarLista(); printf("\n Regla 6: POSICION -> posicion para id pyc ca LISTA cc parc \n");}
  | posicion para id pyc ca {sprintf(bufferNombrePivot,"%s", $3); puntBufferNombrePivot = strtok(bufferNombrePivot, " ;\n");} cc parc {
    tengoLista = 0;
    _posicion = newLeaf(VALOR_NO_DETERMINADO);

    printf("\n Regla 7: POSICION -> posicion para id pyc ca cc parc \n");}
  ;

LISTA: cte {
                // Inicializo la posicion en 0
                indicePosicion = 0;
                sprintf(bufferPosicion,"%d", indicePosicion);
                puntBufferPosicion = strtok(bufferPosicion,";\n");

                // Formateo el CTE_INT y lo inserto en la tabla de simbolos
                sprintf(bufferTS,"%d", $1);
                puntBufferTs = strtok(bufferTS,";\n");
                int numero = atoi(bufferTS);
                insertarTS(puntBufferTs, CONST_INT, "", numero, 0);

                // Inserto en la lista el lugar de ocurrencia
                sprintf(bufferPosicion,"%d", insertarLista(numero, indicePosicion));
                puntBufferPosicion = strtok(bufferPosicion,";\n");
                insertarTS(puntBufferPosicion, CONST_INT, "", insertarLista(numero, indicePosicion), 0);

                // Voy a crear la variable auxiliar @resultado..
                insertarTS(obtenerStringVariableResultado(), CONST_INT, "", 0, 0);
                
                _condPosicion = newNode( IF,
                 newNode("=", newLeaf(puntBufferNombrePivot) , newLeaf( puntBufferTs )) ,
                 newNode("=", newLeaf(obtenerStringVariableResultadoTS()) , newLeaf( puntBufferPosicion ))
                 );

                // Creo un nuevo nodo                        
                _posicion = newNode(PUNTO_Y_COMA, newNode("=", newLeaf(obtenerStringVariableResultadoTS()) , newLeaf( VALOR_NO_DETERMINADO )), _condPosicion);

                printf("\n Regla 8: LISTA -> cte \n");
                }
  | LISTA coma cte {
                        // Aumento la posicion
                        indicePosicion++;

                        sprintf(bufferTS,"%d", $3);
                        puntBufferTs = strtok(bufferTS,";\n");

                        // Formateo el CTE_INT y lo inserto en la tabla de simbolos
                        int numero = atoi(bufferTS);
                        insertarTS(puntBufferTs, CONST_INT, "", numero, 0);
                                               
                        // Agrego el elemento a la TS (para luego poder utilizarlo)
                        sprintf(bufferPosicion,"%d", insertarLista(numero, indicePosicion));
                        puntBufferPosicion = strtok(bufferPosicion,";\n");
                        insertarTS(puntBufferPosicion, CONST_INT, "", insertarLista(numero, indicePosicion), 0);
                        
                        _condPosicion = newNode( IF, newNode("=", newLeaf(puntBufferNombrePivot) , newLeaf( puntBufferTs ) ) , newNode("=", newLeaf(obtenerStringVariableResultadoTS()) , newLeaf( puntBufferPosicion ) ));
                        _posicion = newNode(PUNTO_Y_COMA, _posicion , _condPosicion );


                        printf("\n Regla 9: LISTA -> LISTA coma cte \n");
                        }
  ;

WRITE: write cte_s {
                            sprintf(bufferTS,"%s", $2);
                            puntBufferTs = strtok(bufferTS,";\n");
                            insertarTS(puntBufferTs, CONST_STR, puntBufferTs, 0, 0);
                            _write = newNode(WRITE_NODE, NULL, newLeaf(puntBufferTs));
                            printf("\n Regla 10: WRITE -> write cte_s \n");
                            funcionPosicion = 0;
                            funcionRead = 0;
                          }
  | write id {
                sprintf(bufferTS,"%s", $2);
                puntBufferTs = strtok(bufferTS,";\n");
                _write = newNode(WRITE_NODE, NULL, newLeaf(puntBufferTs));
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