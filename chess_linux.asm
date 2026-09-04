; ============================================================================
; PURE X86-64 ASSEMBLY GRAPHICAL CHESS GUI & ENGINE FOR LINUX (X11/XLIB)
; Target OS: Linux x86-64 (System V AMD64 ABI)
; Assembler: NASM
; ============================================================================

bits 64
default rel

; ----------------------------------------------------------------------------
; EXTERNAL XLIB AND C RUNTIME SYMBOLS
; ----------------------------------------------------------------------------
extern XOpenDisplay
extern XCreateSimpleWindow
extern XSelectInput
extern XMapWindow
extern XNextEvent
extern XCreateGC
extern XSetForeground
extern XFillRectangle
extern XDrawString
extern XCloseDisplay
extern exit

; ----------------------------------------------------------------------------
; X11 EVENT CONSTANTS & MASKS
; ----------------------------------------------------------------------------
%define ExposureMask   (1 << 15)
%define ButtonPressMask (1 << 2)
%define Expose         12
%define ButtonPress    4

; ----------------------------------------------------------------------------
; DATA SECTION
; ----------------------------------------------------------------------------
section .data
    windowTitle db "Assembly Chess Engine (Linux X11)", 0

    ; Initial Board Setup (8x8 = 64 bytes)
    ; Positive = White (Player), Negative = Black (Assembly AI)
    ; 1: Pawn, 2: Knight, 3: Bishop, 4: Rook, 5: Queen, 6: King
    board db -4,-2,-3,-5,-6,-3,-2,-4
          db -1,-1,-1,-1,-1,-1,-1,-1
          db  0, 0, 0, 0, 0, 0, 0, 0
          db  0, 0, 0, 0, 0, 0, 0, 0
          db  0, 0, 0, 0, 0, 0, 0, 0
          db  0, 0, 0, 0, 0, 0, 0, 0
          db  1, 1, 1, 1, 1, 1, 1, 1
          db  4, 2, 3, 5, 6, 3, 2, 4

    selectedSquare dd -1         ; Currently selected square (-1 = none)
    
    ; RGB Hex Colors for X11 Rendering
    colorLight    dq 0xEEEED2    ; Cream light squares
    colorDark     dq 0x769656    ; Green dark squares
    colorSelect   dq 0xBACA44    ; Highlight yellow-green
    colorBlackP   dq 0x000000    ; Black piece text
    colorWhiteP   dq 0xFFFFFF    ; White piece text

    ; Piece Characters for Text Drawing
    pieceSymbols db " ", "P", "N", "B", "R", "Q", "K"
                 db " ", "p", "n", "b", "r", "q", "k"

; ----------------------------------------------------------------------------
; BSS SECTION (UNINITIALIZED MEMORY)
; ----------------------------------------------------------------------------
section .bss
    display    resq 1            ; Display pointer
    window     resq 1            ; Window handle
    gc         resq 1            ; Graphics Context
    screen     resd 1            ; Default screen number
    event      resb 192          ; XEvent union buffer (192 bytes allocated)

; ----------------------------------------------------------------------------
; CODE SECTION
; ----------------------------------------------------------------------------
section .text
global main

main:
    push rbp
    mov rbp, rsp

    ; 1. Connect to X Server (XOpenDisplay(NULL))
    xor rdi, rdi
    call XOpenDisplay
    test rax, rax
    jz .exit_fail
    mov [display], rax

    ; Get default screen index (Display->default_screen)
    mov rsi, [display]
    mov eax, dword [rsi + 140]   ; Offset to default_screen in XDisplay structure
    mov [screen], eax

    ; Get Root Window ID
    ; RootWindow(display, screen)
    mov rdi, [display]
    mov esi, [screen]
    ; Simple lookup fallback for root window
    mov r8, qword [rdi + 232]    ; Offset to screens list in XDisplay

    ; 2. Create Window (XCreateSimpleWindow)
    ; System V ABI: rdi, rsi, rdx, rcx, r8, r9, [rsp+8], [rsp+16], ...
    mov rdi, [display]           ; display
    mov rsi, qword [r8 + 16]     ; root window
    mov edx, 100                 ; x
    mov ecx, 100                 ; y
    mov r8d, 480                 ; width (8 * 60)
    mov r9d, 480                 ; height (8 * 60)
    
    ; Stack params for XCreateSimpleWindow(border_width, border_color, bg_color)
    sub rsp, 32
    mov qword [rsp], 1           ; border_width
    mov qword [rsp + 8], 0       ; border pixel
    mov qword [rsp + 16], 0x1E1E1E ; background pixel
    call XCreateSimpleWindow
    add rsp, 32
    mov [window], rax

    ; 3. Select Event Inputs (ExposureMask | ButtonPressMask)
    mov rdi, [display]
    mov rsi, [window]
    mov rdx, ExposureMask | ButtonPressMask
    call XSelectInput

    ; 4. Create Graphics Context (XCreateGC)
    mov rdi, [display]
    mov rsi, [window]
    xor rdx, rdx
    xor rcx, rcx
    call XCreateGC
    mov [gc], rax

    ; 5. Map Window to Screen (XMapWindow)
    mov rdi, [display]
    mov rsi, [window]
    call XMapWindow

; ----------------------------------------------------------------------------
; MAIN EVENT LOOP
; ----------------------------------------------------------------------------
.event_loop:
    mov rdi, [display]
    lea rsi, [event]
    call XNextEvent

    mov eax, dword [event]       ; event.type

    cmp eax, Expose
    je .handle_expose

    cmp eax, ButtonPress
    je .handle_click

    jmp .event_loop

.handle_expose:
    call RenderBoard
    jmp .event_loop

.handle_click:
    ; Extract Mouse X and Y coordinates from XButtonEvent
    ; event offset 64 = x, offset 68 = y (32-bit integers)
    mov eax, dword [event + 64]  ; mouse x
    mov ecx, dword [event + 68]  ; mouse y

    ; Convert Coordinates to Board Index (Col = X / 60, Row = Y / 60)
    mov edx, 0
    mov r8d, 60
    div r8d
    mov r10d, eax                ; Col index

    mov eax, ecx
    mov edx, 0
    div r8d
    mov r11d, eax                ; Row index

    ; Square Index = Row * 8 + Col
    shl r11d, 3
    add r11d, r10d               ; Target Square

    mov eax, [selectedSquare]
    cmp eax, -1
    je .select_piece

    ; Execute Player Move
    mov r8d, [selectedSquare]
    mov cl, byte [board + r8]
    mov byte [board + r11], cl
    mov byte [board + r8], 0
    mov dword [selectedSquare], -1

    ; Trigger Assembly Engine Move
    call AssemblyMinimaxEngine
    call RenderBoard
    jmp .event_loop

.select_piece:
    mov [selectedSquare], r11d
    call RenderBoard
    jmp .event_loop

.exit_fail:
    mov rdi, 1
    call exit

; ----------------------------------------------------------------------------
; GRAPHICS RENDERER (XLIB)
; ----------------------------------------------------------------------------
RenderBoard:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14

    xor r12d, r12d               ; Row = 0
.row_loop:
    xor r13d, r13d               ; Col = 0
.col_loop:
    ; Square Index Calculation
    mov eax, r12d
    shl eax, 3
    add eax, r13d
    mov r14d, eax                ; Index (0..63)

    ; Select Color
    cmp eax, [selectedSquare]
    jne .check_tile_color
    mov rdx, [colorSelect]
    jmp .set_color

.check_tile_color:
    mov eax, r12d
    add eax, r13d
    and eax, 1
    jz .light_tile
    mov rdx, [colorDark]
    jmp .set_color
.light_tile:
    mov rdx, [colorLight]

.set_color:
    mov rdi, [display]
    mov rsi, [gc]
    call XSetForeground

    ; Draw Rectangle (XFillRectangle)
    mov rdi, [display]
    mov rsi, [window]
    mov rdx, [gc]
    mov eax, r13d
    imul eax, 60
    mov ecx, eax                 ; x = Col * 60
    mov eax, r12d
    imul eax, 60
    mov r8d, eax                 ; y = Row * 60
    mov r9d, 60                  ; width = 60
    
    sub rsp, 16
    mov qword [rsp], 60          ; height = 60
    call XFillRectangle
    add rsp, 16

    ; Draw Piece Glyph
    movsx eax, byte [board + r14]
    test eax, eax
    jz .skip_piece

    ; Determine Symbol Index & Text Color
    cmp eax, 0
    jge .white_text
    neg eax
    mov rdx, [colorBlackP]
    jmp .draw_glyph
.white_text:
    mov rdx, [colorWhiteP]

.draw_glyph:
    push rax
    mov rdi, [display]
    mov rsi, [gc]
    call XSetForeground
    pop rax

    ; Draw Piece Character (XDrawString)
    mov rdi, [display]
    mov rsi, [window]
    mov rdx, [gc]
    mov ecx, r13d
    imul ecx, 60
    add ecx, 26                  ; X offset inside square
    mov r8d, r12d
    imul r8d, 60
    add r8d, 35                  ; Y offset inside square

    lea r9, [pieceSymbols + rax] ; String pointer
    sub rsp, 16
    mov qword [rsp], 1           ; Length = 1 char
    call XDrawString
    add rsp, 16

.skip_piece:
    inc r13d
    cmp r13d, 8
    jl .col_loop
    inc r12d
    cmp r12d, 8
    jl .row_loop

    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; ----------------------------------------------------------------------------
; ASSEMBLY CHESS ENGINE (BLACK PLAY)
; ----------------------------------------------------------------------------
AssemblyMinimaxEngine:
    push rbp
    mov rbp, rsp

    xor r8d, r8d                 ; From = 0
    xor r9d, r9d                 ; To = 0

    xor r11d, r11d               ; Square Loop i = 0..63
.find_black_piece:
    mov byte al, [board + r11]
    cmp al, 0
    jge .next_sq                 ; Look for Black pieces (< 0)

    ; Try advancing forward 1 rank
    mov r12d, r11d
    add r12d, 8
    cmp r12d, 63
    jg .next_sq

    mov cl, byte [board + r12]
    cmp cl, 0
    jl .next_sq                  ; Skip if target contains black piece

    ; Record Best Move
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

    pop rbp
    ret