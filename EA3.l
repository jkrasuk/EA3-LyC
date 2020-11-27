%{
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <float.h>
#include <string.h>
#include "y.tab.h"

void validarLimitesConstanteString();
void validarLimitesConstanteInt();
void validarID();
%}
%option noyywrap noinput nounput yylineno

DIGITO									[0-9]
LETRA									[a-zA-ZáéíóúÁÉÍÓÚ]
DELIM									[ \t\n\r]
CARACTER								[áéíóúÁÉÍÓÚ|a-z|A-Z|0-9|=|>|<|!|:|+|-|*|/|?|¿|!|¡|@|%|#|&|°|´|^|`|~|/|\\|(|)|\-|_|.|,|;|¬||]
VALID_STRING							({CARACTER}+|{DELIM})*
CTE_STRING								\"{VALID_STRING}\"
CTE_INT									{DIGITO}+
ID										{LETRA}({LETRA}|{DIGITO}|_)*

WRITE									[Ww][Rr][Ii][Tt][Ee]
READ									[Rr][Ee][Aa][Dd]
POSICION								[Pp][Oo][Ss][Ii][Cc][Ii][Oo][Nn]

%%

"="										{ return asigna; }
"("										{ return para; }
")"										{ return parc; }
"["										{ return ca; }
"]"										{ return cc; }
";"										{ return pyc; }
","										{ return coma; }
{WRITE}									{ return write; }
{READ}									{ return read; }
{POSICION}								{ return posicion; }
{CTE_STRING}							{ validarLimitesConstanteString(); strcpy(yylval.strVal, yytext);  return cte_s; }
{CTE_INT}								{ validarLimitesConstanteInt(); yylval.intVal = atoi(yytext);  return cte; }
{ID}									{ strcpy(yylval.strVal, yytext); validarID();  return id; }
{DELIM}
<<EOF>> {yyterminate();}
%%

void validarLimitesConstanteString() 
{
	if (yyleng > 50) 
	{
		printf("Longitud maxima excedida en linea %d\n", yylineno);
		exit(1);
	}
}

void validarLimitesConstanteInt() 
{
	int entero;
    sscanf(yytext,"%d",&entero);

	if(!(entero >= 1 && entero <= 32767)){
		printf("Valor maximo excedido en linea %d\n", yylineno);
		exit(1);
	}
}

void validarID()
{
	if (yyleng > 10) 
	{
		printf("Longitud maxima excedida en linea %d\n", yylineno);
		fprintf(stderr, "Fin de ejecucion.\n");
		system ("Pause");
		exit (1);
	}
}
