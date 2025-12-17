;; =============================================================================
;; GLYPH - Core Timing Module
;; =============================================================================
;; Fixed timestep implementation. Platform-agnostic.
;; =============================================================================

bits 64
default rel

DEFAULT_DT_US   equ 16666
MAX_FRAME_TIME  equ 250000

global timing_init
global timing_set_dt
global timing_get_dt
global timing_update
global timing_should_update
global timing_frame_start
global timing_get_fps

global fixed_dt_us
global accumulator_us
global last_time_us
global frame_count
global fps

extern platform_get_time_us

section .bss
    fixed_dt_us     resq 1
    accumulator_us  resq 1
    last_time_us    resq 1
    frame_count     resq 1
    fps             resq 1
    fps_timer_us    resq 1
    fps_frame_count resq 1

section .text

timing_init:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    
    ; Get addresses of all variables
    lea r12, [fixed_dt_us]
    lea r13, [accumulator_us]
    lea r14, [frame_count]
    lea r15, [fps]
    
    mov qword [r12], DEFAULT_DT_US
    mov qword [r13], 0
    mov qword [r14], 0
    mov qword [r15], 0
    
    lea rax, [fps_timer_us]
    mov qword [rax], 0
    lea rax, [fps_frame_count]
    mov qword [rax], 0
    
    call platform_get_time_us
    lea rbx, [last_time_us]
    mov [rbx], rax
    lea rbx, [fps_timer_us]
    mov [rbx], rax
    
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

timing_set_dt:
    lea rax, [fixed_dt_us]
    mov [rax], rcx
    ret

timing_get_dt:
    lea rax, [fixed_dt_us]
    mov rax, [rax]
    ret

timing_frame_start:
    push rbx
    push r12
    push r13
    sub rsp, 40
    
    call platform_get_time_us
    mov r12, rax
    
    lea rbx, [last_time_us]
    mov r13, [rbx]
    sub rax, r13
    
    cmp rax, MAX_FRAME_TIME
    jbe .no_cap
    mov rax, MAX_FRAME_TIME
.no_cap:
    
    lea rbx, [accumulator_us]
    add [rbx], rax
    
    lea rbx, [last_time_us]
    mov [rbx], r12
    
    lea rbx, [fps_frame_count]
    inc qword [rbx]
    
    mov rax, r12
    lea rbx, [fps_timer_us]
    sub rax, [rbx]
    cmp rax, 1000000
    jb .no_fps_update
    
    lea rax, [fps_frame_count]
    mov rax, [rax]
    lea rbx, [fps]
    mov [rbx], rax
    lea rbx, [fps_frame_count]
    mov qword [rbx], 0
    lea rbx, [fps_timer_us]
    mov [rbx], r12
    
.no_fps_update:
    add rsp, 40
    pop r13
    pop r12
    pop rbx
    ret

timing_should_update:
    lea rax, [accumulator_us]
    mov rax, [rax]
    lea rdx, [fixed_dt_us]
    cmp rax, [rdx]
    jb .no_update
    mov eax, 1
    ret
.no_update:
    xor eax, eax
    ret

timing_update:
    lea rax, [fixed_dt_us]
    mov rax, [rax]
    lea rdx, [accumulator_us]
    sub [rdx], rax
    lea rdx, [frame_count]
    inc qword [rdx]
    ret

timing_get_fps:
    lea rax, [fps]
    mov rax, [rax]
    ret
