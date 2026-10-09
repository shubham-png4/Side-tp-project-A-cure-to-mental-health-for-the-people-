; =====================================================================
; x86_64 Assembly Guessing Game (Linux System Calls)
; Syntax: NASM
; =====================================================================

section .data
    msg_title db "=== Guess the Number Game (Assembly) ===", 10, 0
    len_title equ $ - msg_title

    msg_prompt db "Guess a digit between 0 and 9: ", 0
    len_prompt equ $ - msg_prompt

    msg_high   db "Too high! Try again.", 10, 0
    len_high   equ $ - msg_high

    msg_low    db "Too low! Try again.", 10, 0
    len_low    equ $ - msg_low

    msg_win    db 10, "🎉 Correct! You guessed the right digit!", 10, 0
    len_win    equ $ - msg_win

    secret_digit db '7'         ; Target digit character ('7')

section .bss
    user_input resb 2           ; Buffer for input char + newline

section .text
    global _start

_start:
    ; Print Title
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, msg_title
    mov rdx, len_title
    syscall

prompt_loop:
    ; Print Prompt
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, msg_prompt
    mov rdx, len_prompt
    syscall

    ; Read User Input (stdin)
    mov rax, 0                  ; sys_read
    mov rdi, 0                  ; stdin
    mov rsi, user_input
    mov rdx, 2                  ; Read char + newline
    syscall

    ; Compare input character with secret_digit
    mov al, [user_input]
    mov bl, [secret_digit]

    cmp al, bl
    je  win_game
    jl  too_low
    jg  too_high

too_low:
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, msg_low
    mov rdx, len_low
    syscall
    jmp prompt_loop

too_high:
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, msg_high
    mov rdx, len_high
    syscall
    jmp prompt_loop

win_game:
    ; Print Win Message
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, msg_win
    mov rdx, len_win
    syscall

    ; Exit Program (sys_exit)
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; exit code 0
    syscall