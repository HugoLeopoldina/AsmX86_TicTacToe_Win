@echo off

nasm -f win32 .\src\main.asm -o .\main.o
nasm -f win32 .\src\utils.asm -o utils.o
nasm -f win32 .\src\game.asm -o game.o

ld -L C:\\windows\\system32 -lkernel32 -lmsvcrt .\main.o .\utils.o .\game.o -o .\bin\TTT.exe

del main.o
del utils.o
del game.o
