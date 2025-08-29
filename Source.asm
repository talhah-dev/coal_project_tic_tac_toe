; ================================================
; Tic-Tac-Toe (2 Players) - MASM (Irvine32)
; Console, single file, friendly comments
; -----------------------------------------------
; Build (example):
;   ml /c /coff ttt.asm
;   link /SUBSYSTEM:CONSOLE ttt.obj Irvine32.lib
; Run:
;   ttt.exe
; ================================================

INCLUDE Irvine32.inc

.data
; ---------------------------
; Board representation
; 9 cells: 0 = empty, 1 = X, 2 = O
; ---------------------------
board           DWORD 9 DUP(0)

; ---------------------------
; State variables
; ---------------------------
currentPlayer   DWORD 1         ; 1 = X starts, 2 = O
playAgainFlag   DWORD 1         ; 1 => loop another game, 0 => exit

; ---------------------------
; UI strings (null-terminated for WriteString)
; ---------------------------
msgTitle        BYTE 13,10,"===== TIC-TAC-TOE (2 Players) =====",13,10,0
msgHowTo        BYTE "Choose a position (1-9). Empty spots show their number.",13,10,0
msgTurnPrefix   BYTE "Player ",0
msgTurnX        BYTE "X",0
msgTurnO        BYTE "O",0
msgTurnSuffix   BYTE ", it's your turn. Enter position (1-9): ",0

msgInvalid      BYTE "Invalid input. Please enter a number 1..9.",13,10,0
msgTaken        BYTE "That spot is already taken. Try another.",13,10,0

msgWinPrefix    BYTE "Player ",0
msgWinX         BYTE "X",0
msgWinO         BYTE "O",0
msgWinSuffix    BYTE " WINS! ",0

msgDraw         BYTE "It's a DRAW! No more empty spots.",13,10,0

msgPlayAgain    BYTE 13,10,"Play again? Enter 1 for YES, 0 for NO: ",0
msgBye          BYTE 13,10,"Thanks for playing. Bye!",13,10,0

; Board drawing pieces
rowSep          BYTE "---+---+---",0
pipeSpace       BYTE " | ",0
spacePrefix     BYTE " ",0
newline         BYTE 13,10,0

.code

; ------------------------------------------------
; main - Program entry
; ------------------------------------------------
main PROC
    call GameLoopController
    exit
main ENDP

; ------------------------------------------------
; GameLoopController
; - Shows title once
; - Loops full games while user picks play again
; ------------------------------------------------
GameLoopController PROC USES eax edx
    ; Show title once
    mov edx, OFFSET msgTitle
    call WriteString

WhilePlayAgain:
    ; Set playAgainFlag = 0 by default; set to 1 only if user chooses
    mov playAgainFlag, 0

    ; Start one full game
    call RunSingleGame

    ; Ask to play again
AskPlayAgain:
    mov edx, OFFSET msgPlayAgain
    call WriteString
    call ReadDec                 ; EAX = user's number
    cmp eax, 1
    je  SetPlayAgain
    cmp eax, 0
    je  DoneAsk
    ; Otherwise invalid -> ask again
    jmp AskPlayAgain

SetPlayAgain:
    mov playAgainFlag, 1

DoneAsk:
    cmp playAgainFlag, 1
    je  WhilePlayAgain

    ; Say goodbye
    mov edx, OFFSET msgBye
    call WriteString
    ret
GameLoopController ENDP

; ------------------------------------------------
; RunSingleGame
; - Resets board
; - Sets currentPlayer = 1 (X)
; - Repeats turns until win or draw
; ------------------------------------------------
RunSingleGame PROC USES eax
    call ResetBoard
    mov currentPlayer, 1

TurnLoop:
    call Clrscr
    call ShowHeader
    call DisplayBoard

    ; Prompt and get a valid move (EAX = index 0..8)
    call PromptAndGetMove

    ; Place current player's mark at the chosen cell
    ; EAX = index
    call PlaceMark

    ; Check winner
    call CheckWin                ; EAX = 0 (no win), 1 (X), 2 (O)
    cmp eax, 0
    jne SomeoneWon

    ; No winner yet, check draw
    call CheckDraw               ; EAX = 1 if draw, 0 otherwise
    cmp eax, 1
    je  IsDraw

    ; Next player's turn
    call SwitchPlayer
    jmp TurnLoop

SomeoneWon:
    ; Show final board and announce winner
    call Clrscr
    call ShowHeader
    call DisplayBoard
    ; EAX = winner (1 or 2)
    push eax
    mov edx, OFFSET msgWinPrefix
    call WriteString
    pop eax
    cmp eax, 1
    jne WinnerIsO
    mov edx, OFFSET msgWinX
    call WriteString
    jmp ShowWinTail
WinnerIsO:
    mov edx, OFFSET msgWinO
    call WriteString
ShowWinTail:
    mov edx, OFFSET msgWinSuffix
    call WriteString
    call Crlf
    ret

IsDraw:
    call Clrscr
    call ShowHeader
    call DisplayBoard
    mov edx, OFFSET msgDraw
    call WriteString
    ret
RunSingleGame ENDP

; ------------------------------------------------
; ShowHeader
; - Prints title + help line
; ------------------------------------------------
ShowHeader PROC USES edx
    mov edx, OFFSET msgTitle
    call WriteString
    mov edx, OFFSET msgHowTo
    call WriteString
    ret
ShowHeader ENDP

; ------------------------------------------------
; ResetBoard
; - Fills board with 0 (empty)
; ------------------------------------------------
ResetBoard PROC USES eax ecx edi
    mov ecx, 9
    mov eax, 0
    mov edi, OFFSET board
FillLoop:
    mov [edi], eax
    add edi, 4
    loop FillLoop
    ret
ResetBoard ENDP

; ------------------------------------------------
; DisplayBoard
; - Renders the 3x3 grid:
;     1 | 2 | 3
;    ---+---+---
;     4 | 5 | 6
;    ---+---+---
;     7 | 8 | 9
; - Empty cells show their position number
; - Taken cells show X or O
; ------------------------------------------------
DisplayBoard PROC USES eax ecx edx
    ; row 0
    call PrintRow0
    mov edx, OFFSET rowSep
    call WriteString
    call Crlf
    ; row 1
    call PrintRow1
    mov edx, OFFSET rowSep
    call WriteString
    call Crlf
    ; row 2
    call PrintRow2
    call Crlf
    ret
DisplayBoard ENDP

; Helper: print a row (0..2). We split for clarity.

PrintRow0 PROC
    ; indices: 0,1,2
    call PrintRowHeader          ; leading space
    mov eax, 0
    call PrintCell
    call PrintMidPipes
    mov eax, 1
    call PrintCell
    call PrintMidPipes
    mov eax, 2
    call PrintCell
    call Crlf
    ret
PrintRow0 ENDP

PrintRow1 PROC
    ; indices: 3,4,5
    call PrintRowHeader
    mov eax, 3
    call PrintCell
    call PrintMidPipes
    mov eax, 4
    call PrintCell
    call PrintMidPipes
    mov eax, 5
    call PrintCell
    call Crlf
    ret
PrintRow1 ENDP

PrintRow2 PROC
    ; indices: 6,7,8
    call PrintRowHeader
    mov eax, 6
    call PrintCell
    call PrintMidPipes
    mov eax, 7
    call PrintCell
    call PrintMidPipes
    mov eax, 8
    call PrintCell
    ret
PrintRow2 ENDP

PrintRowHeader PROC USES edx
    mov edx, OFFSET spacePrefix  ; just a leading space for nice alignment
    call WriteString
    ret
PrintRowHeader ENDP

PrintMidPipes PROC USES edx
    mov edx, OFFSET pipeSpace
    call WriteString
    ret
PrintMidPipes ENDP

; ------------------------------------------------
; PrintCell
; IN : EAX = cell index (0..8)
; OUT: (prints one symbol) either X, O, or position number (1..9)
; ------------------------------------------------
PrintCell PROC USES eax ebx edi edx
    ; Compute address board[index]
    mov edi, eax
    shl edi, 2                   ; *4
    mov ebx, [board + edi]       ; EBX = value at that cell

    cmp ebx, 0
    jne NotEmpty

    ; Empty -> show (index+1)
    mov eax, edi
    shr eax, 2                   ; EAX = index again
    inc eax                      ; 1..9
    call WriteDec
    ret

NotEmpty:
    cmp ebx, 1
    jne IsO
    ; Print 'X'
    mov al, 'X'
    call WriteChar
    ret
IsO:
    mov al, 'O'
    call WriteChar
    ret
PrintCell ENDP

; ------------------------------------------------
; PromptAndGetMove
; - Shows "Player X/O ... Enter position (1-9):"
; - Repeats until user enters a valid, empty spot
; OUT: EAX = valid index (0..8)
; ------------------------------------------------
PromptAndGetMove PROC USES ebx ecx edx
PromptAgain:
    ; Print "Player ? ..."
    mov edx, OFFSET msgTurnPrefix
    call WriteString

    mov ebx, currentPlayer
    cmp ebx, 1
    jne ShowO
    mov edx, OFFSET msgTurnX
    call WriteString
    jmp AfterName
ShowO:
    mov edx, OFFSET msgTurnO
    call WriteString
AfterName:
    mov edx, OFFSET msgTurnSuffix
    call WriteString

    ; Read input number
    call ReadDec               ; EAX = user number

    ; Validate 1..9
    cmp eax, 1
    jb BadInput
    cmp eax, 9
    ja BadInput

    ; Convert to index 0..8
    dec eax

    ; Check if empty
    push eax                   ; save index
    mov ecx, eax               ; ECX = index
    shl ecx, 2                 ; *4
    mov ebx, [board + ecx]     ; EBX = cell value
    pop eax                    ; restore index
    cmp ebx, 0
    jne SpotTaken

    ; OK
    ret

BadInput:
    mov edx, OFFSET msgInvalid
    call WriteString
    jmp PromptAgain

SpotTaken:
    mov edx, OFFSET msgTaken
    call WriteString
    jmp PromptAgain
PromptAndGetMove ENDP

; ------------------------------------------------
; PlaceMark
; IN : EAX = index (0..8)
; - Writes currentPlayer (1 or 2) into board[index]
; ------------------------------------------------
PlaceMark PROC USES eax ebx ecx
    mov ebx, currentPlayer
    mov ecx, eax
    shl ecx, 2
    mov [board + ecx], ebx
    ret
PlaceMark ENDP

; ------------------------------------------------
; SwitchPlayer
; - Toggles currentPlayer between 1 and 2
; ------------------------------------------------
SwitchPlayer PROC USES eax
    mov eax, currentPlayer
    cmp eax, 1
    jne SetToX
    mov currentPlayer, 2
    ret
SetToX:
    mov currentPlayer, 1
    ret
SwitchPlayer ENDP

; ------------------------------------------------
; CheckWin
; OUT: EAX = 0 (no win), 1 (X wins), 2 (O wins)
; - Checks the 8 winning lines
; ------------------------------------------------
CheckWin PROC USES ebx ecx edx esi
    ; Helper macro-like: load three cells and test equal/nonzero
    ; We'll write the 8 lines explicitly for clarity.

    ; Line 0: 0,1,2
    mov esi, 0
    call LoadTriplet
    call TestTriplet
    cmp eax, 0
    jne Done

    ; Line 1: 3,4,5
    mov esi, 3
    call LoadTriplet
    call TestTriplet
    cmp eax, 0
    jne Done

    ; Line 2: 6,7,8
    mov esi, 6
    call LoadTriplet
    call TestTriplet
    cmp eax, 0
    jne Done

    ; Line 3: 0,3,6
    mov esi, 0
    call LoadColTriplet0
    call TestTriplet
    cmp eax, 0
    jne Done

    ; Line 4: 1,4,7
    mov esi, 1
    call LoadColTriplet1
    call TestTriplet
    cmp eax, 0
    jne Done

    ; Line 5: 2,5,8
    mov esi, 2
    call LoadColTriplet2
    call TestTriplet
    cmp eax, 0
    jne Done

    ; Line 6: 0,4,8
    call LoadDiag0
    call TestTriplet
    cmp eax, 0
    jne Done

    ; Line 7: 2,4,6
    call LoadDiag1
    call TestTriplet
    cmp eax, 0
    jne Done

    xor eax, eax      ; no winner
Done:
    ret
CheckWin ENDP

; Helpers to load three values into EBX, ECX, EDX, then TestTriplet uses them.

; Row triplet starting at ESI (ESI = 0,3,6)
LoadTriplet PROC USES esi edi
    ; EBX = board[ESI], ECX = board[ESI+1], EDX = board[ESI+2]
    mov edi, esi
    shl edi, 2
    mov ebx, [board + edi]

    mov edi, esi
    add edi, 1
    shl edi, 2
    mov ecx, [board + edi]

    mov edi, esi
    add edi, 2
    shl edi, 2
    mov edx, [board + edi]
    ret
LoadTriplet ENDP

; Column triplet: indices 0,3,6 from base ESI=0; or 1,4,7; or 2,5,8
LoadColTriplet0 PROC USES esi edi
    ; ESI assumed 0
    ; EBX=0, ECX=3, EDX=6
    mov ebx, [board + (0*4)]
    mov ecx, [board + (3*4)]
    mov edx, [board + (6*4)]
    ret
LoadColTriplet0 ENDP

LoadColTriplet1 PROC USES esi edi
    ; EBX=1, ECX=4, EDX=7
    mov ebx, [board + (1*4)]
    mov ecx, [board + (4*4)]
    mov edx, [board + (7*4)]
    ret
LoadColTriplet1 ENDP

LoadColTriplet2 PROC USES esi edi
    ; EBX=2, ECX=5, EDX=8
    mov ebx, [board + (2*4)]
    mov ecx, [board + (5*4)]
    mov edx, [board + (8*4)]
    ret
LoadColTriplet2 ENDP

; Diagonals
LoadDiag0 PROC
    ; 0,4,8
    mov ebx, [board + (0*4)]
    mov ecx, [board + (4*4)]
    mov edx, [board + (8*4)]
    ret
LoadDiag0 ENDP

LoadDiag1 PROC
    ; 2,4,6
    mov ebx, [board + (2*4)]
    mov ecx, [board + (4*4)]
    mov edx, [board + (6*4)]
    ret
LoadDiag1 ENDP

; TestTriplet:
; IN : EBX, ECX, EDX
; OUT: EAX = 0 (no win) or 1/2 (who won)
TestTriplet PROC USES ebx ecx edx
    ; If EBX != 0 and EBX==ECX and EBX==EDX => winner = EBX
    cmp ebx, 0
    je  NotWin
    cmp ebx, ecx
    jne NotWin
    cmp ebx, edx
    jne NotWin
    mov eax, ebx
    ret
NotWin:
    xor eax, eax
    ret
TestTriplet ENDP

; ------------------------------------------------
; CheckDraw
; OUT: EAX = 1 if draw (no zeros), else 0
; NOTE: Call this only after confirming no winner.
; ------------------------------------------------
CheckDraw PROC USES eax ecx edi
    mov ecx, 9
    mov edi, OFFSET board
CheckLoop:
    mov eax, [edi]
    cmp eax, 0
    je  NotDraw
    add edi, 4
    loop CheckLoop
    mov eax, 1
    ret
NotDraw:
    xor eax, eax
    ret
CheckDraw ENDP

END main
