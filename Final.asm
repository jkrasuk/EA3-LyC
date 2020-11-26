include macros.asm
include macros2.asm
include number.asm

.MODEL LARGE
.386
.STACK 200h

.DATA

@resultado                                        dd             ?              
_elemento_no_encontrado_1                         db             "Elemento no encontrado", '$', 22 dup (?)
_valor_menor_a_1_2                                db             "El valor debe ser >= 1", '$', 22 dup (?)
_lista_vacia_3                                    db             "Lista vacia", '$', 11 dup (?)
_0                                                dd             0.0            
_1                                                dd             1.0            
_valorNoDeterminado                               dd             -1.0           
_Ingrese_un_valor_pivot_mayor_o_igual_a_1____4    db             "Ingrese un valor pivot mayor o igual a 1: ", '$', 42 dup (?)
pivot                                             dd             ?              
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
jne branch1

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
jne branch1
displayString _lista_vacia_3
NEWLINE
JMP FOOTER
NEWLINE
branch1:
displayString _Elemento_encontrado_en_posicion____5
NEWLINE
fld resul
fld _1
FADD
fstp resul
DisplayFloat resul,1
NEWLINE
FOOTER:
mov AX,4C00h                  ; Indica que debe finalizar la ejecución
int 21h

END inicio