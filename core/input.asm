;; =============================================================================
;; GLYPH - Core Input Module
;; =============================================================================
;; Portable input state representation. No platform-specific code.
;;
;; Design:
;;   - key_state[256]: Current state (1 = down, 0 = up)
;;   - key_pressed[256]: Just pressed this frame
;;   - key_released[256]: Just released this frame
;;
;; Platform layer updates these. Core exposes clean queries.
;; =============================================================================

bits 64
default rel

;; -----------------------------------------------------------------------------
;; Constants - Virtual Key Codes (Windows compatible)
;; -----------------------------------------------------------------------------
KEY_BACKSPACE   equ 0x08
KEY_TAB         equ 0x09
KEY_ENTER       equ 0x0D
KEY_SHIFT       equ 0x10
KEY_CTRL        equ 0x11
KEY_ALT         equ 0x12
KEY_ESCAPE      equ 0x1B
KEY_SPACE       equ 0x20
KEY_LEFT        equ 0x25
KEY_UP          equ 0x26
KEY_RIGHT       equ 0x27
KEY_DOWN        equ 0x28

;; Letter keys (A-Z = 0x41-0x5A)
KEY_A           equ 0x41
KEY_B           equ 0x42
KEY_C           equ 0x43
KEY_D           equ 0x44
KEY_E           equ 0x45
KEY_F           equ 0x46
KEY_G           equ 0x47
KEY_H           equ 0x48
KEY_I           equ 0x49
KEY_J           equ 0x4A
KEY_K           equ 0x4B
KEY_L           equ 0x4C
KEY_M           equ 0x4D
KEY_N           equ 0x4E
KEY_O           equ 0x4F
KEY_P           equ 0x50
KEY_Q           equ 0x51
KEY_R           equ 0x52
KEY_S           equ 0x53
KEY_T           equ 0x54
KEY_U           equ 0x55
KEY_V           equ 0x56
KEY_W           equ 0x57
KEY_X           equ 0x58
KEY_Y           equ 0x59
KEY_Z           equ 0x5A

;; Number keys (0-9 = 0x30-0x39)
KEY_0           equ 0x30
KEY_1           equ 0x31
KEY_2           equ 0x32
KEY_3           equ 0x33
KEY_4           equ 0x34
KEY_5           equ 0x35
KEY_6           equ 0x36
KEY_7           equ 0x37
KEY_8           equ 0x38
KEY_9           equ 0x39

;; -----------------------------------------------------------------------------
;; Exports
;; -----------------------------------------------------------------------------
global input_init
global input_begin_frame
global input_is_down
global input_was_pressed
global input_was_released
global input_set_key_state

global key_state
global key_pressed
global key_released

global KEY_UP
global KEY_DOWN
global KEY_LEFT
global KEY_RIGHT
global KEY_ESCAPE
global KEY_SPACE
global KEY_ENTER
global KEY_W
global KEY_A
global KEY_S
global KEY_D

;; -----------------------------------------------------------------------------
;; Data Section
;; -----------------------------------------------------------------------------
section .bss
    key_state       resb 256    ; Current state: 1 = down, 0 = up
    key_pressed     resb 256    ; Just pressed this frame
    key_released    resb 256    ; Just released this frame
    prev_key_state  resb 256    ; Previous frame state

;; -----------------------------------------------------------------------------
;; Code Section
;; -----------------------------------------------------------------------------
section .text

;; -----------------------------------------------------------------------------
;; input_init
;; Initialize all input state to zero.
;; Args: none
;; Returns: none
;; -----------------------------------------------------------------------------
input_init:
    push rdi
    push rcx
    
    ; Clear all arrays
    lea rdi, [key_state]
    xor eax, eax
    mov ecx, 256
    rep stosb
    
    lea rdi, [key_pressed]
    xor eax, eax
    mov ecx, 256
    rep stosb
    
    lea rdi, [key_released]
    xor eax, eax
    mov ecx, 256
    rep stosb
    
    lea rdi, [prev_key_state]
    xor eax, eax
    mov ecx, 256
    rep stosb
    
    pop rcx
    pop rdi
    ret

;; -----------------------------------------------------------------------------
;; input_begin_frame
;; Called at start of frame. Computes pressed/released from state changes.
;; Must be called AFTER platform updates key_state.
;; Args: none
;; Returns: none
;; -----------------------------------------------------------------------------
input_begin_frame:
    push rbx
    push rdi
    push rsi
    push r12
    
    lea rsi, [key_state]
    lea rdi, [prev_key_state]
    lea rbx, [key_pressed]
    lea r12, [key_released]
    
    xor rcx, rcx
    
.loop:
    movzx eax, byte [rsi + rcx]     ; current
    movzx edx, byte [rdi + rcx]     ; previous
    
    ; pressed = current && !previous
    xor r8d, r8d
    test al, al
    jz .not_pressed
    test dl, dl
    jnz .not_pressed
    mov r8b, 1
.not_pressed:
    mov [rbx + rcx], r8b
    
    ; released = !current && previous
    xor r8d, r8d
    test al, al
    jnz .not_released
    test dl, dl
    jz .not_released
    mov r8b, 1
.not_released:
    mov [r12 + rcx], r8b
    
    ; Copy current to previous for next frame
    mov [rdi + rcx], al
    
    inc rcx
    cmp rcx, 256
    jb .loop
    
    pop r12
    pop rsi
    pop rdi
    pop rbx
    ret

;; -----------------------------------------------------------------------------
;; input_is_down
;; Check if a key is currently held down.
;; Args:
;;   rcx = key code (0-255)
;; Returns: rax = 1 if down, 0 if up
;; -----------------------------------------------------------------------------
input_is_down:
    xor eax, eax
    cmp rcx, 256
    jae .done
    lea rdx, [key_state]
    movzx eax, byte [rdx + rcx]
.done:
    ret

;; -----------------------------------------------------------------------------
;; input_was_pressed
;; Check if a key was just pressed this frame.
;; Args:
;;   rcx = key code (0-255)
;; Returns: rax = 1 if just pressed, 0 otherwise
;; -----------------------------------------------------------------------------
input_was_pressed:
    xor eax, eax
    cmp rcx, 256
    jae .done
    lea rdx, [key_pressed]
    movzx eax, byte [rdx + rcx]
.done:
    ret

;; -----------------------------------------------------------------------------
;; input_was_released
;; Check if a key was just released this frame.
;; Args:
;;   rcx = key code (0-255)
;; Returns: rax = 1 if just released, 0 otherwise
;; -----------------------------------------------------------------------------
input_was_released:
    xor eax, eax
    cmp rcx, 256
    jae .done
    lea rdx, [key_released]
    movzx eax, byte [rdx + rcx]
.done:
    ret

;; -----------------------------------------------------------------------------
;; input_set_key_state
;; Called by platform layer to set a key's state.
;; Args:
;;   rcx = key code (0-255)
;;   rdx = state (1 = down, 0 = up)
;; Returns: none
;; -----------------------------------------------------------------------------
input_set_key_state:
    cmp rcx, 256
    jae .done
    lea rax, [key_state]
    mov [rax + rcx], dl
.done:
    ret
