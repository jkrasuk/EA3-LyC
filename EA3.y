%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h> 
#include <stdbool.h>
#include "./utils/tools.h"
#define YYDEBUG 0

extern int yylex();
extern int yyparse();
void yyerror(const char *s);
extern FILE* yyin;
extern int yylineno;
extern int yyleng;
extern char *yytext;

char bufferTS[800], bufferNombrePivot[800], bufferPosicion[800];
char* puntBufferTs, *puntBufferNombrePivot, *puntBufferPosicion;
int indicePosicion=0, i=0, funcionPosicion = 0, funcionRead = 0,tengoLista=0;
ast * _write, * _read, *_asig, * _posicion, *_condPosicion,  * _nodoComprobacionValidacion, * _nodoMensajeValidacion, * _pProg ,* _pSent;
%}
%token ID CTE_INT CTE_STRING
%token ASIG
%token PARA PARC CA CC PYC COMA
%token WRITE READ
%token POSICION

%type <intVal> CTE_INT
%type <strVal> CTE_STRING
%type <strVal> ID

%start s

%union
{
    int intVal;
    float floatVal;
    char strVal[50];
    char* auxLogicOperator;
}
%%

s: 
  {
    printf("Inicia COMPILADOR\n");
}
  prog {
        printf("\n Regla 0 - s: PROG \n");
        generarAssembler(_pProg, obtenerTablaTS()); 
        guardarTS();
        print2D(_pProg); 
        generarGraphviz(_pProg);
        printf("\n COMPILACION EXITOSA \n");
  }
  ;

prog: prog sent {
    _pProg = newNode(";", _pProg, _pSent); 
    
    if(funcionPosicion)
    {
        _nodoComprobacionValidacion = newNode("=", newLeaf(puntBufferTs), newLeaf("_valorNoDeterminado"));
        if(tengoLista)
        {
            _nodoMensajeValidacion = newNode("WRITE", NULL, newLeaf("\"Elemento no encontrado\""));
        }
        else
        {
            _nodoMensajeValidacion = newNode("WRITE", NULL, newLeaf("\"Lista vacia\""));
        }

        _pProg = newNode(";", _pProg, newNode("IF", _nodoComprobacionValidacion, _nodoMensajeValidacion));
    }
    else if(funcionRead)
    {
        _nodoComprobacionValidacion = newNode("<", newLeaf(puntBufferTs), newLeaf("_1"));
        _nodoMensajeValidacion = newNode("WRITE", NULL, newLeaf("\"El valor debe ser >= 1\""));
        _pProg = newNode(";", _pProg, newNode("IF", _nodoComprobacionValidacion, _nodoMensajeValidacion));
    }

    printf("\n Regla 2 - prog: prog sent \n");
    }
  | sent {_pProg = _pSent; printf("\n Regla 1 - prog: sent \n");}
  ;

sent: read {_pSent = _read; printf("\n Regla 3 - prog: read \n");}
  | write {_pSent = _write; printf("\n Regla 3 - prog: write \n");}
  | asig {_pSent = _asig; printf("\n Regla 3 - prog: asig \n");}
  ;

read: READ ID {
                sprintf(bufferTS,"%s", $2);
                puntBufferTs = strtok(bufferTS, " ;\n"); 
                if(insertarTS(puntBufferTs, "INT", "", 0, 0) != 0)
                {
                  fprintf(stdout, "%s%s%s", "Error: la variable '", puntBufferTs, "' ya fue declarada");
                }
                _read = newNode("READ", NULL ,newLeaf(puntBufferTs));
                printf("\n Regla 4 - read: read ID \n");
                funcionPosicion = 0;
                funcionRead = 1;
                }
  ;

asig: ID ASIG posicion {
                          sprintf(bufferTS,"%s", $1);
                          puntBufferTs = strtok(bufferTS, " ;\n"); 
                          if(insertarTS(puntBufferTs, "INT", "", 0, 0) != 0)
                          {
                            fprintf(stdout, "%s%s%s", "Error: la variable '", puntBufferTs, "' ya fue declarada");
                          }
                          _asig = newNode("=", newLeaf(puntBufferTs) , _posicion );                                 
                          printf("\n Regla 5 - asig: ID ASIG posicion \n");
                          funcionPosicion = 1;
                          funcionRead = 0;
                          }
  ;

posicion: 
  POSICION PARA ID PYC CA {sprintf(bufferNombrePivot,"%s", $3); puntBufferNombrePivot = strtok(bufferNombrePivot, " ;\n");} lista CC PARC {tengoLista = 1; printf("\n Regla 6 - posicion: POSICION PARA ID PYC CA lista CC PARC \n");}
  | POSICION PARA ID PYC CA {sprintf(bufferNombrePivot,"%s", $3); puntBufferNombrePivot = strtok(bufferNombrePivot, " ;\n");} CC PARC {
    tengoLista = 0;
    // Agrego una hoja con el -1
    _posicion = newLeaf("_valorNoDeterminado");

    printf("\n Regla 6 - posicion: POSICION PARA ID PYC CA CC PARC \n");}
  ;

lista: CTE_INT {
                // Inicializo la posicion en 0
                indicePosicion = 0;
                sprintf(bufferPosicion,"%d", indicePosicion);
                puntBufferPosicion = strtok(bufferPosicion,";\n");

                // Formateo el CTE_INT y lo inserto en la tabla de simbolos
                sprintf(bufferTS,"%d", $1);
                puntBufferTs = strtok(bufferTS,";\n");
                int numero = atoi(bufferTS);
                insertarTS(puntBufferTs, "CONST_INT", "", numero, 0);

                // Inserto en la lista el lugar de ocurrencia
                sprintf(bufferPosicion,"%d", insertarLista(numero, indicePosicion));
                puntBufferPosicion = strtok(bufferPosicion,";\n");

                // Agrego el elemento a la TS (para luego poder utilizarlo)
                insertarTS(puntBufferTs, "CONST_INT", "", insertarLista(numero, indicePosicion), 0);

                _condPosicion = newNode( "IF",
                 newNode("=", newLeaf(puntBufferNombrePivot) , newLeaf( puntBufferTs )) ,
                 newNode("=", newLeaf("@resultado") , newLeaf( puntBufferPosicion ))
                 );

                // Creo un nuevo nodo                        
                _posicion = newNode(";", newNode("=", newLeaf("@resultado") , newLeaf( "_valorNoDeterminado" )), _condPosicion);

                printf("\n Regla 8 - lista: CTE_INT \n");
                }
  | lista COMA CTE_INT {
                        // Aumento la posicion
                        indicePosicion++;

                        sprintf(bufferTS,"%d", $3);
                        puntBufferTs = strtok(bufferTS,";\n");

                        // Formateo el CTE_INT y lo inserto en la tabla de simbolos
                        int numero = atoi(bufferTS);
                        insertarTS(puntBufferTs, "CONST_INT", "", numero, 0);

                                               
                        // Agrego el elemento a la TS (para luego poder utilizarlo)
                        sprintf(bufferPosicion,"%d", insertarLista(numero, indicePosicion));
                        puntBufferPosicion = strtok(bufferPosicion,";\n");
                        insertarTS(puntBufferPosicion, "CONST_INT", "", insertarLista(numero, indicePosicion), 0);
                        
                        _condPosicion = newNode( "IF", newNode("=", newLeaf(puntBufferNombrePivot) , newLeaf( puntBufferTs ) ) , newNode("=", newLeaf("@resultado") , newLeaf( puntBufferPosicion ) ));
                        _posicion = newNode(";", _posicion , _condPosicion );


                        printf("\n Regla 9 - lista: lista COMA CTE_INT \n");
                        }
  ;

write: WRITE CTE_STRING {
                            sprintf(bufferTS,"%s", $2);
                            puntBufferTs = strtok(bufferTS,";\n");
                            insertarTS(puntBufferTs, "CONST_STR", puntBufferTs, 0, 0);
                            _write = newNode("WRITE", NULL, newLeaf(puntBufferTs));
                            printf("\n Regla 10 - write: WRITE CTE_STRING \n");
                            funcionPosicion = 0;
                            funcionRead = 0;
                          }
  | WRITE ID {
                sprintf(bufferTS,"%s", $2);
                puntBufferTs = strtok(bufferTS,";\n");
                _write = newNode("WRITE", NULL, newLeaf(puntBufferTs));
                printf("\n Regla 11 - write: WRITE ID \n");
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