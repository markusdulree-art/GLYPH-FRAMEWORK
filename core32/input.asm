;; =============================================================================
;; GLYPH - Core Input Module (32-bit)
;; Platform: Windows x86 | Assembler: NASM | Linker: GCC
;; =============================================================================

bits 32

;; Exports
global _input_init
global _input_begin_frame
global _input_is_down
global _input_was_pressed
global _input_was_released
global _input_set_key_state

global _key_state
global _key_pressed
global _key_released

section .bss
    _key_state      resb 256
    _key_pressed    resb 256
    _key_released   resb 256
    prev_key_state  resb 256

section .text

;; =============================================================================
;; _input_init - Initialize input state
;; =============================================================================
_input_init:
    push ebp
    mov ebp, esp
    push edi
    push ecx

    ;; Clear all arrays
    mov edi, _key_state
    xor eax, eax
    mov ecx, 256
    rep stosb

    mov edi, _key_pressed
    xor eax, eax
    mov ecx, 256
    rep stosb

    mov edi, _key_released
    xor eax, eax
    mov ecx, 256
    rep stosb

    mov edi, prev_key_state
    xor eax, eax
    mov ecx, 256
    rep stosb

    pop ecx
    pop edi
    pop ebp
    ret

;; =============================================================================
;; _input_begin_frame - Compute pressed/released from state changes
;; =============================================================================
_input_begin_frame:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov esi, _key_state
    mov edi, prev_key_state
    mov ebx, _key_pressed

    xor ecx, ecx

.loop:
    movzx eax, byte [esi + ecx]     ; current
    movzx edx, byte [edi + ecx]     ; previous

    ;; pressed = current && !previous
    xor ebx, ebx
    test al, al
    jz .not_pressed
    test dl, dl
    jnz .not_pressed
    mov bl, 1
.not_pressed:
    mov [_key_pressed + ecx], bl

    ;; released = !current && previous
    xor ebx, ebx
    test al, al
    jnz .not_released
    test dl, dl
    jz .not_released
    mov bl, 1
.not_released:
    mov [_key_released + ecx], bl

    ;; Copy current to previous
    mov [edi + ecx], al

    inc ecx
    cmp ecx, 256
    jb .loop

    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

;; =============================================================================
;; _input_is_down - Check if key is held
;; Args: [ebp+8]=keycode
;; Returns: EAX=0/1
;; =============================================================================
_input_is_down:
    push ebp
    mov ebp, esp

    mov ecx, [ebp + 8]
    xor eax, eax
    cmp ecx, 256
    jae .done
    movzx eax, byte [_key_state + ecx]

.done:
    pop ebp
    ret

;; =============================================================================
;; _input_was_pressed - Check if key was just pressed
;; Args: [ebp+8]=keycode
;; Returns: EAX=0/1
;; =============================================================================
_input_was_pressed:
    push ebp
    mov ebp, esp

    mov ecx, [ebp + 8]
    xor eax, eax
    cmp ecx, 256
    jae .done
    movzx eax, byte [_key_pressed + ecx]

.done:
    pop ebp
    ret

;; =============================================================================
;; _input_was_released - Check if key was just released
;; Args: [ebp+8]=keycode
;; Returns: EAX=0/1
;; =============================================================================
_input_was_released:
    push ebp
    mov ebp, esp

    mov ecx, [ebp + 8]
    xor eax, eax
    cmp ecx, 256
    jae .done
    movzx eax, byte [_key_released + ecx]

.done:
    pop ebp
    ret

;; =============================================================================
;; _input_set_key_state - Set key state (called by platform)
;; Args: [ebp+8]=keycode, [ebp+12]=state
;; =============================================================================
_input_set_key_state:
    push ebp
    mov ebp, esp

    mov ecx, [ebp + 8]          ; keycode
    mov eax, [ebp + 12]         ; state

    cmp ecx, 256
    jae .done
    mov [_key_state + ecx], al

.done:
    pop ebp
    ret
