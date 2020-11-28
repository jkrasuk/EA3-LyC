#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

typedef struct treeNode
{
    char *value;
    int nodeId;
    struct treeNode *left;
    struct treeNode *right;
} ast;

ast *newNode();
ast *newLeaf();
void generarArbolTXTUtil(ast *root, int space);
void generarArbolTXT(ast *root);
void generarGraphviz(ast *arbol);
void recorrerArbolGraphviz(ast *arbol, FILE *pf);

int contadorId = 0;
FILE *intermedia;

// Funcion para la creacion de un nuevo nodo
ast *newNode(char *operation, ast *leftNode, ast *rightNode)
{
    ast *node = (ast *)malloc(sizeof(ast));
    node->value = operation;
    node->nodeId = contadorId;
    node->left = leftNode;
    node->right = rightNode;
    contadorId++;
    return node;
}

// Funcion para la creacion de una nueva hoja
ast *newLeaf(char *value)
{
    ast *node = (ast *)malloc(sizeof(ast));
    node->nodeId = contadorId;
    node->value = strdup(value);
    node->left = NULL;
    node->right = NULL;
    contadorId++;
    return node;
}

void generarArbolTXTUtil(ast *root, int space)
{
    int i;

    if (root == NULL)
        return;

    space += 10;

    generarArbolTXTUtil(root->right, space);

    fprintf(intermedia, "\n");

    for (i = 10; i < space; i++)
        fprintf(intermedia, " ");

    fprintf(intermedia, "%s\n", root->value);

    generarArbolTXTUtil(root->left, space);
}

void generarArbolTXT(ast *root)
{
    intermedia = fopen(NOMBRE_ARCHIVO_INTERMEDIA_TXT, "w");

    if (intermedia == NULL)
    {
        printf("No se pudo crear el archivo intermedia.txt\n");
        exit(1);
    }

    generarArbolTXTUtil(root, 0);
    fclose(intermedia);
}

void generarGraphviz(ast *arbol)
{
    FILE *pf = fopen("intermedia.gv", "w+");
    fprintf(pf, "digraph G {\n");
    fprintf(pf, "\tnode [fontname = \"Arial\"];\n");
    recorrerArbolGraphviz(arbol, pf);
    fprintf(pf, "}");
    fclose(pf);
}

void recorrerArbolGraphviz(ast *arbol, FILE *pf)
{
    if (arbol == NULL)
    {
        return;
    }

    if (arbol->left)
    {
        fprintf(pf, " N%d -> N%d; \n", arbol->nodeId, arbol->left->nodeId);
        recorrerArbolGraphviz(arbol->left, pf);
    }

    if (arbol->right)
    {
        fprintf(pf, " N%d -> N%d; \n", arbol->nodeId, arbol->right->nodeId);
        recorrerArbolGraphviz(arbol->right, pf);
    }

    if (strchr(arbol->value, '\"'))
    {
        // En caso de que sea una hoja con mensaje de error, debe tener doble redondel
        // De esta forma, se indica que allí termina el programa
        if (strcmp(arbol->value, ELEMENTO_NO_ENCONTRADO) == 0 || strcmp(arbol->value, EL_VALOR_DEBE_SER_MAYOR_O_IGUAL_A_1) == 0 || strcmp(arbol->value, LISTA_VACIA) == 0)
        {
            fprintf(pf, " N%d [peripheries=2; label = %s]\n", arbol->nodeId, arbol->value);
        }
        else
        {
            fprintf(pf, " N%d [label = %s]\n", arbol->nodeId, arbol->value);
        }
    }
    else
    {
        fprintf(pf, " N%d [label = \"%s\"]\n", arbol->nodeId, arbol->value);
    }
}