section .data
    msg_start db "=== Assembly Guessing Game ===", 10, "Guess a digit between 0 and 9: ", 0
    len_start equ $ - msg_start
    
    msg_win   db 10, "Correct! You win!", 10, 0
    len_win   equ $ - msg_win

    msg_wrong db "Wrong! Try again: ", 0
    len_wrong equ $ - msg_wrong

    secret_digit db '7'

section .bss
    user_input resb 2

section .text
    global _start

_start:
    ; Print start message
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, msg_start
    mov rdx, len_start
    syscall

read_loop:
    ; Read user input
    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    mov rsi, user_input
    mov rdx, 2
    syscall

    ; Compare input character with secret digit ('7')
    mov al, [user_input]
    cmp al, [secret_digit]
    je win

    ; Print wrong message
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, msg_wrong
    mov rdx, len_wrong
    syscall

    jmp read_loop

win:
    ; Print win message
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, msg_win
    mov rdx, len_win
    syscall

    ; sys_exit
    mov rax, 60         ; exit
    xor rdi, rdi        ; status 0
    syscall