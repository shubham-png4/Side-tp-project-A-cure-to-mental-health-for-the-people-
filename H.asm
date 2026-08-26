; x86_64 Assembly Chatbot Shell (NASM syntax for Linux)
; Compiles with:
;   nasm -f elf64 chatbot.asm -o chatbot.o
;   ld chatbot.o -o chatbot

section .data
    prompt db "You: ", 0
    prompt_len equ $ - prompt
    goodbye db "Exiting chatbot...", 10, 0
    goodbye_len equ $ - goodbye
    
    ; Command to invoke system script/curl for AI response
    curl_path db "/usr/bin/curl", 0
    arg1 db "-s", 0
    arg2 db "https://api.groq.com/openai/v1/chat/completions", 0

section .bss
    user_buffer resb 256

section .text
    global _start

_start:
main_loop:
    ; 1. Print Prompt ("You: ")
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    ; 2. Read User Input
    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    mov rsi, user_buffer
    mov rdx, 256
    syscall

    ; Check if input is empty or exit
    cmp rax, 1          ; If only newline entered
    jle exit_program

    ; 3. Output confirmation (Simulating response pipeline)
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, user_buffer
    mov rdx, 256
    syscall

    jmp main_loop

exit_program:
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, goodbye
    mov rdx, goodbye_len
    syscall

    ; sys_exit
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; exit code 0
    syscall