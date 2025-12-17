;; =============================================================================
;; GLYPH - Core Timing Module (32-bit)
;; Platform: Windows x86 | Assembler: NASM | Linker: GCC
;; =============================================================================

bits 32

DEFAULT_DT_US   equ 16666
MAX_FRAME_TIME  equ 250000

;; Imports
extern _platform_get_time_us

;; Exports
global _timing_init
global _timing_set_dt
global _timing_get_dt
global _timing_update
global _timing_should_update
global _timing_frame_start
global _timing_get_fps

section .bss
    fixed_dt_us     resd 1
    accumulator_us  resd 1
    last_time_us    resd 1
    frame_count     resd 1
    fps             resd 1
    fps_timer_us    resd 1
    fps_frame_count resd 1

section .text

;; =============================================================================
;; _timing_init
;; =============================================================================
_timing_init:
    push ebp
    mov ebp, esp

    mov dword [fixed_dt_us], DEFAULT_DT_US
    mov dword [accumulator_us], 0
    mov dword [frame_count], 0
    mov dword [fps], 0
    mov dword [fps_timer_us], 0
    mov dword [fps_frame_count], 0

    call _platform_get_time_us
    mov [last_time_us], eax
    mov [fps_timer_us], eax

    pop ebp
    ret

;; =============================================================================
;; _timing_set_dt - Set fixed timestep
;; Args: [ebp+8]=dt_us
;; =============================================================================
_timing_set_dt:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]
    mov [fixed_dt_us], eax
    pop ebp
    ret

;; =============================================================================
;; _timing_get_dt
;; Returns: EAX=dt_us
;; =============================================================================
_timing_get_dt:
    mov eax, [fixed_dt_us]
    ret

;; =============================================================================
;; _timing_frame_start - Called at frame start
;; =============================================================================
_timing_frame_start:
    push ebp
    mov ebp, esp
    push ebx
    push esi

    call _platform_get_time_us
    mov esi, eax                ; current_time

    ;; Calculate delta
    mov ebx, [last_time_us]
    sub eax, ebx                ; delta

    ;; Cap delta
    cmp eax, MAX_FRAME_TIME
    jbe .no_cap
    mov eax, MAX_FRAME_TIME
.no_cap:

    ;; Add to accumulator
    add [accumulator_us], eax

    ;; Update last time
    mov [last_time_us], esi

    ;; Update FPS counter
    inc dword [fps_frame_count]

    ;; Check if 1 second passed
    mov eax, esi
    sub eax, [fps_timer_us]
    cmp eax, 1000000
    jb .no_fps_update

    mov eax, [fps_frame_count]
    mov [fps], eax
    mov dword [fps_frame_count], 0
    mov [fps_timer_us], esi

.no_fps_update:
    pop esi
    pop ebx
    pop ebp
    ret

;; =============================================================================
;; _timing_should_update
;; Returns: EAX=0/1
;; =============================================================================
_timing_should_update:
    mov eax, [accumulator_us]
    cmp eax, [fixed_dt_us]
    jb .no_update
    mov eax, 1
    ret
.no_update:
    xor eax, eax
    ret

;; =============================================================================
;; _timing_update - Consume one timestep
;; =============================================================================
_timing_update:
    mov eax, [fixed_dt_us]
    sub [accumulator_us], eax
    inc dword [frame_count]
    ret

;; =============================================================================
;; _timing_get_fps
;; Returns: EAX=fps
;; =============================================================================
_timing_get_fps:
    mov eax, [fps]
    ret
