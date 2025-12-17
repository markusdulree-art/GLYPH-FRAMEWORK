;; =============================================================================
;; GLYPH - Core Framebuffer Module (32-bit)
;; Platform: Windows x86 | Assembler: NASM | Linker: GCC
;; =============================================================================
;; Portable framebuffer logic for 32-bit systems.
;; =============================================================================

bits 32

;; Constants
GRID_WIDTH      equ 80
GRID_HEIGHT     equ 25
CELL_SIZE       equ 4
BUFFER_SIZE     equ GRID_WIDTH * GRID_HEIGHT * CELL_SIZE

COLOR_LGRAY     equ 7
COLOR_BLACK     equ 0

CELL_GLYPH      equ 0
CELL_FG         equ 1
CELL_BG         equ 2
CELL_FLAGS      equ 3

;; Exports
global _gfx_init
global _gfx_clear
global _gfx_put_cell
global _gfx_put_char
global _gfx_draw_text
global _gfx_present
global _gfx_get_dirty_count

global _back_buffer
global _front_buffer
global _dirty_count

section .bss
    _back_buffer    resb BUFFER_SIZE
    _front_buffer   resb BUFFER_SIZE
    _dirty_count    resd 1

section .data
    default_fg      db COLOR_LGRAY
    default_bg      db COLOR_BLACK

section .text

;; =============================================================================
;; _gfx_init - Initialize framebuffer
;; =============================================================================
_gfx_init:
    push ebp
    mov ebp, esp
    push edi
    push ecx

    ;; Clear back buffer
    mov edi, _back_buffer
    mov ecx, GRID_WIDTH * GRID_HEIGHT

.clear_back:
    mov byte [edi + CELL_GLYPH], ' '
    mov byte [edi + CELL_FG], COLOR_LGRAY
    mov byte [edi + CELL_BG], COLOR_BLACK
    mov byte [edi + CELL_FLAGS], 0
    add edi, CELL_SIZE
    dec ecx
    jnz .clear_back

    ;; Clear front buffer (force dirty)
    mov edi, _front_buffer
    mov ecx, GRID_WIDTH * GRID_HEIGHT

.clear_front:
    mov byte [edi + CELL_GLYPH], 0
    mov byte [edi + CELL_FG], 0
    mov byte [edi + CELL_BG], 0
    mov byte [edi + CELL_FLAGS], 0xFF
    add edi, CELL_SIZE
    dec ecx
    jnz .clear_front

    mov dword [_dirty_count], 0

    pop ecx
    pop edi
    pop ebp
    ret

;; =============================================================================
;; _gfx_clear - Clear back buffer
;; =============================================================================
_gfx_clear:
    push ebp
    mov ebp, esp
    push edi
    push ecx

    mov edi, _back_buffer
    mov ecx, GRID_WIDTH * GRID_HEIGHT

.loop:
    mov byte [edi + CELL_GLYPH], ' '
    mov al, [default_fg]
    mov byte [edi + CELL_FG], al
    mov al, [default_bg]
    mov byte [edi + CELL_BG], al
    mov byte [edi + CELL_FLAGS], 0
    add edi, CELL_SIZE
    dec ecx
    jnz .loop

    pop ecx
    pop edi
    pop ebp
    ret

;; =============================================================================
;; _gfx_put_char - Draw character with default colors
;; Args: [ebp+8]=x, [ebp+12]=y, [ebp+16]=char
;; =============================================================================
_gfx_put_char:
    push ebp
    mov ebp, esp
    push edi
    push ebx

    mov eax, [ebp + 8]          ; x
    mov edx, [ebp + 12]         ; y

    ;; Bounds check
    cmp eax, GRID_WIDTH
    jae .done
    cmp edx, GRID_HEIGHT
    jae .done

    ;; Calculate offset: (y * WIDTH + x) * CELL_SIZE
    imul edx, GRID_WIDTH
    add edx, eax
    shl edx, 2                  ; * 4

    mov edi, _back_buffer
    add edi, edx

    mov eax, [ebp + 16]         ; char
    mov [edi + CELL_GLYPH], al
    mov al, [default_fg]
    mov [edi + CELL_FG], al
    mov al, [default_bg]
    mov [edi + CELL_BG], al

.done:
    pop ebx
    pop edi
    pop ebp
    ret

;; =============================================================================
;; _gfx_put_cell - Draw cell with custom colors
;; Args: [ebp+8]=x, [ebp+12]=y, [ebp+16]=char, [ebp+20]=fg, [ebp+24]=bg
;; =============================================================================
_gfx_put_cell:
    push ebp
    mov ebp, esp
    push edi

    mov eax, [ebp + 8]          ; x
    mov edx, [ebp + 12]         ; y

    ;; Bounds check
    cmp eax, GRID_WIDTH
    jae .done
    cmp edx, GRID_HEIGHT
    jae .done

    ;; Calculate offset
    imul edx, GRID_WIDTH
    add edx, eax
    shl edx, 2

    mov edi, _back_buffer
    add edi, edx

    mov eax, [ebp + 16]
    mov [edi + CELL_GLYPH], al
    mov eax, [ebp + 20]
    mov [edi + CELL_FG], al
    mov eax, [ebp + 24]
    mov [edi + CELL_BG], al

.done:
    pop edi
    pop ebp
    ret

;; =============================================================================
;; _gfx_draw_text - Draw null-terminated string
;; Args: [ebp+8]=x, [ebp+12]=y, [ebp+16]=string_ptr
;; =============================================================================
_gfx_draw_text:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov ebx, [ebp + 8]          ; x
    mov edi, [ebp + 12]         ; y
    mov esi, [ebp + 16]         ; string

.loop:
    movzx eax, byte [esi]
    test al, al
    jz .done

    ;; Call gfx_put_char(x, y, char)
    push eax                    ; char
    push edi                    ; y
    push ebx                    ; x
    call _gfx_put_char
    add esp, 12

    inc esi
    inc ebx
    cmp ebx, GRID_WIDTH
    jb .loop

.done:
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

;; =============================================================================
;; _gfx_present - Sync back buffer to front buffer
;; Returns: EAX = dirty cell count
;; =============================================================================
_gfx_present:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov esi, _back_buffer
    mov edi, _front_buffer
    xor ebx, ebx                ; dirty counter
    mov ecx, GRID_WIDTH * GRID_HEIGHT

.loop:
    mov eax, [esi]
    cmp eax, [edi]
    je .same

    mov [edi], eax
    inc ebx

.same:
    add esi, CELL_SIZE
    add edi, CELL_SIZE
    dec ecx
    jnz .loop

    mov [_dirty_count], ebx
    mov eax, ebx

    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

;; =============================================================================
;; _gfx_get_dirty_count
;; =============================================================================
_gfx_get_dirty_count:
    mov eax, [_dirty_count]
    ret
