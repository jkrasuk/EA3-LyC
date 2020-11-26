include macros.asm
include macros2.asm
include number.asm

.MODEL LARGE
.386
.STACK 200h

.DATA

@resultado     dd             ?              
_elemento_no_encontrado_1                                   db             "Elemento no encontrado", '$', 22 dup (?)
_Ingrese_un_valor_pivot_mayor_o_igual_a_1____2              db             "Ingrese un valor pivot mayor o igual a 1: ", '$', 42 dup (?)
pivot          dd             ?              
_1             dd             1.0            
_0             dd             0.0            
_9999          dd             9999.0         
_2             dd             2.0            
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

displayString _Ingrese_un_valor_pivot_mayor_o_igual_a_1____2
NEWLINE
GetFloat pivot
NEWLINE

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
jne branch0
fld _0
fld _1
FADD
fstp @resultado
branch0:

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
jne branch1
fld _1
fld _1
FADD
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
fld _1
FADD
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
fld _1
FADD
fstp @resultado
branch3:
fld @resultado
fld _0
FCOM
fstsw AX
sahf
je branch9999
fld @resultado
fstp resul
displayString _Elemento_encontrado_en_posicion____3
NEWLINE
DisplayFloat resul,1
NEWLINE
JMP FOOTER
branch9999:
displayString _elemento_no_encontrado_1
NEWLINE
FOOTER:
mov AX,4C00h                  ; Indica que debe finalizar la ejecución
int 21h

END inicio