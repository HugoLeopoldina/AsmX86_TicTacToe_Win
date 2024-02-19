; kernel32.dll
extern _ReadFile

; utils.asm
extern allocateMemory
extern deallocateMemory
extern reallocateMemory
extern cleanTerminal
extern printNewLine
extern zeroMemory
extern copyString
extern print

extern PRINT_STRING
extern PRINT_CHAR
extern INPUT_HANDLE

section .bss
    turn resb 16 ; 'Turno: {currentPlayer->name}'

section .data
    global game

    line db "Linha: ", 0
    col db "Coluna: ", 0
    rowError db "Limite de linha excedido!", 0
    colError db "Limite de coluna excedido!", 0
    winner db " Venceu!!", 0xA, 0
    draw db "Empate!!", 0xA, 0

    red_color db 0x1B, "[31m ", 0 ; \033[31m
    normal_color db 0x1B, "[0m", 0 ; \033[0m

    tableNumbers db "   1 2 3", 0 ; Numeros das colunas a ser exibido
    turnString db "Turno: ", 0

    game dd 0 ; Objeto Game
    table dd 0 ; Tabela
    players dd 0 ; Jogadores
    player1 dd 0 ; Jogador 1
    player2 dd 0 ; Jogador 2
    p1Name db "Player 1", 0
    p2Name db "Player 2", 0

section .text
    global createGame ; Aloca a estrutura Game
    global freeGame ; Libera a estrutura Game

    global printGame ; Imprime o jogo (tabela)
    global printTurn ; Imprime o turno (vez do jogador)
    global printError ; Imprime uma menssagem de error
    global printWinner ; Imprime o ganhador
    global printDraw ; Imprime uma menssagem de empate

    global getChoices ; Obtem as escolhas (linha e coluna) do jogador atual
    global checkWinner ; Verifica na tabela e retorna o ganhador
    global makeChoices ; Define a chave (key) do jogador atual na tabela e é 
    ; responsável por alterar o ponteiro do jogador atual

    global getTablePosition ; Obtem o endereço para a posição na tabela (x, y)

;----------------------------------------------------------------------------------------------------------

    createGame:
        push ebp
        mov ebp, esp

        ; Game
        push 12
        call allocateMemory
        mov [game], eax

        ; Tabela = lista de strings ( 3 x 3 )
        ; Lista 3 x 3 = 9 bytes

        ; Table
        push 9
        call allocateMemory
        mov [table], eax

        ; Players
        push 8 ; 2 Players
        call allocateMemory
        mov [players], eax

        ; Name: 4 bytes (ponteiro para chars)
        ; key: 1 byte (char)
        ; choice: 4 bytes (ponteiro para 2 inteiros)
        ; choices: 4 bytes (ponteiro para ponteiros para 2 inteiros)
        ; choicesCount: 4 bytes (inteiro)

        ; Player 1
        push 17
        call allocateMemory
        mov [player1], eax

        ; Definindo os valores do Player 1
        mov dword [eax], p1Name ; Name
        mov byte [eax + 4], 0x58 ; key 'X'
        ; choice, choices e choicesCount é 0 por enquanto

        ; Player 2
        push 17
        call allocateMemory
        mov [player2], eax

        mov dword [eax], p2Name
        mov byte [eax + 4], 0x4F ; key 'O'

        ; Recuperando os objetos
        mov eax, [players]
        mov ebx, [player1]
        mov ecx, [player2]

        ; Definindo os players alocados no ponteiro Players (lista)
        mov dword [eax], ebx ; p1
        mov dword [eax + 4], ecx ; p2

        ; Atribuindo os objetos à estrutura Game
        mov eax, ebx ; player atual (p1)
        mov ebx, [players]
        mov ecx, [table]

        mov dword [game], eax ; game = currentPlayer
        mov dword [game + 4], ebx ; game + 4 = players
        mov dword [game + 8], ecx ; game + 8 = table

        pop ebp
        ret

;----------------------------------------------------------------------------------------------------------

    freeGame:
        push ebp
        mov ebp, esp

        ; Table
        push dword [table]
        call deallocateMemory

        ; Player 1
        push dword [player1]
        call deallocateMemory

        ; Player 2
        push dword [player2]
        call deallocateMemory

        ; Players
        push dword [players]
        call deallocateMemory

        ; Game
        push dword [game]
        call deallocateMemory

        pop ebp
        ret

;----------------------------------------------------------------------------------------------------------

    printGame:
        push ebp
        mov ebp, esp

        call cleanTerminal
        call printNewLine

        push dword [PRINT_STRING]
        push tableNumbers
        call print

        call printNewLine
        call printNewLine

        sub esp, 8 ; row e col

        mov dword [esp], 0 ; ; row controle de loop
        rowLoop:
            mov dword [esp + 4], 0 ; col controle de loop

            mov eax, [esp]
            inc eax
            add eax, 0x30

            ; '1', '2', '3'
            push dword [PRINT_CHAR]
            push eax
            call print

            ; Imprimindo 2 espaços após os numeros das linhas
            sub esp, 2
            mov byte [esp], 0x20
            mov byte [esp + 1], 0x20
            mov eax, esp

            push dword [PRINT_STRING]
            push eax
            call print
            add esp, 2

            colLoop:
                mov eax, [esp + 4]

                ; ebx = row * 3
                mov ebx, [esp]
                imul ebx, 3

                ; eax = colunas ( 3 em 3 )
                add eax, ebx

                mov ebx, [game + 8] ; game + 8 = table]

                ; Somar o endereço da tabela com o valor da linha (contador * 3)
                add ebx, eax
                movzx ebx, byte [ebx] ; Recupera a chave no endereço atual da tabela
                ; e converte para dword 
                
                ; Imprime o caractere da tabela
                cmp ebx, 0
                je printSpace
                jmp printKey

                printSpace:
                    push dword [PRINT_CHAR]
                    push 0x20 ; ' '
                    call print

                    jmp continue

                ; Imprime a chave do jogador
                printKey:
                    push dword [PRINT_CHAR]
                    push ebx
                    call print

                continue:
                    ; Imprimir outro espaço
                    push dword [PRINT_CHAR]
                    push 0x20
                    call print

                    inc dword [esp + 4]
                    cmp dword [esp + 4], 3
                    jl colLoop

            call printNewLine

            inc dword [esp]
            cmp dword [esp], 3
            jl rowLoop

        call printNewLine

        add esp, 8
        pop ebp
        ret

;----------------------------------------------------------------------------------------------------------

    printTurn:
        push ebp
        mov ebp, esp

        push turn
        call zeroMemory

        mov edx, turn

        push edx
        push turnString
        call copyString

        mov eax, [game] ; currentPlayer
        mov ebx, [eax] ; currentPlayer->name

        ; Reposicionar para copiar o nome do player
        mov edx, turn
        add edx, 7

        push edx
        push ebx
        call copyString

        call printNewLine

        push dword [PRINT_STRING]
        push turn
        call print

        pop ebp
        ret

;----------------------------------------------------------------------------------------------------------

    getTablePosition:
        push ebp
        mov ebp, esp

        mov eax, [game + 8] ; tabela
        mov ebx, [ebp + 12] ; coluna
        mov ecx, [ebp + 8] ; linha

        dec ebx ; Incluir zero 
        dec ecx

        ; Exemplo de entrada:
        ; Linha: 2
        ; Coluna: 3
        ; Pra pegar a posição exata na tabela 3x3, é necessário multiplicar a linha por 3,
        ; porque o array é um bloco CONTINUO de 9 bytes, logo se multiplicar-mos a linha por 3
        ; vamos obter a posição y exata na tabela (2 * 3 = 6), somar a linha
        ; pela coluna (6 + 3 = 9), então se somar-mos o endereço atual da tabela com esta posição,
        ; a posição exata da tabela é retornada
        imul ecx, 3
        add ecx, ebx
        add eax, ecx

        pop ebp
        pop ecx

        add esp, 8
        push ecx
        ret

;----------------------------------------------------------------------------------------------------------

    printError:
        push ebp
        mov ebp, esp

        call printGame

        sub esp, 3
        mov dword [esp], 0x00203E ; '> '
        mov ebx, esp

        push dword [PRINT_STRING]
        push ebx
        call print
        add esp, 3

        push dword [PRINT_STRING]
        push red_color
        call print

        mov eax, [ebp + 8] ; Menssagem de erro

        push dword [PRINT_STRING]
        push eax
        call print

        push dword [PRINT_STRING]
        push normal_color
        call print

        call printTurn

        pop ebp
        pop ecx

        add esp, 4
        push ecx
        ret

;----------------------------------------------------------------------------------------------------------

    getChoices:
        push ebp
        mov ebp, esp

        ; Alocar memoria para dois inteiros (linha e coluna)
        push 8
        call allocateMemory

        sub esp, 8

        mov dword [esp], eax ; Linha
        add eax, 4
        mov dword [esp + 4], eax ; Coluna

        getChoicesRowLoop:
            mov eax, [esp]
            mov dword [eax], 0 ; Zerar linha

            call printNewLine
            
            push dword [PRINT_STRING]
            push line ; "Linha: "
            call print

            ; Entrada de dados para o valor da linha
            push 0
            push 0
            push 3 ; 1º será a linha, 2º carriage return '\r', 3º new line '\n' = 'x\r\n'
            push dword [esp + 12] ; Endereço local alocado (linha)
            push dword [INPUT_HANDLE]
            call _ReadFile

            ; Verificar se o valor da linha é maior que 3 e menor que 1
            ; caso o a entrada seja apenas 1 byte, o segundo será o caractere
            ; especial '\r' (0xD), caso seja 2 bytes será um erro
            mov eax, [esp] ; Linha (3 caracteres)

            cmp byte [eax + 1], 0xD ; Compara o byte 2 com '\r'
            jne getChoicesRowError

            movzx ebx, byte [eax] ; byte 1
            sub ebx, 0x30 ; converte em inteiro

            ; Convertendo a linha de char para int
            mov byte [eax], bl

            ; Linha maior que 3?
            cmp ebx, 3
            ja getChoicesRowError

            ; Linha menor que 1?
            cmp ebx, 1
            jl getChoicesRowError

            ; Reimprimir tudo por conta do error que permanece caso
            ; nada é escrito na entrada, logo, o error é removido
            call printGame
            call printTurn
            call printNewLine

            ; imprimir a linha
            push dword [PRINT_STRING]
            push line
            call print

            mov ebx, [esp] ; linha (int)
            movzx ebx, byte [ebx]
            add ebx, 0x30 ; int para char

            push dword [PRINT_CHAR]
            push ebx
            call print

            call printNewLine

            jmp getChoicesColLoop

            getChoicesRowError:
                push rowError
                call printError
                jmp getChoicesRowLoop

        getChoicesColLoop:
            mov eax, [esp + 4]
            mov dword [eax], 0 ; zerar coluna

            push dword [PRINT_STRING]
            push col
            call print

            push 0
            push 0
            push 3
            push dword [esp + 16]
            push dword [INPUT_HANDLE]
            call _ReadFile

            mov eax, [esp + 4] ; Aponta para o primeiro byte da coluna

            cmp byte [eax + 1], 0xD
            jne getChoicesColError

            movzx ebx, byte [eax]
            sub ebx, 0x30
            
            ; Convertendo a coluna de char para int
            mov byte [eax], bl

            cmp ebx, 3
            ja getChoicesColError

            cmp ebx, 1
            jl getChoicesColError
            jmp getChoicesEnd

            getChoicesColError:
                push colError
                call printError

                call printNewLine

                ; Imprimir a linha

                push dword [PRINT_STRING]
                push line
                call print

                mov ebx, [esp] ; linha (int)
                movzx ebx, byte [ebx]
                add ebx, 0x30 ; int para char

                push dword [PRINT_CHAR]
                push ebx
                call print

                call printNewLine
                jmp getChoicesColLoop

        getChoicesEnd:
            mov ebx, [esp] ; linha

            mov eax, [game] ; game->currentPlayer->name
            lea eax, [eax + 5] ; eax = &game->currentPlayer->choice

            mov dword [eax], ebx ; game->currentPlayer->choice = &linha

            add esp, 8

            pop ebp
            ret

;----------------------------------------------------------------------------------------------------------

    checkWinner:
        push ebp
        mov ebp, esp

        mov esi, [game + 8] ; table

        sub esp, 4 ; winner
        mov dword [esp], 0

        ; Devo percorrer os player e definir os pontos de cada posição na tabela
        mov ebx, 0
        checkWinnerPlayerLoop:
            cmp ebx, 2
            je checkWinnerEnd

            mov eax, [game + 4]
            mov ecx, ebx
            imul ecx, 4
            add eax, ecx ; ecx = 0 ... 4
            mov eax, [eax]
            mov dword [esp], eax
            ; eax = player

            ; Percorrer a tabela
            mov edx, 0
            checkWinnerTableLoop:
                cmp edx, 3
                je checkWinnerPlayerLoopEnd

                ; X
                ; X
                ; X
                mov ecx, 0
                verticalPointsLoop:
                    cmp ecx, 3
                    je checkWinnerEnd

                    ; char currentCol = table[row][col];
                    mov eax, ecx
                    imul eax, 3
                    add eax, edx

                    push ebx

                    movzx ebx, byte [esi + eax] ; chave na tabela
                    mov eax, [esp + 4] ; player
                    movzx eax, byte [eax + 4] ; player->key

                    cmp eax, ebx
                    pop ebx
                    je addVerticalPoints
                    mov ecx, 0

                ; X X X
                ;
                ;
                horizontalPointsLoop:
                    ; Só vai pular quando alcançar 3 pontos
                    cmp ecx, 3
                    je checkWinnerEnd

                    mov edi, edx
                    imul edi, 3
                    add edi, ecx

                    push ebx
                    ; char currentRow = table[col][row];
                    movzx ebx, byte [esi + edi]
                    cmp eax, ebx
                    pop ebx
                    je addHorizontalPoints

                    ; zerar o contador para o proximo loop
                    mov ecx, 0

                ; X    
                ;   X  
                ;     X
                diagonalPointsLoop:
                    cmp ecx, 3
                    je checkWinnerEnd

                    ; char currentDiag = table[row][row];
                    push ebx
                    mov ebx, ecx
                    imul ebx, 4
                    movzx ebx, byte [esi + ebx]
                    cmp ebx, eax
                    pop ebx
                    je addDiagonalPoints
                    mov ecx, 0

                ;     X
                ;   X
                ; X
                antiDiagonalPointsLoop:
                    cmp ecx, 3
                    je checkWinnerEnd

                    ; char currentAntiDiag = table[2-row][row];
                    push ebx
                    mov ebx, 2
                    sub ebx, ecx

                    push ebx
                    mov ebx, 3
                    imul ebx, ecx
                    add ebx, [esp]
                    add esp, 4
                    movzx ebx, byte [esi + ebx]
                    cmp ebx, eax
                    pop ebx
                    je addAntiDiagonalPoints
                    mov ecx, 0                 

                cmp edx, 2
                je withoutWinner                
                jmp checkWinnerTableLoopEnd

                withoutWinner:
                    push edx

                    ; verificar empate
                    mov eax, [game + 4]
                    mov edx, [eax]
                    mov eax, [eax + 4]

                    mov edx, [edx + 13] ; player1->choicesCount
                    mov eax, [eax + 13] ; player2->choicesCount

                    add eax, edx
                    cmp eax, 9
                    je checkWinnerATie

                    pop edx

                    mov dword [esp], 0
                    jmp checkWinnerTableLoopEnd

                addVerticalPoints:
                    inc ecx
                    jmp verticalPointsLoop

                addHorizontalPoints:
                    inc ecx
                    jmp horizontalPointsLoop

                addDiagonalPoints:
                    inc ecx
                    jmp diagonalPointsLoop

                addAntiDiagonalPoints:
                    inc ecx
                    jmp antiDiagonalPointsLoop

                checkWinnerTableLoopEnd:
                    inc edx
                    jmp checkWinnerTableLoop

                checkWinnerATie:
                    pop edx
                    mov dword [esp], 1
                    jmp checkWinnerTableLoopEnd

            checkWinnerPlayerLoopEnd:
                inc ebx
                jmp checkWinnerPlayerLoop

        checkWinnerEnd:
            pop eax
            ; eax == 0 = sem ganhador
            ; eax == 1 = empate
            ; eax != 0 != 1 = ganhador
            pop ebp
            ret

;----------------------------------------------------------------------------------------------------------

    printWinner:
        push ebp
        mov ebp, esp

        sub esp, 4
        mov dword [esp], eax

        call printGame
        call printNewLine

        pop eax

        ; eax = winner
        push PRINT_STRING
        push dword [eax] ; name
        call print

        push PRINT_STRING
        push winner
        call print

        call printNewLine

        pop ebp
        ret

;----------------------------------------------------------------------------------------------------------

    makeChoices:
        push ebp
        mov ebp, esp


        ; choice
        mov eax, [game]
        mov eax, [eax + 5] ; game->currentPlayer->choice

        movzx ebx, byte [eax]
        movzx ecx, byte [eax + 4]

        push ecx ; coluna
        push ebx ; linha
        call getTablePosition
        ; eax = Endereço para a posição na tabela

        cmp byte [eax], 0
        ; Caso a posição na tabela não seja 0, a posição ja esta em uso
        jne makeChoicesNotZero
        jmp makeChoicesHasZero

        ; Retorna false
        makeChoicesNotZero:
            mov eax, 1
            jmp makeChoicesEnd

        ; Escreve a chave na tabela
        ; Retorna true
        makeChoicesHasZero:
            mov edx, [game]
            movzx edx, byte [edx + 4] ; currentPlayer->key
            mov byte [eax], dl ; byte menos significativo de edx (currentPlayer->key)

            ; Incrementar choicesCount
            mov eax, [game]
            inc dword [eax + 13] ; currentPlayer->choicesCount++
            mov ebx, [eax + 13]

            ; Realocar o bloco do heap apontado por currentPlayer->choice (escolha atual)
            ; pelo tamanho 8 * currentPlayer->choicesCount, assim fazendo com
            ; que este bloco seja liberado e um novo bloco no heap seja criado
            ; com os valores copiados e com o tamanho estendido para uma nova escolha (2 inteiros)
            ; logo, uma lista de lista de dois inteiros é criado
            ; e o ponteiro será atribuido para currentPlayer->choices

            ; Incrementar choicesCount novamente por conta da forma de que vai ser tratada esta lista.
            ; Será tratado como inteiros continuos e não ponteiro para ponteiros para 2 inteiros
            ; Exemplo: o usuario fez 2 escolhas, choicesCount vai ser 2, (2 + 1) * 8 = 24 bytes
            ; logo sera realocado para 24 bytes, tendo 2 escolhas e 1 espaço para nova escolha

            inc ebx
            imul ebx, 8 ; novo tamanho choicesCount * 4
            mov eax, [eax + 5] ; choice

            push ebx
            push eax
            call reallocateMemory
            ; eax = endereço do bloco alocado

            mov ebx, [game]
            lea ebx, [ebx + 9] ; choices
            mov [ebx], eax
            ; choices + (choicesCount * 8) = nova escolha alocada

            ; Definir o proximo player (verificação pelo key)
            mov eax, [game] ; currentPlayer
            mov ebx, [game + 4] ; players

            movzx ecx, byte [eax + 4] ; currentPlayer->key

            cmp ecx, 0x58 ; 'X'
            je changeP2
            jmp changeP1

            changeP1:
                mov ebx, [ebx]
                mov [game], ebx
                jmp makeChoicesHasZeroEnd

            changeP2:
                mov ebx, [ebx + 4]
                mov [game], ebx

            makeChoicesHasZeroEnd:
                mov eax, 0

        makeChoicesEnd:
            pop ebp
            ret

;----------------------------------------------------------------------------------------------------------

    printDraw:
        push ebp
        mov ebp, esp

        call printGame

        push dword [PRINT_STRING]
        push draw
        call print

        call printNewLine

        pop ebp
        ret