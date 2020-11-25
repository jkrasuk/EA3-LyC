%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h> 
#define YYDEBUG 0

extern int yylex();
extern int yyparse();
void yyerror(const char *s);
extern FILE* yyin;
extern int yylineno;
extern int yyleng;
extern char *yytext;
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
    char strVal[30];
    char* auxLogicOperator;
}
%%

s: 
  {printf("Inicia COMPILADOR\n");}
  prog {
        printf("\n Regla 0 - s: PROG \n");
        printf("\n COMPILACION EXITOSA \n");
  }
  ;

prog: prog sent {printf("\n Regla 2 - prog: prog sent \n");}
  | sent {printf("\n Regla 1 - prog: sent \n");}
  ;

sent: read {printf("\n Regla 3 - prog: read \n");}
  | write {printf("\n Regla 3 - prog: write \n");}
  | asig {printf("\n Regla 3 - prog: asig \n");}
  ;

read: READ ID {printf("\n Regla 4 - read: read ID \n");}
  ;

asig: ID ASIG posicion {printf("\n Regla 5 - asig: ID ASIG posicion \n");}
  ;

posicion: POSICION PARA ID PYC CA lista CC PARC {printf("\n Regla 6 - posicion: POSICION PARA ID PYC CA lista CC PARC \n");}
  | POSICION PARA ID PYC CA CC PARC {printf("\n Regla 6 - posicion: POSICION PARA ID PYC CA CC PARC \n");}
  ;

lista: CTE_INT {printf("\n Regla 8 - lista: CTE_INT \n");}
  | lista COMA CTE_INT {printf("\n Regla 9 - lista: lista COMA CTE_INT \n");}
  ;

write: WRITE CTE_STRING {printf("\n Regla 10 - write: WRITE CTE_STRING \n");}
  | WRITE ID {printf("\n Regla 11 - write: WRITE ID \n");}
  ;

%%

int main(int argc, char *argv[]) {

    if ((yyin = fopen(argv[1], "rt")) == NULL) {
        printf("\nNo se puede abrir el archivo: %s\n", argv[1]);
    } else {
        yyparse();
    }

    fclose(yyin);

    return 0;
}

void yyerror(const char *str) {
    fprintf(stderr, "Error: %s en la linea %d\n", str, yylineno);
    system("Pause");
    exit(1);
}
