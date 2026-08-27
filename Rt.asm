; =====================================================================
; 64-bit x86 Linux Terminal Pong Game Engine
; Syntax: NASM
; System Calls: sys_write (1), sys_nanosleep (35), sys_exit (60)
; =====================================================================

section .data
    clear_scr   db 0x1B, "[2J", 0x1B, "[H"  ; ANSI clear screen + Home
    clear_len   equ $ - clear_scr

    newline     db 10
    space       db " "
    wall_char   db "#"
    ball_char   db "O"
    paddle_char db "|"
    
    ; Board Dimensions
    WIDTH       db 40
    HEIGHT      db 15

    ; Frame Rate Timing (nanosleep struct: 0 sec, 80,000,000 ns = 80ms delay)
    timespec:
        tv_sec  dq 0
        tv_nsec dq 80000000

section .bss
    ball_x      resb 1
    ball_y      resb 1
    dir_x       resb 1   ; 1 = right, 255 (-1) = left
    dir_y       resb 1   ; 1 = down, 255 (-1) = up
    paddle_y    resb 1

section .text
    global _start

_start:
    ; Initialize Game State
    mov byte [ball_x], 20
    mov byte [ball_y], 7
    mov byte [dir_x], 1
    mov byte [dir_y], 1
    mov byte [paddle_y], 6

game_loop:
    ; 1. Clear Screen
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, clear_scr
    mov rdx, clear_len
    syscall

    ; 2. Render Board (Nested Row/Col Loop)
    mov r8b, 0          ; r8b = Current Row (y)

row_loop:
    cmp r8b, [HEIGHT]
    jge render_done

    mov r9b, 0          ; r9b = Current Col (x)

col_loop:
    cmp r9b, [WIDTH]
    jge row_done

    ; Check if top/bottom border
    cmp r8b, 0
    je print_wall
    mov al, [HEIGHT]
    dec al
    cmp r8b, al
    je print_wall

    ; Check if Left Wall
    cmp r9b, 0
    je print_wall

    ; Check if Right Paddle (Col = WIDTH - 2)
    mov al, [WIDTH]
    sub al, 2
    cmp r9b, al
    jne check_ball

    ; Render 3-character high Paddle
    mov al, [paddle_y]
    cmp r8b, al
    jl print_space
    add al, 2
    cmp r8b, al
    jg print_space
    jmp print_paddle

check_ball:
    ; Check Ball Position (x, y)
    cmp r9b, [ball_x]
    jne print_space
    cmp r8b, [ball_y]
    jne print_space
    jmp print_ball

print_wall:
    mov rsi, wall_char
    jmp draw_char
print_paddle:
    mov rsi, paddle_char
    jmp draw_char
print_ball:
    mov rsi, ball_char
    jmp draw_char
print_space:
    mov rsi, space

draw_char:
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rdx, 1
    syscall

    inc r9b             ; Next column
    jmp col_loop

row_done:
    ; Print newline at end of row
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    inc r8b             ; Next row
    jmp row_loop

render_done:
    ; 3. Update Physics & Collision Logic
    ; Update Ball X
    mov al, [ball_x]
    add al, [dir_x]
    mov [ball_x], al

    ; Update Ball Y
    mov al, [ball_y]
    add al, [dir_y]
    mov [ball_y], al

    ; Bounce Top Wall (y <= 1)
    cmp byte [ball_y], 1
    jle bounce_y

    ; Bounce Bottom Wall (y >= HEIGHT - 2)
    mov al, [HEIGHT]
    sub al, 2
    cmp [ball_y], al
    jge bounce_y
    jmp check_x_bounce

bounce_y:
    neg byte [dir_y]    ; Reverse vertical direction

check_x_bounce:
    ; Bounce Left Wall (x <= 1)
    cmp byte [ball_x], 1
    jle bounce_x

    ; Bounce Right Paddle / Wall (x >= WIDTH - 3)
    mov al, [WIDTH]
    sub al, 3
    cmp [ball_x], al
    jge bounce_x
    jmp move_paddle_ai

bounce_x:
    neg byte [dir_x]    ; Reverse horizontal direction

move_paddle_ai:
    ; Simple AI: Paddle tracks ball Y position
    mov al, [ball_y]
    dec al
    mov [paddle_y], al

    ; 4. Frame Delay (sys_nanosleep)
    mov rax, 35         ; sys_nanosleep
    mov rdi, timespec
    mov rsi, 0
    syscall

    jmp game_loop       ; Infinite loop

exit_game:
    mov rax, 60         ; sys_exit
    xor rdi, rdi
    syscall