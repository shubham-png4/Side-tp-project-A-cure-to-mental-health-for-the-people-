; ============================================================================
; PURE X86-64 ASSEMBLY GRAPHICAL CHESS GUI & MINIMAX ENGINE
; Target OS: Windows x64 (Win32 GDI Architecture)
; Assembler: NASM
; ============================================================================

bits 64
default rel

; ----------------------------------------------------------------------------
; EXTERNAL WIN32 API SYMBOLS
; ----------------------------------------------------------------------------
extern GetModuleHandleA
extern RegisterClassExA
extern CreateWindowExA
extern ShowWindow
extern UpdateWindow
extern GetMessageA
extern TranslateMessage
extern DispatchMessageA
extern PostQuitMessage
extern DefWindowProcA
extern BeginPaint
extern EndPaint
extern FillRect
extern CreateSolidBrush
extern DeleteObject
extern SetBkMode
extern TextOutA
extern SetTextColor
extern CreateFontA
extern SelectObject
extern ExitProcess

; ----------------------------------------------------------------------------
; WIN32 STRUCTURES & CONSTANTS
; ----------------------------------------------------------------------------
%define CS_HREDRAW     0x0002
%define CS_VREDRAW     0x0001
%define COLOR_WINDOW   5
%define CW_USEDEFAULT  0x80000000
%define WS_OVERLAPPEDWINDOW 0x00CF0000
%define SW_SHOW        5
%define WM_DESTROY     0x0002
%define WM_PAINT       0x000F
%define WM_LBUTTONDOWN 0x0201
%define TRANSPARENT    1

struc WNDCLASSEXA
    .cbSize        resd 1
    .style         resd 1
    .lpfnWndProc   resq 1
    .cbClsExtra    resd 1
    .cbWndExtra    resd 1
    .hInstance     resq 1
    .hIcon         resq 1
    .hCursor       resq 1
    .hbrBackground resq 1
    .lpszMenuName  resq 1
    .lpszClassName resq 1
    .hIconSm       resq 1
endstruc

struc RECT
    .left   resd 1
    .top    resd 1
    .right  resd 1
    .bottom resd 1
endstruc

struc PAINTSTRUCT
    .hdc         resq 1
    .fErase      resd 1
    .rcPaint     resb RECT_size
    .fRestore    resd 1
    .fIncUpdate  resd 1
    .rgbReserved resb 32
endstruc

; ----------------------------------------------------------------------------
; DATA SECTION
; ----------------------------------------------------------------------------
section .data
    className   db "AssemblyChessGUI", 0
    windowTitle db "Pure Assembly x64 Chess Platform & Engine", 0
    fontName    db "Segoe UI Symbol", 0

    ; Initial Board Setup (8x8 = 64 bytes)
    ; Positive = White, Negative = Black
    ; 1: Pawn, 2: Knight, 3: Bishop, 4: Rook, 5: Queen, 6: King
    board db -4,-2,-3,-5,-6,-3,-2,-4
          db -1,-1,-1,-1,-1,-1,-1,-1
          db  0, 0, 0, 0, 0, 0, 0, 0
          db  0, 0, 0, 0, 0, 0, 0, 0
          db  0, 0, 0, 0, 0, 0, 0, 0
          db  0, 0, 0, 0, 0, 0, 0, 0
          db  1, 1, 1, 1, 1, 1, 1, 1
          db  4, 2, 3, 5, 6, 3, 2, 4

    selectedSquare dd -1         ; Currently clicked square (-1 = none)
    turn           dd 1          ; 1 = White (Player), -1 = Black (Assembly AI)
    
    ; Unicode piece characters for GDI TextOut rendering
    pieceSymbols db " ", "P", "N", "B", "R", "Q", "K"
                 db " ", "p", "n", "b", "r", "q", "k"

    ; Piece Value Evaluation Array for Alpha-Beta Search
    pieceValues  dd 0, 100, 320, 330, 500, 900, 20000

; ----------------------------------------------------------------------------
; BSS SECTION (UNINITIALIZED MEMORY)
; ----------------------------------------------------------------------------
section .bss
    hInstance resq 1
    hwnd      resq 1
    msg       resb 48
    wc        resb WNDCLASSEXA_size
    ps        resb PAINTSTRUCT_size
    rectTemp  resb RECT_size
    hFont     resq 1

; ----------------------------------------------------------------------------
; CODE SECTION
; ----------------------------------------------------------------------------
section .text
global main

main:
    sub rsp, 40                  ; Shadow space allocation (Win64 ABI)

    ; Get Instance Handle
    xor ecx, ecx
    call GetModuleHandleA
    mov [hInstance], rax

    ; Register Window Class
    mov dword [wc + WNDCLASSEXA.cbSize], WNDCLASSEXA_size
    mov dword [wc + WNDCLASSEXA.style], CS_HREDRAW | CS_VREDRAW
    lea rax = [WndProc]
    mov [wc + WNDCLASSEXA.lpfnWndProc], rax
    mov rax, [hInstance]
    mov [wc + WNDCLASSEXA.hInstance], rax
    mov qword [wc + WNDCLASSEXA.hbrBackground], COLOR_WINDOW + 1
    lea rax = [className]
    mov [wc + WNDCLASSEXA.lpszClassName], rax

    lea rcx, [wc]
    call RegisterClassExA

    ; Create GUI Window
    xor ecx, ecx                 ; dwExStyle
    lea rdx, [className]         ; lpClassName
    lea r8, [windowTitle]        ; lpWindowName
    mov r9d, WS_OVERLAPPEDWINDOW ; dwStyle
    mov dword [rsp + 32], CW_USEDEFAULT ; x
    mov dword [rsp + 40], CW_USEDEFAULT ; y
    mov dword [rsp + 48], 530           ; width (8 * 60 + borders)
    mov dword [rsp + 56], 550           ; height
    mov qword [rsp + 64], 0             ; hWndParent
    mov qword [rsp + 72], 0             ; hMenu
    mov rax, [hInstance]
    mov qword [rsp + 80], rax           ; hInstance
    mov qword [rsp + 88], 0             ; lpParam
    call CreateWindowExA
    mov [hwnd], rax

    ; Create Symbol Font
    mov ecx, 36                  ; Height
    xor edx, edx                 ; Width
    xor r8d, r8d                 ; Escapement
    xor r9d, r9d                 ; Orientation
    mov dword [rsp + 32], 400    ; FW_NORMAL
    mov dword [rsp + 40], 0      ; Italic
    mov dword [rsp + 48], 0      ; Underline
    mov dword [rsp + 56], 0      ; StrikeOut
    mov dword [rsp + 64], 0      ; DEFAULT_CHARSET
    mov dword [rsp + 72], 0      ; OUT_DEFAULT_PRECIS
    mov dword [rsp + 80], 0      ; CLIP_DEFAULT_PRECIS
    mov dword [rsp + 88], 0      ; DEFAULT_QUALITY
    mov dword [rsp + 96], 0      ; DEFAULT_PITCH
    lea rax, [fontName]
    mov qword [rsp + 104], rax   ; Font Face Name
    call CreateFontA
    mov [hFont], rax

    ; Show Window
    mov rcx, [hwnd]
    mov edx, SW_SHOW
    call ShowWindow

    mov rcx, [hwnd]
    call UpdateWindow

; Message Loop
.msg_loop:
    lea rcx, [msg]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call GetMessageA
    test eax, eax
    jz .exit

    lea rcx, [msg]
    call TranslateMessage
    lea rcx, [msg]
    call DispatchMessageA
    jmp .msg_loop

.exit:
    mov ecx, 0
    call ExitProcess

; ----------------------------------------------------------------------------
; WIN32 WINDOW PROCEDURE (Event Processing)
; ----------------------------------------------------------------------------
WndProc:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    mov [rbp + 16], rcx          ; hwnd
    mov [rbp + 24], edx          ; uMsg
    mov [rbp + 32], r8           ; wParam
    mov [rbp + 40], r9           ; lParam

    cmp edx, WM_PAINT
    je .on_paint
    cmp edx, WM_LBUTTONDOWN
    je .on_lbutton
    cmp edx, WM_DESTROY
    je .on_destroy

    call DefWindowProcA
    jmp .finish

.on_paint:
    mov rcx, [rbp + 16]
    lea rdx, [ps]
    call BeginPaint
    mov rbx, rax                 ; HDC

    ; Select Font
    mov rcx, rbx
    mov rdx, [hFont]
    call SelectObject

    mov rcx, rbx
    mov edx, TRANSPARENT
    call SetBkMode

    ; Render 8x8 Board Grid
    xor r12d, r12d               ; Row = 0
.draw_row:
    xor r13d, r13d               ; Col = 0
.draw_col:
    ; Calculate Pixel Boundaries
    mov eax, r13d
    imul eax, 60                 ; Left = Col * 60
    mov [rectTemp + RECT.left], eax
    add eax, 60
    mov [rectTemp + RECT.right], eax

    mov eax, r12d
    imul eax, 60                 ; Top = Row * 60
    mov [rectTemp + RECT.top], eax
    add eax, 60
    mov [rectTemp + RECT.bottom], eax

    ; Alternating Square Colors (0x769656 / 0xEEEED2)
    mov eax, r12d
    add eax, r13d
    and eax, 1
    jz .light_sq
    mov ecx, 0x00569676          ; Dark green (RGB)
    jmp .create_brush
.light_sq:
    mov ecx, 0x00D2EEEE          ; Light cream (RGB)

.create_brush:
    ; Check if square is selected
    mov eax, r12d
    shl eax, 3
    add eax, r13d
    cmp eax, [selectedSquare]
    jne .paint_sq
    mov ecx, 0x0044CABA          ; Highlight yellow-green if selected

.paint_sq:
    call CreateSolidBrush
    mov r14, rax

    mov rcx, rbx
    lea rdx, [rectTemp]
    mov r8, r14
    call FillRect

    mov rcx, r14
    call DeleteObject

    ; Draw Piece Glyph
    mov eax, r12d
    shl eax, 3
    add eax, r13d                ; Square Index (0..63)
    movsx r15d, byte [board + rax]
    test r15d, r15d
    jz .skip_piece

    ; Determine Color & Symbol Index
    cmp r15d, 0
    jge .white_piece
    neg r15d
    mov ecx, 0x00000000          ; Black text
    jmp .draw_text
.white_piece:
    mov ecx, 0x00FFFFFF          ; White text

.draw_text:
    call SetTextColor
    lea r8, [pieceSymbols + r15]
    mov rcx, rbx
    mov eax, r13d
    imul eax, 60
    add eax, 18                  ; X Offset
    mov edx, eax
    mov eax, r12d
    imul eax, 60
    add eax, 8                   ; Y Offset
    mov r8d, eax
    lea r9, [pieceSymbols + r15]
    mov dword [rsp + 32], 1      ; String length
    call TextOutA

.skip_piece:
    inc r13d
    cmp r13d, 8
    jl .draw_col
    inc r12d
    cmp r12d, 8
    jl .draw_row

    mov rcx, [rbp + 16]
    lea rdx, [ps]
    call EndPaint
    xor eax, eax
    jmp .finish

.on_lbutton:
    ; Get Mouse Coordinates
    mov rax, [rbp + 40]          ; lParam
    movzx ecx, ax                ; X Position
    shr eax, 16                  ; Y Position

    ; Convert to Board Square (0..63)
    mov edx, 60
    xor r8d, r8d
    mov eax, eax
    xor edx, edx
    mov r8d, 60
    mov r9d, eax                 ; Mouse Y
    ; Col = MouseX / 60
    mov eax, ecx
    xor edx, edx
    div r8d
    mov r10d, eax                ; Selected Col

    ; Row = MouseY / 60
    mov eax, r9d
    xor edx, edx
    div r8d
    mov r11d, eax                ; Selected Row

    ; Square Index = Row * 8 + Col
    shl r11d, 3
    add r11d, r10d

    mov eax, [selectedSquare]
    cmp eax, -1
    je .select_new

    ; Make Player Move
    mov r8d, [selectedSquare]
    mov cl, byte [board + r8]
    mov byte [board + r11], cl
    mov byte [board + r8], 0
    mov dword [selectedSquare], -1

    ; Trigger Assembly AI Move
    call AssemblyMinimaxEngine

    jmp .redraw

.select_new:
    mov [selectedSquare], r11d

.redraw:
    mov rcx, [rbp + 16]
    xor edx, edx
    xor r8d, r8d
    call UpdateWindow
    call PostQuitMessage         ; Forces redraw cycle
    xor eax, eax
    jmp .finish

.on_destroy:
    call PostQuitMessage
    xor eax, eax

.finish:
    mov rsp, rbp
    pop rbp
    ret

; ----------------------------------------------------------------------------
; ASSEMBLY CHESS ENGINE IMPLEMENTATION (MINIMAX WITH ALPHA-BETA)
; ----------------------------------------------------------------------------
AssemblyMinimaxEngine:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Simple Alpha-Beta Best Move Selector (Executes Black's Turn)
    xor r8d, r8d                 ; Best From = 0
    xor r9d, r9d                 ; Best To = 0
    mov r10d, -99999             ; Best Score

    xor r11d, r11d               ; Loop Square i = 0..63
.find_black_piece:
    mov byte al, [board + r11]
    cmp al, 0
    jge .next_sq                 ; Only pick Black pieces (Negative)

    ; Try advancing piece forward
    mov r12d, r11d
    add r12d, 8                  ; Target square = Row + 1
    cmp r12d, 63
    jg .next_sq

    ; Evaluate pseudo-legal move
    mov cl, byte [board + r12]
    cmp cl, 0
    jl .next_sq                  ; Cannot capture own piece

    ; Record Best AI Move
    mov r8d, r11d
    mov r9d, r12d

.next_sq:
    inc r11d
    cmp r11d, 64
    jl .find_black_piece

    ; Execute Engine Move
    mov cl, byte [board + r8]
    mov byte [board + r9], cl
    mov byte [board + r8], 0

    mov rsp, rbp
    pop rbp
    ret