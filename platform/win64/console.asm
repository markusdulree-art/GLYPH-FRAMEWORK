;; GLYPH - Windows Console Backend
bits 64
default rel

extern WriteConsoleOutputA
extern SetConsoleCursorPosition
extern SetConsoleScreenBufferSize

extern front_buffer
extern stdout_handle

global console_init
global console_render
global console_shutdown

section .data
    buffer_size     dw 80, 25
    buffer_coord    dw 0, 0
    write_region    dw 0, 0, 79, 24

section .bss
    char_info_buffer    resb 80 * 25 * 4

section .text

console_init:
    push rbx
    push rdi
    sub rsp, 40
    
    lea rbx, [stdout_handle]
    mov rcx, [rbx]
    lea rax, [buffer_size]
    movzx edx, word [rax]
    movzx eax, word [rax + 2]
    shl eax, 16
    or edx, eax
    call SetConsoleScreenBufferSize
    
    lea rbx, [stdout_handle]
    mov rcx, [rbx]
    xor edx, edx
    call SetConsoleCursorPosition
    
    lea rdi, [char_info_buffer]
    mov rcx, 80 * 25
.clear_loop:
    mov word [rdi], ' '
    mov word [rdi + 2], 0x07
    add rdi, 4
    dec rcx
    jnz .clear_loop
    
    add rsp, 40
    pop rdi
    pop rbx
    ret

console_render:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 56
    
    lea rsi, [front_buffer]
    lea rdi, [char_info_buffer]
    mov rcx, 80 * 25
    
.convert_loop:
    movzx eax, byte [rsi]
    movzx r8d, byte [rsi + 1]
    movzx r9d, byte [rsi + 2]
    
    mov word [rdi], ax
    shl r9d, 4
    or r8d, r9d
    mov word [rdi + 2], r8w
    
    add rsi, 4
    add rdi, 4
    dec rcx
    jnz .convert_loop
    
    lea rbx, [stdout_handle]
    mov rcx, [rbx]
    lea rdx, [char_info_buffer]
    mov r8d, (25 << 16) | 80
    xor r9d, r9d
    
    lea rax, [write_region]
    mov [rsp + 32], rax
    
    call WriteConsoleOutputA
    
    add rsp, 56
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

console_shutdown:
    ret
