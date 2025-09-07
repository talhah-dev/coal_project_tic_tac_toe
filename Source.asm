INCLUDE Irvine32.inc

.data
board      BYTE '1','2','3','4','5','6','7','8','9'
turn       BYTE 'X'
sepLine    BYTE "--|---|--",0
pipeStr    BYTE " | ",0
msgEnter   BYTE "Enter position (1-9): ",0
msgInvalid BYTE "Invalid move! Try again.",0
msgWin     BYTE "Winner: ",0
msgDraw    BYTE "It's a DRAW!",0
msgTurn    BYTE "Player turn: ",0

.code

; ---------------------------------------------
; PrintBoard
; ---------------------------------------------
PrintBoard PROC
    ; Row 1
    mov al, board[0]          ; cell 1
    call WriteChar
    mov edx, OFFSET pipeStr   ; " | "
    call WriteString
    mov al, board[1]          ; cell 2
    call WriteChar
    mov edx, OFFSET pipeStr
    call WriteString
    mov al, board[2]          ; cell 3
    call WriteChar
    call Crlf

    mov edx, OFFSET sepLine   ; ---|---|---
    call WriteString
    call Crlf

    ; Row 2
    mov al, board[3]
    call WriteChar
    mov edx, OFFSET pipeStr
    call WriteString
    mov al, board[4]
    call WriteChar
    mov edx, OFFSET pipeStr
    call WriteString
    mov al, board[5]
    call WriteChar
    call Crlf

    mov edx, OFFSET sepLine
    call WriteString
    call Crlf

    ; Row 3
    mov al, board[6]
    call WriteChar
    mov edx, OFFSET pipeStr
    call WriteString
    mov al, board[7]
    call WriteChar
    mov edx, OFFSET pipeStr
    call WriteString
    mov al, board[8]
    call WriteChar
    call Crlf
    call Crlf
    ret
PrintBoard ENDP

; ---------------------------------------------
; CheckWin
;  - CF=0 on win, CF=1 otherwise
;  - Ensures the line is X or O (not 1..9)
; ---------------------------------------------
CheckWin PROC
    CHECK3 MACRO i, j, k, lblNext
        mov al, board[i]
        cmp al, 'X'        ; Is AL == 'X' ?
        je @F              ; yes -> skip the next test and continue
        cmp al, 'O'        ; otherwise, is AL == 'O' ?
        jne lblNext            
@@:     cmp al, board[j]
        jne lblNext        ; no -> not all three equal; go try next line
        cmp al, board[k]
        jne lblNext        ; no -> not all three equal; go try next line
        clc
        ret
    ENDM

    CHECK3 0,1,2, L1
L1: CHECK3 3,4,5, L2
L2: CHECK3 6,7,8, L3
L3: CHECK3 0,3,6, L4
L4: CHECK3 1,4,7, L5
L5: CHECK3 2,5,8, L6
L6: CHECK3 0,4,8, L7
L7: CHECK3 2,4,6, NoWin

NoWin:
    stc
    ret
CheckWin ENDP

; ---------------------------------------------
; Main
; ---------------------------------------------
main PROC
    call PrintBoard
    mov ecx, 9                ; moves remaining

GameLoop:
    ; show whose turn
    mov edx, OFFSET msgTurn
    call WriteString
    mov al, turn
    call WriteChar
    call Crlf

    ; prompt + read
    mov edx, OFFSET msgEnter
    call WriteString
    call ReadInt              ; EAX = 1..9
    sub eax, 1                ; -> 0..8
    cmp eax, 0
    jl BadInput
    cmp eax, 8
    jg BadInput

    ; check cell free
    mov bl, board[eax]
    cmp bl, 'X'
    je BadInput
    cmp bl, 'O'
    je BadInput

    ; place move
    mov bl, turn
    mov board[eax], bl

    call PrintBoard

    ; winner?
    call CheckWin
    jnc HaveWinner

    ; consume a move
    dec ecx
    jnz SwitchTurn

    ; draw
    mov edx, OFFSET msgDraw
    call WriteString
    call Crlf
    jmp Done

SwitchTurn:
    ; toggle X <-> O
    cmp turn, 'X'
    jne SetX
    mov turn, 'O'
    jmp GameLoop
SetX:
    mov turn, 'X'
    jmp GameLoop

BadInput:
    mov edx, OFFSET msgInvalid
    call WriteString
    call Crlf
    jmp GameLoop

HaveWinner:
    mov edx, OFFSET msgWin
    call WriteString
    mov al, turn
    call WriteChar
    call Crlf

Done:
    exit
main ENDP

END main
