flex EA3.l
pause
bison -dyv EA3.y
pause
gcc.exe lex.yy.c y.tab.c -o EA3.exe
pause
pause
EA3.exe test.txt
del lex.yy.c
del y.tab.c
del y.output
del y.tab.h
pause