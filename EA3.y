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

// Seccion TS
typedef struct
{
        char *nombre;
        char *nombreASM;
        char *tipo;
        union Valor{
                int valor_int;
                double valor_double;
                char *valor_str;
        }valor;
        int longitud;
}t_data;

typedef struct s_simbolo
{
        t_data data;
        struct s_simbolo *next;
}t_simbolo;

typedef struct
{
        t_simbolo *primero;
}t_tabla;
int indicePosicion;
char bufferTS[800];
char bufferNombrePivot[800];
char bufferPosicion[800];
char* puntBufferTs;
char* puntBufferNombrePivot;
char* puntBufferPosicion;
void crearTablaTS();
int insertarTS(const char*, const char*, const char*, int, double);
t_data* crearDatos(const char*, const char*, const char*, int, double);
void guardarTS();
t_simbolo * getLexema(const char *);
char* reemplazarString(char*, const char*);
t_tabla tablaTS;
// FIN Seccion TS

// Seccion Arbol
typedef struct treeNode {
    char* value;
    int nodeId;
    struct treeNode* left;
    struct treeNode* right;
} ast;

int  i=0, contadorString = 0, contadorId = 0;
ast * _write, * _read, *_asig, * _posicion, *_fact, *_condPosicion;
ast* _pProg ,* _pSent;
ast* _aux;
FILE*  intermedia;
ast* newNode();
ast* newLeaf();
void print2DUtil(ast *root, int space);
void print2D(ast *root);
void generarGraphviz(ast* arbol);
void recorrerArbolGraphviz(ast* arbol, FILE* pf);
// FIN Seccion Arbol

// Seccion Assembler
int vectorEtiquetas[50], topeVectorEtiquetas = -1;
void generarAssembler();
void generaHeader(FILE *);
void crearSeccionData(FILE *);
void crearSeccionCode(FILE *);
void generaFooter(FILE *);
void recorrerArbol( ast * , FILE *);
// FIN Seccion Assembler

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
  {printf("Inicia COMPILADOR\n");}
  prog {
        printf("\n Regla 0 - s: PROG \n");
        generarAssembler(); 
        guardarTS();
        print2D(_pProg); 
        generarGraphviz(_pProg);
        printf("\n COMPILACION EXITOSA \n");
  }
  ;

prog: prog sent {_pProg = newNode(";", _pProg, _pSent); printf("\n Regla 2 - prog: prog sent \n");}
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
                          }
  ;

posicion: POSICION PARA ID PYC CA {sprintf(bufferNombrePivot,"%s", $3); puntBufferNombrePivot = strtok(bufferNombrePivot, " ;\n");} lista CC PARC {printf("\n Regla 6 - posicion: POSICION PARA ID PYC CA lista CC PARC \n");}
  | POSICION PARA ID PYC CA {sprintf(bufferNombrePivot,"%s", $3); puntBufferNombrePivot = strtok(bufferNombrePivot, " ;\n");} CC PARC {printf("\n Regla 6 - posicion: POSICION PARA ID PYC CA CC PARC \n");}
  ;

lista: CTE_INT {
                indicePosicion = 0;
                sprintf(bufferTS,"%d", $1);
                puntBufferTs = strtok(bufferTS,";\n");
                sprintf(bufferPosicion,"%d", indicePosicion);
                puntBufferPosicion = strtok(bufferPosicion,";\n");
                char bufferNoEncontrando[10];
                char* puntBufferNoEncontrado;
                sprintf(bufferPosicion,"%d", indicePosicion);
                puntBufferPosicion = strtok(bufferPosicion,";\n");
                sprintf(bufferNoEncontrando,"%d", -1);
                puntBufferNoEncontrado = strtok(bufferNoEncontrando,";\n");
                _condPosicion = newNode( "IF",
                 newNode("=", newLeaf(puntBufferNombrePivot) , newLeaf( puntBufferTs ) ) ,
                  newNode("CUERPO", 
                            newNode("=", newLeaf("@posicion") , newLeaf( puntBufferPosicion )),
                            newNode("=", newLeaf("@posicion") , newLeaf( puntBufferNoEncontrado ) )));
                _posicion = newNode(";", _posicion , _condPosicion );
                printf("\n Regla 8 - lista: CTE_INT \n");
                }
  | lista COMA CTE_INT {
                        indicePosicion++;
                        sprintf(bufferTS,"%d", $3);
                        puntBufferTs = strtok(bufferTS,";\n");
                        sprintf(bufferPosicion,"%d", indicePosicion);
                        puntBufferPosicion = strtok(bufferPosicion,";\n");
                        _condPosicion = newNode( "IF", newNode("=", newLeaf(puntBufferNombrePivot) , newLeaf( puntBufferTs ) ) , newNode("=", newLeaf("@posicion") , newLeaf( puntBufferPosicion ) ));
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
                          }
  | WRITE ID {
              sprintf(bufferTS,"%s", $2);
              puntBufferTs = strtok(bufferTS,";\n");
               _write = newNode("WRITE", NULL, newLeaf(puntBufferTs));
              printf("\n Regla 11 - write: WRITE ID \n");
              }
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
// Seccion de codigo para TS
int insertarTS(const char *nombre, const char *tipo, const char* valString, int valInt, double valDouble)
{
    t_simbolo *tabla = tablaTS.primero;
    char nombreCTE[300] = "_";
    strcat(nombreCTE, nombre);
    
    while(tabla)
    {
        if(strcmp(tabla->data.nombre, nombre) == 0 || strcmp(tabla->data.nombre, nombreCTE) == 0)
        {
            return 1;
        }
        else if(strcmp(tabla->data.tipo, "CONST_STR") == 0)
        {
            
            if(strcmp(tabla->data.valor.valor_str, valString) == 0)
            {
                return 1;
            }
        }
        
        if(tabla->next == NULL)
        {
            break;
        }
        tabla = tabla->next;
    }
    
    t_data *data = (t_data*) malloc(sizeof(t_data));
    data = crearDatos(nombre, tipo, valString, valInt, valDouble);

    if(data == NULL)
    {
        return 1;
    }

    t_simbolo* nuevo = (t_simbolo*) malloc(sizeof(t_simbolo));

    if(nuevo == NULL)
    {
        return 2;
    }

    nuevo->data = *data;
    nuevo->next = NULL;

    if(tablaTS.primero == NULL)
    {
        tablaTS.primero = nuevo;
    }
    else
    {
        tabla->next = nuevo;
    }

    return 0;
}
t_data* crearDatos(const char *nombre, const char *tipo, const char* valString, int valInt, double valDouble)
{
    char full[200] = "_";
    char aux[200];

    t_data *data = (t_data*)calloc(1, sizeof(t_data));
    if(data == NULL)
    {
        return NULL;
    }

    data->tipo = (char*)malloc(sizeof(char) * (strlen(tipo) + 1));
    strcpy(data->tipo, tipo);
    if( strcmp(tipo, "STRING")==0 || strcmp(tipo, "INT")==0 || strcmp(tipo, "FLOAT")==0 )
    {
        data->nombre = (char*)malloc(sizeof(char) * (strlen(nombre) + 1));
        strcpy(data->nombre, nombre);
        data->nombreASM = (char*)malloc(sizeof(char) * (strlen(nombre) + 1));
        strcpy(data->nombreASM, nombre);

        //printf("\n\t\t el nombreASM de %s es %s", data->nombreASM, data->nombre);
        return data;
    }
    else
    {
        if(strcmp(tipo, "CONST_STR") == 0)
        {
            contadorString++;
            
            data->valor.valor_str = (char*)malloc(sizeof(char) * (strlen(valString) + 1));
            strcpy(data->valor.valor_str, valString);

            char auxString[200];
            strcpy(full, ""); 
            reemplazarString(auxString, nombre);
            strcat(full, auxString); // "S_<nombre>"  
            char numero[10];
            sprintf(numero, "_%d", contadorString);
            strcat(full, numero); // "S_<nombre>_#"

            data->nombre = (char*)malloc(sizeof(char) * (strlen(full) + 1));
            data->nombreASM = (char*)malloc(sizeof(char) * (strlen(full) + 1));
            strcpy(data->nombre, full);
            strcpy(data->nombreASM, data->nombre);
        }
        if(strcmp(tipo, "CONST_INT") == 0)
        {
            sprintf(aux, "%d", valInt);
            strcat(full, aux);
            data->nombre = (char*)malloc(sizeof(char) * (strlen(full) + 1));
            strcpy(data->nombre, full);
            data->valor.valor_int = valInt;
            data->nombreASM = (char*)malloc(sizeof(char) * (strlen(full) + 1));
            strcpy(data->nombreASM, full);
        }
        return data;
    }
    return NULL;
}
char* reemplazarString(char* dest, const char* cad)
{
    int i, longitud;
    longitud = strlen(cad);

    for(i=0; i<longitud; i++)
    {
        if((cad[i] >= 'a' && cad[i] <= 'z') || (cad[i] >='A' && cad[i] <= 'Z') || (cad[i] >= '0' && cad[i] <= '9'))
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

void guardarTS()
{
    FILE* arch;
    if((arch = fopen("ts.txt", "wt")) == NULL)
    {
            printf("\nNo se pudo crear la tabla de simbolos.\n\n");
            return;
    }
    else if(tablaTS.primero == NULL)
            return;
    
    fprintf(arch, "%-60s%-20s%-50s%-15s\n", "NOMBRE", "TIPO DATO", "VALOR", "LONGITUD");

    t_simbolo *aux;
    t_simbolo *tabla = tablaTS.primero;
    char linea[300];

    while(tabla)
    {
        aux = tabla;
        tabla = tabla->next;
        
        if(strcmp(aux->data.tipo, "INT") == 0 || strcmp(aux->data.tipo, "FLOAT") ==0 || strcmp(aux->data.tipo, "STRING") ==0)
        {
            sprintf(linea, "%-60s%-20s%-50s%-15s\n", aux->data.nombre, aux->data.tipo, "-", "-");
        }
        else if(strcmp(aux->data.tipo, "CONST_INT") == 0)
        {
            sprintf(linea, "%-60s%-20s%-50d%-15d\n", aux->data.nombre, aux->data.tipo, aux->data.valor.valor_int, strlen(aux->data.nombre) -1);
        }
        else if(strcmp(aux->data.tipo, "CONST_STR") == 0)
        {
            sprintf(linea, "%-60s%-20s%-50s%-15d\n", aux->data.nombre, aux->data.tipo, aux->data.valor.valor_str, strlen(aux->data.valor.valor_str) -2);
        }
        fprintf(arch, "%s", linea);
        free(aux);
    }
    fclose(arch); 
}
// FIN Seccion de codigo para TS

// Seccion de codigo para Arbol
ast* newNode(char* operation, ast* leftNode, ast* rightNode) {
    ast* node = (ast*) malloc(sizeof(ast));
    node->value = operation;
    node->nodeId = contadorId;
    node->left = leftNode;
    node->right = rightNode;
    contadorId++;
    return node;
}

ast* newLeaf(char* value) {
    ast* node = (ast*) malloc(sizeof(ast));
    node->nodeId = contadorId;
    node->value = strdup(value);
    node->left = NULL;
    node->right = NULL;
    contadorId++;
    return node;
}

void print2DUtil(ast *root, int space) 
{ 
    
    // Base case 
    if (root == NULL) 
        return; 
  
    // Increase distance between levels 
    space += 10; 
  
    // Process right child first 
    print2DUtil(root->right, space); 
  
    // Print current node after space 
    fprintf( intermedia ,"\n");
    int i; 
    for (i = 10; i < space; i++) 
        fprintf( intermedia ," "); 
    fprintf( intermedia ,"%s\n", root->value); 
  
    // Process left child 
    print2DUtil(root->left, space); 
} 
  
// Wrapper over print2DUtil() 
void print2D(ast *root) 
{ 
    intermedia = fopen("intermedia.txt", "w");
    if ( intermedia == NULL) {
        printf("No se pudo crear el archivo intermedia.txt\n");
        exit(1);
    }
   // Pass initial space count as 0 
   print2DUtil(root, 0); 
   fclose( intermedia );
} 

void generarGraphviz(ast * arbol){
    FILE *pf = fopen("intermedia.gv", "w+"); 
        fprintf(pf,"digraph G {\n");    
        fprintf(pf,"\tnode [fontname = \"Arial\"];\n");
        recorrerArbolGraphviz( arbol , pf);
        fprintf(pf,"}");
        fclose(pf);
}

void recorrerArbolGraphviz(ast * arbol, FILE* pf)
{
    if(arbol==NULL)
        return;
    
    //printf( "%s\t%d\n", arbol->value , arbol->nodeId );

    if(arbol->left)
    {
          fprintf(pf," N%d -> N%d; \n",arbol->nodeId , arbol->left->nodeId);
          recorrerArbolGraphviz(arbol->left, pf);
    }

    if(arbol->right)
    {
          fprintf(pf," N%d -> N%d; \n",arbol->nodeId ,arbol->right->nodeId);
          recorrerArbolGraphviz(arbol->right, pf);
    }


    if(strchr(arbol->value,'\"'))
        fprintf(pf," N%d [label = %s]\n",arbol->nodeId ,arbol->value );
    else fprintf(pf," N%d [label = \"%s\"]\n",arbol->nodeId ,arbol->value );
}
// FIN Seccion de codigo para Arbol

//Seccion de codigo para Assembler
void generarAssembler()
{
    FILE* file = fopen("Final.asm", "w");
    if (file == NULL) {
        printf("No se pudo crear el archivo final.asm \n");
        exit(1);
    }
    generaHeader(file);
    // crearSeccionData(file);
    // crearSeccionCode(file);
    // recorrerArbol( _pProg ,file );
    // crearFooter(file);
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
void generaFooter(FILE *f)
{
    fprintf(f, "\n\n");
    fprintf(f, "MOV EAX, 4C00h\n");
    fprintf(f, "INT 21h\n\n");
    fprintf(f, "\n");
}
// FIN Seccion de codigo para Assembler
