include macros.asm
include macros2.asm
include number.asm

.MODEL LARGE
.386
.STACK 200h

.DATA

@resultado     dd             ?              
_elemento_no_encontrado_1                                   db             "Elemento no encontrado", '$', 22 dup (?)
_lista_vacia_2                                              db             "Lista vacia", '$', 11 dup (?)
_0             dd             0.0            
_1             dd             1.0            
_9999          dd             9999.0         
_Ingrese_un_valor_pivot_mayor_o_igual_a_1____3              db             "Ingrese un valor pivot mayor o igual a 1: ", '$', 42 dup (?)
pivot          dd             ?              
_3             dd             3.0            
_2             dd             2.0            
_4             dd             4.0            
resul          dd             ?              
_Elemento_encontrado_en_posicion____4                       db             "Elemento encontrado en posicion: ", '$', 33 dup (?)
@ifI           dd             ?              ; Variable para condición izquierda
@ifD           dd             ?              ; Variable para condición derecha

.CODE

inicio:

mov AX,@DATA                  ; Inicializa el segmento de datos
mov DS,AX                     
mov ES,AX                     

displayString _Ingrese_un_valor_pivot_mayor_o_igual_a_1____3
NEWLINE
GetFloat pivot
NEWLINE

;Comienza el codigo de posicion
fld _9999
fstp @resultado

;Codigo if
fld pivot
fstp @ifI
fld _3
fstp @ifD
fld @ifI
fld @ifD
fxch
fcom 
fstsw AX
sahf
jne branch0
fld _0
fstp @resultado
branch0:

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
jne branch1
fld _1
fstp @resultado
branch1:

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
jne branch2
fld _2
fstp @resultado
branch2:

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
jne branch3
fld _3
fstp @resultado
branch3:
fld @resultado
fstp resul

;Validacion de elemento no encontrado
fld resul
fstp @ifI
fld _9999
fstp @ifD
fld @ifI
fld @ifD
fxch
fcom 
fstsw AX
sahf
jne branch4
displayString _elemento_no_encontrado_1
NEWLINE
JMP FOOTER
NEWLINE
branch4:
displayString _Elemento_encontrado_en_posicion____4
NEWLINE
fld resul
fld _1
FADD
fstp resul
DisplayFloat resul,1
NEWLINE
JMP FOOTER
branch10000:
displayString _lista_vacia_2
NEWLINE
FOOTER:
mov AX,4C00h                  ; Indica que debe finalizar la ejecución
int 21h

END inicio