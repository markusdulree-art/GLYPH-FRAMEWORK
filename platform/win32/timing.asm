;; =============================================================================
;; GLYPH - Windows x86 Timing Backend
;; Platform: Windows x86 | Assembler: NASM | Linker: GCC
;; =============================================================================
;; High-resolution timing using QueryPerformanceCounter.
;; Returns 64-bit values but we work with 32-bit portions.
;; =============================================================================

bits 32

;; Imports - Windows API
extern _QueryPerformanceCounter@4
extern _QueryPerformanceFrequency@4

;; Exports
global _platform_get_time_us
global _platform_timing_init

section .bss
    perf_frequency  resq 1      ; 64-bit frequency
    perf_counter    resq 1      ; 64-bit counter
    start_time      resq 1      ; 64-bit start time

section .text

;; =============================================================================
;; _platform_timing_init - Initialize timing system
;; =============================================================================
_platform_timing_init:
    push ebp
    mov ebp, esp

    ;; Get frequency
    push perf_frequency
    call _QueryPerformanceFrequency@4

    ;; Get starting counter
    push start_time
    call _QueryPerformanceCounter@4

    pop ebp
    ret

;; =============================================================================
;; _platform_get_time_us - Get time in microseconds since start
;; Returns: EAX = microseconds (lower 32 bits)
;; =============================================================================
_platform_get_time_us:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ;; Check if initialized
    mov eax, [perf_frequency]
    or eax, [perf_frequency + 4]
    jnz .initialized
    call _platform_timing_init

.initialized:
    ;; Get current counter
    push perf_counter
    call _QueryPerformanceCounter@4

    ;; Calculate delta (64-bit subtraction)
    mov eax, [perf_counter]
    mov edx, [perf_counter + 4]
    sub eax, [start_time]
    sbb edx, [start_time + 4]

    ;; delta is now in EDX:EAX
    ;; We need (delta * 1000000) / frequency
    ;; For simplicity, use 32-bit math (works for ~70 minutes)

    ;; Multiply by 1000000 (this may overflow for large deltas)
    mov ecx, 1000000
    mul ecx                     ; EDX:EAX = delta_low * 1000000

    ;; Divide by frequency (use low 32 bits of frequency)
    mov ecx, [perf_frequency]
    test ecx, ecx
    jz .zero_freq
    div ecx                     ; EAX = quotient

    jmp .done

.zero_freq:
    xor eax, eax

.done:
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret
