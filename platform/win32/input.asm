;; =============================================================================
;; GLYPH - Windows x86 Input Backend
;; Platform: Windows x86 | Assembler: NASM | Linker: GCC
;; =============================================================================
;; Polls keyboard using GetAsyncKeyState.
;; =============================================================================

bits 32

;; Imports - Windows API
extern _GetAsyncKeyState@4
extern _ReadConsoleInputA@16
extern _GetNumberOfConsoleInputEvents@8

;; Imports - Platform
extern _stdin_handle

;; Imports - Core
extern _input_set_key_state

;; Exports
global _console_poll_input

section .bss
    input_record    resb 20 * 16    ; INPUT_RECORD buffer
    events_read     resd 1
    num_events      resd 1

section .text

;; =============================================================================
;; _console_poll_input - Poll keyboard state
;; =============================================================================
_console_poll_input:
    push ebp
    mov ebp, esp
    push ebx
    push esi

    ;; Poll arrow keys
    mov eax, 0x25
    call .poll_key
    mov eax, 0x26
    call .poll_key
    mov eax, 0x27
    call .poll_key
    mov eax, 0x28
    call .poll_key

    ;; Poll WASD
    mov eax, 0x57
    call .poll_key
    mov eax, 0x41
    call .poll_key
    mov eax, 0x53
    call .poll_key
    mov eax, 0x44
    call .poll_key

    ;; Poll common keys
    mov eax, 0x20               ; Space
    call .poll_key
    mov eax, 0x0D               ; Enter
    call .poll_key
    mov eax, 0x1B               ; Escape
    call .poll_key
    mov eax, 0x08               ; Backspace
    call .poll_key

    ;; Poll number keys 0-9
    mov esi, 0x30
.num_loop:
    mov eax, esi
    call .poll_key
    inc esi
    cmp esi, 0x3A
    jb .num_loop

    ;; Poll letter keys A-Z
    mov esi, 0x41
.letter_loop:
    mov eax, esi
    call .poll_key
    inc esi
    cmp esi, 0x5B
    jb .letter_loop

    ;; Flush console input buffer
    call .flush_input

    pop esi
    pop ebx
    pop ebp
    ret

;; -----------------------------------------------------------------------------
;; .poll_key - Poll single key (EAX = keycode)
;; -----------------------------------------------------------------------------
.poll_key:
    push eax                    ; Save keycode

    push eax
    call _GetAsyncKeyState@4

    ;; High bit set = key down
    test ax, 0x8000
    mov edx, 0
    jz .set_state
    mov edx, 1

.set_state:
    pop eax                     ; Restore keycode
    
    ;; Call input_set_key_state(keycode, state)
    push edx                    ; state
    push eax                    ; keycode
    call _input_set_key_state
    add esp, 8                  ; cdecl cleanup

    ret

;; -----------------------------------------------------------------------------
;; .flush_input - Flush console input buffer
;; -----------------------------------------------------------------------------
.flush_input:
    push ebp
    mov ebp, esp

.flush_loop:
    push num_events
    push dword [_stdin_handle]
    call _GetNumberOfConsoleInputEvents@8

    cmp dword [num_events], 0
    je .flush_done

    push events_read
    push 16
    push input_record
    push dword [_stdin_handle]
    call _ReadConsoleInputA@16

    cmp dword [events_read], 16
    jae .flush_loop

.flush_done:
    pop ebp
    ret
