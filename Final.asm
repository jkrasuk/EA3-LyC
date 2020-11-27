include macros.asm
include macros2.asm
include number.asm

.MODEL LARGE
.386
.STACK 200h

.DATA

_elemento_no_encontrado_1                         db             "Elemento no encontrado", '$', 22 dup (?)
_valor_menor_a_1_2                                db             "El valor debe ser >= 1", '$', 22 dup (?)
_lista_vacia_3                                    db             "Lista vacia", '$', 11 dup (?)
_1                                                dd             1.0            
_valorNoDeterminado                               dd             -1.0           
_Ingrese_un_valor_pivot_mayor_o_igual_a_1____4    db             "Ingrese un valor pivot mayor o igual a 1: ", '$', 42 dup (?)
pivot                                             dd             ?              
_10                                               dd             10.0           
_0                                                dd             0.0            
__@resultado0                                     dd             0.0            
_20                                               dd             20.0           
_30                                               dd             30.0           
_2                                                dd             2.0            
_40                                               dd             40.0           
_3                                                dd             3.0            
_5                                                dd             5.0            
_4                                                dd             4.0            
resul                                             dd             ?              
_Elemento_encontrado_en_posicion____5             db             "Elemento encontrado en posicion: ", '$', 33 dup (?)
@ifI                                              dd             ?              ; Variable para condición izquierda
@ifD                                              dd             ?              ; Variable para condición derecha

.CODE

inicio:

mov AX,@DATA                  ; Inicializa el segmento de datos
mov DS,AX                     
mov ES,AX                     

displayString _Ingrese_un_valor_pivot_mayor_o_igual_a_1____4
NEWLINE
GetFloat pivot
NEWLINE

;Validacion de pivot mayor o igual a 1
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
JAE branch0
displayString _valor_menor_a_1_2
NEWLINE
JMP FOOTER
NEWLINE
branch0:

;Comienza el codigo de posicion
fld _valorNoDeterminado
fstp __@resultado0

;Codigo if
fld pivot
fstp @ifI
fld _10
fstp @ifD
fld @ifI
fld @ifD
fxch
fcom 
fstsw AX
sahf
jne branch1
fld _0
fstp __@resultado0
branch1:

;Codigo if
fld pivot
fstp @ifI
fld _20
fstp @ifD
fld @ifI
fld @ifD
fxch
fcom 
fstsw AX
sahf
jne branch2
fld _1
fstp __@resultado0
branch2:

;Codigo if
fld pivot
fstp @ifI
fld _30
fstp @ifD
fld @ifI
fld @ifD
fxch
fcom 
fstsw AX
sahf
jne branch3
fld _2
fstp __@resultado0
branch3:

;Codigo if
fld pivot
fstp @ifI
fld _40
fstp @ifD
fld @ifI
fld @ifD
fxch
fcom 
fstsw AX
sahf
jne branch4
fld _3
fstp __@resultado0
branch4:

;Codigo if
fld pivot
fstp @ifI
fld _5
fstp @ifD
fld @ifI
fld @ifD
fxch
fcom 
fstsw AX
sahf
jne branch5
fld _4
fstp __@resultado0
branch5:

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
jne branch6
fld _5
fstp __@resultado0
branch6:
fld __@resultado0
fstp resul

;Validacion de elemento no encontrado
fld resul
fstp @ifI
fld _valorNoDeterminado
fstp @ifD
fld @ifI
fld @ifD
fxch
fcom 
fstsw AX
sahf
jne branch7
displayString _elemento_no_encontrado_1
NEWLINE
JMP FOOTER
NEWLINE
branch7:
displayString _Elemento_encontrado_en_posicion____5
NEWLINE
fld resul
fld _1
FADD
fstp resul
DisplayFloat resul,1
NEWLINE
FOOTER:
mov AX,4C00h                  
int 21h

END inicio