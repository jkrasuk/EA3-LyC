include macros.asm
include macros2.asm
include number.asm

.MODEL LARGE
.386
.STACK 200h

.DATA

@resultado     dd             ?              
_Ingrese_un_valor_pivot_mayor_o_igual_a_1____1              db             "Ingrese un valor pivot mayor o igual a 1: ", '$', 42 dup (?)
pivot          dd             ?              
Elemento_no_encontrado_2                                    db             Elemento no encontrado, '$', 20 dup (?)
_0             dd             0.0            
_2             dd             2.0            
_2             dd             2.0            
_1             dd             1.0            
_3             dd             3.0            
_4             dd             4.0            
resul          dd             ?              
_Elemento_encontrado_en_posicion____3                       db             "Elemento encontrado en posicion: ", '$', 33 dup (?)
@ifI           dd             ?              ; Variable para condición izquierda
@ifD           dd             ?              ; Variable para condición derecha

.CODE

inicio:

mov AX,@DATA                  ; Inicializa el segmento de datos
mov DS,AX                     
mov ES,AX                     

displayString _Ingrese_un_valor_pivot_mayor_o_igual_a_1____1
NEWLINE
GetFloat pivot
NEWLINE

;Comienza el codigo de maximo
fld Elemento_no_encontrado_2
fstp @resultado

;Comienza el codigo de maximo
fld _2
fstp pivot

;Codigo if
fld pivot
fstp @ifI
fld _2
fstp @ifD
fld @ifI
fld @ifD
fxch
fcom 
fstsw AX
sahf
jae branch0
fld _0
fstp @resultado
branch0:

;Comienza el codigo de maximo
fld _2
fstp pivot

;Codigo if
fld pivot
fstp @ifI
fld _2
fstp @ifD
fld @ifI
fld @ifD
fxch
fcom 
fstsw AX
sahf
jae branch1
fld _0
fstp @resultado
branch1:

;Comienza el codigo de maximo
fld _1
fstp pivot

;Codigo if
fld pivot
fstp @ifI
fld _1
fstp @ifD
fld @ifI
fld @ifD
fxch
fcom 
fstsw AX
sahf
jae branch2
fld _2
fstp @resultado
branch2:

;Comienza el codigo de maximo
fld _4
fstp pivot

;Codigo if
fld pivot
fstp @ifI
fld _4
fstp @ifD
fld @ifI
fld @ifD
fxch
fcom 
fstsw AX
sahf
jae branch3
fld _3
fstp @resultado
branch3:
fld @resultado
fstp resul
displayString _Elemento_encontrado_en_posicion____3
NEWLINE
DisplayFloat resul,1
NEWLINE

mov AX,4C00h                  ; Indica que debe finalizar la ejecución
int 21h

END inicio