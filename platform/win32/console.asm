;; =============================================================================
;; GLYPH - Windows x86 Console Backend
;; Platform: Windows x86 | Assembler: NASM | Linker: GCC
;; =============================================================================
;; Renders the framebuffer to Windows Console using WriteConsoleOutputA.
;; =============================================================================

bits 32

;; Imports - Windows API
extern _WriteConsoleOutputA@20
extern _SetConsoleCursorPosition@8
extern _SetConsoleScreenBufferSize@8

;; Imports - Core
extern _front_buffer

;; Imports - Platform
extern _stdout_handle

;; Exports
global _console_init
global _console_render
global _console_shutdown

section .data
    ;; COORD structures (packed as DWORD: Y << 16 | X)
    buffer_size     dd (25 << 16) | 80      ; 80x25
    buffer_coord    dd 0                     ; 0,0
    
    ;; SMALL_RECT: Left, Top, Right, Bottom (packed)
    write_region    dw 0, 0, 79, 24

section .bss
    char_info_buffer    resb 80 * 25 * 4    ; CHAR_INFO array

section .text

;; =============================================================================
;; _console_init - Initialize console
;; =============================================================================
_console_init:
    push ebp
    mov ebp, esp
    push ebx
    push edi

    ;; Set console buffer size
    push dword [buffer_size]
    push dword [_stdout_handle]
    call _SetConsoleScreenBufferSize@8

    ;; Move cursor to top-left
    push 0                          ; COORD 0,0
    push dword [_stdout_handle]
    call _SetConsoleCursorPosition@8

    ;; Clear CHAR_INFO buffer
    mov edi, char_info_buffer
    mov ecx, 80 * 25
.clear_loop:
    mov word [edi], ' '             ; ASCII space
    mov word [edi + 2], 0x07        ; Light gray on black
    add edi, 4
    dec ecx
    jnz .clear_loop

    pop edi
    pop ebx
    pop ebp
    ret

;; =============================================================================
;; _console_render - Render front buffer to console
;; =============================================================================
_console_render:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ;; Convert Cell buffer to CHAR_INFO buffer
    mov esi, _front_buffer
    mov edi, char_info_buffer
    mov ecx, 80 * 25

.convert_loop:
    ;; Read Cell: glyph(0), fg(1), bg(2), flags(3)
    movzx eax, byte [esi]           ; glyph
    movzx ebx, byte [esi + 1]       ; fg
    movzx edx, byte [esi + 2]       ; bg

    ;; Write CHAR_INFO: char(2 bytes), attributes(2 bytes)
    mov word [edi], ax              ; character
    shl edx, 4                      ; bg << 4
    or ebx, edx                     ; (bg << 4) | fg
    mov word [edi + 2], bx          ; attributes

    add esi, 4
    add edi, 4
    dec ecx
    jnz .convert_loop

    ;; WriteConsoleOutputA(handle, buffer, size, coord, &region)
    push write_region
    push dword [buffer_coord]
    push dword [buffer_size]
    push char_info_buffer
    push dword [_stdout_handle]
    call _WriteConsoleOutputA@20

    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

;; =============================================================================
;; _console_shutdown - Cleanup
;; =============================================================================
_console_shutdown:
    ret
