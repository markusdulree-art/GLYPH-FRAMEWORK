;; GLYPH - Windows Timing Backend
bits 64
default rel

extern QueryPerformanceCounter
extern QueryPerformanceFrequency

global platform_get_time_us
global platform_timing_init

section .bss
    perf_frequency  resq 1
    perf_counter    resq 1
    start_time      resq 1

section .text

platform_timing_init:
    sub rsp, 40
    lea rcx, [perf_frequency]
    call QueryPerformanceFrequency
    lea rcx, [start_time]
    call QueryPerformanceCounter
    add rsp, 40
    ret

platform_get_time_us:
    push rbx
    push r12
    sub rsp, 40
    
    lea rax, [perf_frequency]
    mov rax, [rax]
    test rax, rax
    jnz .init_done
    call platform_timing_init
.init_done:
    lea rcx, [perf_counter]
    call QueryPerformanceCounter
    
    lea rax, [perf_counter]
    mov rax, [rax]
    lea rbx, [start_time]
    sub rax, [rbx]
    
    mov rcx, 1000000
    imul rcx
    
    lea rbx, [perf_frequency]
    mov rbx, [rbx]
    idiv rbx
    
    add rsp, 40
    pop r12
    pop rbx
    ret
