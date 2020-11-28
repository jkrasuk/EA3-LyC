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
pivot                                             dd             ?              
_Ingrese_un_valor_pivot_mayor_o_igual_a_1____4    db             "Ingrese un valor pivot mayor o igual a 1: ", '$', 42 dup (?)
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

MOV AX,@DATA                  
MOV DS,AX                     
MOV ES,AX                     

GetFloat pivot,1
NEWLINE
FLD pivot
FSTP @ifI
FLD _1
FSTP @ifD
FLD @ifI
FLD @ifD
FXCH
FCOM 
FSTSW AX
SAHF
JAE branch0
displayString _valor_menor_a_1_2
NEWLINE
JMP FOOTER
NEWLINE
branch0:
displayString _Ingrese_un_valor_pivot_mayor_o_igual_a_1____4
NEWLINE
FLD _valorNoDeterminado
FSTP __@resultado0
FLD pivot
FSTP @ifI
FLD _10
FSTP @ifD
FLD @ifI
FLD @ifD
FXCH
FCOM 
FSTSW AX
SAHF
JNE branch1
FLD _0
FSTP __@resultado0
branch1:
FLD pivot
FSTP @ifI
FLD _20
FSTP @ifD
FLD @ifI
FLD @ifD
FXCH
FCOM 
FSTSW AX
SAHF
JNE branch2
FLD _1
FSTP __@resultado0
branch2:
FLD pivot
FSTP @ifI
FLD _30
FSTP @ifD
FLD @ifI
FLD @ifD
FXCH
FCOM 
FSTSW AX
SAHF
JNE branch3
FLD _2
FSTP __@resultado0
branch3:
FLD pivot
FSTP @ifI
FLD _40
FSTP @ifD
FLD @ifI
FLD @ifD
FXCH
FCOM 
FSTSW AX
SAHF
JNE branch4
FLD _3
FSTP __@resultado0
branch4:
FLD pivot
FSTP @ifI
FLD _5
FSTP @ifD
FLD @ifI
FLD @ifD
FXCH
FCOM 
FSTSW AX
SAHF
JNE branch5
FLD _4
FSTP __@resultado0
branch5:
FLD pivot
FSTP @ifI
FLD _4
FSTP @ifD
FLD @ifI
FLD @ifD
FXCH
FCOM 
FSTSW AX
SAHF
JNE branch6
FLD _5
FSTP __@resultado0
branch6:
FLD __@resultado0
FSTP resul
FLD resul
FSTP @ifI
FLD _valorNoDeterminado
FSTP @ifD
FLD @ifI
FLD @ifD
FXCH
FCOM 
FSTSW AX
SAHF
JNE branch7
displayString _elemento_no_encontrado_1
NEWLINE
JMP FOOTER
NEWLINE
branch7:
displayString _Elemento_encontrado_en_posicion____5
NEWLINE
FLD resul
FLD _1
FADD
FSTP resul
DisplayFloat resul,1
NEWLINE
FOOTER:
MOV AX,4C00h
INT 21h

END inicio