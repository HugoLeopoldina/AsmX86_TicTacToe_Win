; msvcrt.dll
extern _system

; kernel32.dll
extern _WriteFile
extern _GetStdHandle
extern _GetProcessHeap
extern _HeapAlloc
extern _HeapFree
extern _HeapReAlloc

section .data
    global PRINT_CHAR
    global PRINT_STRING
    global OUTPUT_HANDLE
    global HEAP_HANDLE
    global INPUT_HANDLE

    pointer dd 0 ; ponteiro base

    ; Identificadores
    INPUT_HANDLE dd 0 ; Indentificador para o dispositivo de entrada padrão
    HEAP_HANDLE dd 0 ; Indentificador para a memoria heap
    OUTPUT_HANDLE dd 0 ; Identificador para a saida padrão

    ; Sinalizadores
    PRINT_CHAR dd 0
    PRINT_STRING dd 1

    ; comandos de terminal
    utf8_codepage db "chcp 65001", 0
    clean_terminal db 0x1B, "[H", 0x1B, "[J", 0  ; \033[H\033[J equivalente CTRL + L

section .text
    global print ; Imprime um caractere ou uma string
    global printNewLine ; Imprime uma nova linha
    global copyString ; Copia uma string em um bloco de memoria

    global getHandles ; Obtem os identificadores necessarios para o programa
    global setUtf8CP ; Define o CodePage do terminal como UTF8
    global cleanTerminal ; Limpa o terminal

    global allocateMemory ; Aloca um bloco na memoria heap
    global deallocateMemory ; Libera a memoria alocada no heap
    global reallocateMemory ; Realoca um bloco de memoria
    global zeroMemory ; Zera um bloco de memória

    print:
        push ebp
        mov ebp, esp

        ; String/Caractere a ser impresso
        mov ebx, [ebp + 8] ; ebp + 8 = 1º parametro 

        ; Sinalizador ( define o que imprimir )
        mov ecx, [ebp + 12] ; ebp + 12 = 2º parametro

        mov [pointer], ebx ; string/char

        cmp ecx, dword [PRINT_CHAR]
        je printChar
        jmp printString
        
        printChar:
            mov eax, 1 ; Tamanho do caractere

            push 0
            push 0
            push eax
            push pointer
            push dword [OUTPUT_HANDLE]
            call _WriteFile

            jmp printContinueChar

        printString:
            ; Tamanho em bytes da string
            mov eax, 0
            mov ebx, [pointer]

            printStringLoop:
                cmp byte [ebx + eax], 0
                je printStringEnd

                inc eax
                jmp printStringLoop

            printStringEnd:    
                push 0
                push 0
                push eax
                push dword [pointer]
                push dword [OUTPUT_HANDLE]
                call _WriteFile
                jmp printContinueString

        printContinueChar:
            pop ebp
            pop ecx

            add esp, 8
            push ecx
            ret

        printContinueString:
            pop ebp
            pop ecx

            add esp, 8
            push ecx
            ret

    getHandles:
        push ebp
        mov ebp, esp

        push -11
        call _GetStdHandle
        mov [OUTPUT_HANDLE], eax

        push -10
        call _GetStdHandle
        mov [INPUT_HANDLE], eax

        call _GetProcessHeap
        mov [HEAP_HANDLE], eax

        pop ebp
        ret

    setUtf8CP:
        push ebp
        mov ebp, esp

        push utf8_codepage
        call _system

        ; system não limpa a pilha
        pop ecx

        pop ebp
        ret

    cleanTerminal:
        push ebp
        mov ebp, esp

        push dword [PRINT_STRING]
        push clean_terminal
        call print

        pop ebp
        ret

    allocateMemory:
        push ebp
        mov ebp, esp

        mov ebx, [ebp + 8] ; Tamanho

        push ebx
        push 0x8 ; HEAP_ZERO_MEMORY
        push dword [HEAP_HANDLE]
        call _HeapAlloc
        ; eax = endereço do bloco

        pop ebp
        pop ecx ; Salvando o endereço de retorno para limpar a pilha

        add esp, 4
        push ecx
        ret

    deallocateMemory:
        push ebp
        mov ebp, esp

        mov ebx, [ebp + 8]

        push ebx
        push 0x8
        push dword [HEAP_HANDLE]
        call _HeapFree

        pop ebp
        pop ecx

        add esp, 4
        push ecx

        ret

    zeroMemory:
        push ebp
        mov ebp, esp

        mov eax, [ebp + 8] ; Bloco alvo
        mov ebx, 0 ; contador

        zeroMemoryLoop:
            cmp byte [eax + ebx], 0
            je zeroMemoryEnd
            mov byte [eax + ebx], 0
            inc ebx
            jmp zeroMemoryLoop

        zeroMemoryEnd:
            pop ebp
            pop ecx

            add esp, 4
            push ecx
            ret

    printNewLine:
        push ebp
        mov ebp, esp

        ; \n
        push dword [PRINT_CHAR]
        push 0xA
        call print

        pop ebp
        ret
    
    reallocateMemory:
        push ebp
        mov ebp, esp

        mov eax, [ebp + 8] ; bloco a ser realocado
        mov ebx, [ebp + 12] ; tamanho

        push ebx
        push eax
        push 0x8
        push dword [HEAP_HANDLE]
        call _HeapReAlloc

        pop ebp
        pop ecx
        add esp, 8
        push ecx
        ret

    copyString:
        push ebp
        mov ebp, esp

        mov ebx, [esp + 8] ; Fonte
        mov ecx, [esp + 12] ; Destino
        mov esi, 0 ; Contador

        mov dword [esp], 0
        copyStringLoop:
            ; Verificando se o caractere atual é nulo
            cmp byte [ebx], 0
            je copyStringEnd

            ; Salvando o caractere atual no byte menos significativo de edx
            mov dl, byte [ebx]    

            ; Percorrendo e salvando o caractere atual no bloco de destino
            mov byte [ecx + esi], dl

            inc esi
            inc ebx

            jmp copyStringLoop
        
        copyStringEnd:
            pop ebp
            pop ecx

            add esp, 8
            push ecx
            ret
