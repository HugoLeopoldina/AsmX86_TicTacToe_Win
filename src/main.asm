; kernel32.dll
extern _ExitProcess

; utils.asm
extern getHandles
extern setUtf8CP
extern cleanTerminal

extern createGame
extern freeGame

extern printGame
extern printTurn
extern printError

extern getChoices
extern makeChoices

extern checkWinner
extern printWinner
extern printDraw

section .data
    positionError db "Posição já definida!", 0

section .text
    global start ; Ponto de entrada

    start:
        ; Inicialização
        call getHandles
        call setUtf8CP
        call cleanTerminal
        call createGame

        ; Loop principal
        mainLoop:
            call printGame
            call printTurn
            call getChoices

            makeChoicesLoop:
                call makeChoices
                ; Se eax == 1 posição ja definida

                cmp eax, 1
                je alreadDefined
                jmp mainLoopEnd

                alreadDefined:
                    push positionError
                    call printError
                    call getChoices
                    jmp makeChoicesLoop

            mainLoopEnd:
                call checkWinner

                ; sem ganhador
                cmp eax, 0
                je mainLoop

                ; empate
                cmp eax, 1
                je endInADraw

                ; ganhador
                jmp endWithWinner



        endWithWinner:
            call printWinner
            jmp finish

        endInADraw:
            call printDraw

        finish:
            call freeGame

            push 0
            call _ExitProcess
