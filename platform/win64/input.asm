;; GLYPH - Windows Input Backend
;; Windows x64, NASM, GCC
bits 64
default rel

INPUT_RECORD_SIZE equ 20

extern PeekConsoleInputA
extern ReadConsoleInputA
extern GetNumberOfConsoleInputEvents
extern GetAsyncKeyState

extern stdin_handle
extern input_set_key_state

global console_poll_input

section .bss
    input_record    resb INPUT_RECORD_SIZE * 16
    events_read     resd 1
    num_events      resd 1

section .text

console_poll_input:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    
    ; Arrow keys
    mov ecx, 0x25
    call poll_key
    mov ecx, 0x26
    call poll_key
    mov ecx, 0x27
    call poll_key
    mov ecx, 0x28
    call poll_key
    
    ; WASD
    mov ecx, 0x57
    call poll_key
    mov ecx, 0x41
    call poll_key
    mov ecx, 0x53
    call poll_key
    mov ecx, 0x44
    call poll_key
    
    ; Common keys
    mov ecx, 0x20
    call poll_key
    mov ecx, 0x0D
    call poll_key
    mov ecx, 0x1B
    call poll_key
    mov ecx, 0x08
    call poll_key
    
    ; Number keys 0-9
    mov r12d, 0x30
.num_loop:
    mov ecx, r12d
    call poll_key
    inc r12d
    cmp r12d, 0x3A
    jb .num_loop
    
    ; Letter keys A-Z
    mov r12d, 0x41
.letter_loop:
    mov ecx, r12d
    call poll_key
    inc r12d
    cmp r12d, 0x5B
    jb .letter_loop
    
    call flush_console_input
    
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

;; poll_key - Check a single key using GetAsyncKeyState
;; Args: ecx = virtual key code
poll_key:
    push rbx
    push r12
    sub rsp, 40
    
    ; Save key code in non-volatile register
    mov r12d, ecx
    
    ; GetAsyncKeyState(vKey)
    ; rcx already has key code
    call GetAsyncKeyState
    
    ; High bit set = key is currently down
    test ax, 0x8000
    mov edx, 0
    jz .set_state
    mov edx, 1
    
.set_state:
    mov ecx, r12d
    call input_set_key_state
    
    add rsp, 40
    pop r12
    pop rbx
    ret

;; flush_console_input - Flush pending console input events
flush_console_input:
    push rbx
    push r12
    sub rsp, 40
    
.flush_loop:
    lea rbx, [stdin_handle]
    mov rcx, [rbx]
    lea rdx, [num_events]
    call GetNumberOfConsoleInputEvents
    
    lea rax, [num_events]
    cmp dword [rax], 0
    je .done
    
    lea rbx, [stdin_handle]
    mov rcx, [rbx]
    lea rdx, [input_record]
    mov r8d, 16
    lea r9, [events_read]
    call ReadConsoleInputA
    
    lea rax, [events_read]
    cmp dword [rax], 16
    jae .flush_loop
    
.done:
    add rsp, 40
    pop r12
    pop rbx
    ret
