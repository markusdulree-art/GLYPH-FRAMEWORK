;; =============================================================================
;; GLYPH - Core Framebuffer Module
;; Platform: Windows x64 | Assembler: NASM | Linker: GCC
;; =============================================================================
;; Portable framebuffer logic. No platform-specific code.
;; 
;; Cell Layout (4 bytes per cell):
;;   byte 0: glyph     (ASCII character)
;;   byte 1: fg_color  (0-15, standard console colors)
;;   byte 2: bg_color  (0-15, standard console colors)
;;   byte 3: flags     (reserved for future: bold, blink, etc)
;;
;; Double buffering:
;;   - back_buffer:  Write here during rendering
;;   - front_buffer: What's currently displayed
;;   - gfx_present compares and updates only changed cells
;; =============================================================================

bits 64
default rel

;; -----------------------------------------------------------------------------
;; Constants
;; -----------------------------------------------------------------------------
GRID_WIDTH      equ 80
GRID_HEIGHT     equ 25
CELL_SIZE       equ 4
BUFFER_SIZE     equ GRID_WIDTH * GRID_HEIGHT * CELL_SIZE  ; 8000 bytes

;; Default colors
COLOR_BLACK     equ 0
COLOR_BLUE      equ 1
COLOR_GREEN     equ 2
COLOR_CYAN      equ 3
COLOR_RED       equ 4
COLOR_MAGENTA   equ 5
COLOR_BROWN     equ 6
COLOR_LGRAY     equ 7
COLOR_DGRAY     equ 8
COLOR_LBLUE     equ 9
COLOR_LGREEN    equ 10
COLOR_LCYAN     equ 11
COLOR_LRED      equ 12
COLOR_LMAGENTA  equ 13
COLOR_YELLOW    equ 14
COLOR_WHITE     equ 15

;; Cell structure offsets
CELL_GLYPH      equ 0
CELL_FG         equ 1
CELL_BG         equ 2
CELL_FLAGS      equ 3

;; -----------------------------------------------------------------------------
;; Exports
;; -----------------------------------------------------------------------------
global gfx_init
global gfx_clear
global gfx_put_cell
global gfx_put_char
global gfx_draw_text
global gfx_present
global gfx_get_dirty_count

global back_buffer
global front_buffer
global dirty_count

global GRID_WIDTH
global GRID_HEIGHT
global CELL_SIZE
global BUFFER_SIZE

;; -----------------------------------------------------------------------------
;; Data Section
;; -----------------------------------------------------------------------------
section .bss
    back_buffer     resb BUFFER_SIZE
    front_buffer    resb BUFFER_SIZE
    dirty_count     resq 1          ; Number of cells changed in last present

section .data
    default_fg      db COLOR_LGRAY
    default_bg      db COLOR_BLACK

;; -----------------------------------------------------------------------------
;; Code Section
;; -----------------------------------------------------------------------------
section .text

;; -----------------------------------------------------------------------------
;; gfx_init
;; Initialize framebuffer. Clear both buffers.
;; Args: none
;; Returns: none
;; -----------------------------------------------------------------------------
gfx_init:
    push rbx
    push rdi
    
    ; Clear back buffer
    lea rdi, [back_buffer]
    mov rcx, BUFFER_SIZE / 4
    
.clear_back:
    mov byte [rdi + CELL_GLYPH], ' '
    mov byte [rdi + CELL_FG], COLOR_LGRAY
    mov byte [rdi + CELL_BG], COLOR_BLACK
    mov byte [rdi + CELL_FLAGS], 0
    add rdi, CELL_SIZE
    dec rcx
    jnz .clear_back
    
    ; Clear front buffer (different from back to force full redraw)
    lea rdi, [front_buffer]
    mov rcx, BUFFER_SIZE / 4
    
.clear_front:
    mov byte [rdi + CELL_GLYPH], 0
    mov byte [rdi + CELL_FG], 0
    mov byte [rdi + CELL_BG], 0
    mov byte [rdi + CELL_FLAGS], 0xFF    ; Force dirty
    add rdi, CELL_SIZE
    dec rcx
    jnz .clear_front
    
    lea rax, [dirty_count]
    mov qword [rax], 0
    
    pop rdi
    pop rbx
    ret

;; -----------------------------------------------------------------------------
;; gfx_clear
;; Clear back buffer to spaces with default colors.
;; Args: none
;; Returns: none
;; -----------------------------------------------------------------------------
gfx_clear:
    push rdi
    push rcx
    
    lea rdi, [back_buffer]
    mov rcx, GRID_WIDTH * GRID_HEIGHT
    
.loop:
    mov byte [rdi + CELL_GLYPH], ' '
    mov al, [default_fg]
    mov byte [rdi + CELL_FG], al
    mov al, [default_bg]
    mov byte [rdi + CELL_BG], al
    mov byte [rdi + CELL_FLAGS], 0
    add rdi, CELL_SIZE
    dec rcx
    jnz .loop
    
    pop rcx
    pop rdi
    ret

;; -----------------------------------------------------------------------------
;; gfx_put_cell
;; Put a cell at (x, y) with full control.
;; Args:
;;   rcx = x (0-based)
;;   rdx = y (0-based)
;;   r8b = glyph (ASCII)
;;   r9b = fg_color
;;   [rsp+40] = bg_color (stack, after shadow space)
;; Returns: none
;; -----------------------------------------------------------------------------
gfx_put_cell:
    push rbx
    push rdi
    
    ; Bounds check
    cmp rcx, GRID_WIDTH
    jae .done
    cmp rdx, GRID_HEIGHT
    jae .done
    
    ; Calculate offset: (y * WIDTH + x) * CELL_SIZE
    imul rax, rdx, GRID_WIDTH
    add rax, rcx
    shl rax, 2              ; * 4 (CELL_SIZE)
    
    lea rdi, [back_buffer]
    add rdi, rax
    
    ; Write cell data
    mov [rdi + CELL_GLYPH], r8b
    mov [rdi + CELL_FG], r9b
    mov al, [rsp + 40]      ; bg_color from stack
    mov [rdi + CELL_BG], al
    mov byte [rdi + CELL_FLAGS], 0
    
.done:
    pop rdi
    pop rbx
    ret

;; -----------------------------------------------------------------------------
;; gfx_put_char
;; Simplified: put character at (x, y) with default colors.
;; Args:
;;   rcx = x
;;   rdx = y
;;   r8b = glyph
;; Returns: none
;; -----------------------------------------------------------------------------
gfx_put_char:
    push rbx
    push rdi
    
    ; Bounds check
    cmp rcx, GRID_WIDTH
    jae .done
    cmp rdx, GRID_HEIGHT
    jae .done
    
    ; Calculate offset
    imul rax, rdx, GRID_WIDTH
    add rax, rcx
    shl rax, 2
    
    lea rdi, [back_buffer]
    add rdi, rax
    
    mov [rdi + CELL_GLYPH], r8b
    mov al, [default_fg]
    mov [rdi + CELL_FG], al
    mov al, [default_bg]
    mov [rdi + CELL_BG], al
    
.done:
    pop rdi
    pop rbx
    ret

;; -----------------------------------------------------------------------------
;; gfx_draw_text
;; Draw a null-terminated string starting at (x, y).
;; Args:
;;   rcx = x
;;   rdx = y
;;   r8  = pointer to null-terminated string
;; Returns: none
;; -----------------------------------------------------------------------------
gfx_draw_text:
    push rbx
    push rdi
    push rsi
    push r12
    push r13
    
    mov r12, rcx            ; x
    mov r13, rdx            ; y
    mov rsi, r8             ; string pointer
    
.loop:
    movzx rax, byte [rsi]
    test al, al
    jz .done
    
    ; Put character
    mov rcx, r12
    mov rdx, r13
    mov r8b, al
    call gfx_put_char
    
    inc rsi
    inc r12
    
    ; Wrap at edge? (optional - currently just clips)
    cmp r12, GRID_WIDTH
    jb .loop
    
.done:
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rbx
    ret

;; -----------------------------------------------------------------------------
;; gfx_present
;; Compare back_buffer to front_buffer, return count of dirty cells.
;; Platform layer reads dirty_count and buffers directly.
;; Args: none
;; Returns: rax = number of dirty cells
;; -----------------------------------------------------------------------------
gfx_present:
    push rbx
    push rdi
    push rsi
    push r12
    
    lea rsi, [back_buffer]
    lea rdi, [front_buffer]
    xor r12, r12            ; dirty counter
    mov rcx, GRID_WIDTH * GRID_HEIGHT
    
.loop:
    ; Compare 4-byte cells
    mov eax, [rsi]
    cmp eax, [rdi]
    je .same
    
    ; Cell is dirty - copy to front buffer
    mov [rdi], eax
    inc r12
    
.same:
    add rsi, CELL_SIZE
    add rdi, CELL_SIZE
    dec rcx
    jnz .loop
    
    lea rax, [dirty_count]
    mov [rax], r12
    mov rax, r12
    
    pop r12
    pop rsi
    pop rdi
    pop rbx
    ret

;; -----------------------------------------------------------------------------
;; gfx_get_dirty_count
;; Returns the dirty count from last present.
;; Args: none
;; Returns: rax = dirty_count
;; -----------------------------------------------------------------------------
gfx_get_dirty_count:
    lea rax, [dirty_count]
    mov rax, [rax]
    ret
