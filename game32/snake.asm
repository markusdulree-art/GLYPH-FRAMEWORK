;; =============================================================================
;; GLYPH - Snake Game (32-bit)
;; Platform: Windows x86 | Assembler: NASM | Linker: GCC
;; =============================================================================

bits 32

extern _gfx_put_char
extern _gfx_draw_text
extern _input_was_pressed

global _game_init
global _game_update
global _game_render
global _game_should_quit

GRID_W          equ 80
GRID_H          equ 25
MAX_SNAKE_LEN   equ 500
DIR_UP          equ 0
DIR_DOWN        equ 1
DIR_LEFT        equ 2
DIR_RIGHT       equ 3
STATE_PLAYING   equ 0
STATE_GAMEOVER  equ 1
STATE_PAUSED    equ 2

section .bss
    snake_x         resb MAX_SNAKE_LEN
    snake_y         resb MAX_SNAKE_LEN
    snake_len       resd 1
    snake_dir       resd 1
    food_x          resd 1
    food_y          resd 1
    score           resd 1
    game_state      resd 1
    quit_flag       resd 1
    tick_counter    resd 1
    rand_seed       resd 1

section .data
    title_str       db "=== SNAKE (32-bit) ===", 0
    score_str       db "Score: ", 0
    gameover_str    db "GAME OVER! Press ENTER to restart", 0
    pause_str       db "PAUSED - Press SPACE", 0

section .text

;; =============================================================================
;; _game_init
;; =============================================================================
_game_init:
    push ebp
    mov ebp, esp

    mov dword [quit_flag], 0
    mov dword [game_state], STATE_PLAYING
    mov dword [rand_seed], 12345
    call _reset_game

    pop ebp
    ret

_reset_game:
    push ebp
    mov ebp, esp

    mov dword [snake_len], 3
    mov dword [snake_dir], DIR_RIGHT
    mov dword [score], 0
    mov dword [tick_counter], 0

    mov byte [snake_x], 40
    mov byte [snake_x + 1], 39
    mov byte [snake_x + 2], 38
    mov byte [snake_y], 12
    mov byte [snake_y + 1], 12
    mov byte [snake_y + 2], 12

    call _spawn_food

    pop ebp
    ret

_spawn_food:
    push ebp
    mov ebp, esp
    push ebx
    push esi

.retry:
    mov eax, [rand_seed]
    imul eax, 1103515245
    add eax, 12345
    mov [rand_seed], eax
    shr eax, 16
    xor edx, edx
    mov ecx, 78
    div ecx
    inc edx
    mov [food_x], edx

    mov eax, [rand_seed]
    imul eax, 1103515245
    add eax, 12345
    mov [rand_seed], eax
    shr eax, 16
    xor edx, edx
    mov ecx, 22
    div ecx
    add edx, 2
    mov [food_y], edx

    ;; Check not on snake
    mov esi, [snake_len]
    xor ebx, ebx
.check:
    cmp ebx, esi
    jge .ok
    movzx eax, byte [snake_x + ebx]
    cmp eax, [food_x]
    jne .next
    movzx eax, byte [snake_y + ebx]
    cmp eax, [food_y]
    je .retry
.next:
    inc ebx
    jmp .check

.ok:
    pop esi
    pop ebx
    pop ebp
    ret

;; =============================================================================
;; _game_update
;; =============================================================================
_game_update:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ;; Check ESC
    push 0x1B
    call _input_was_pressed
    add esp, 4
    test eax, eax
    jz .no_quit
    mov dword [quit_flag], 1
    jmp .done
.no_quit:

    ;; Game over state
    cmp dword [game_state], STATE_GAMEOVER
    jne .not_gameover
    push 0x0D
    call _input_was_pressed
    add esp, 4
    test eax, eax
    jz .done
    call _reset_game
    mov dword [game_state], STATE_PLAYING
    jmp .done
.not_gameover:

    ;; Paused state
    cmp dword [game_state], STATE_PAUSED
    jne .not_paused
    push 0x20
    call _input_was_pressed
    add esp, 4
    test eax, eax
    jz .done
    mov dword [game_state], STATE_PLAYING
    jmp .done
.not_paused:

    ;; Space = pause
    push 0x20
    call _input_was_pressed
    add esp, 4
    test eax, eax
    jz .no_pause
    mov dword [game_state], STATE_PAUSED
    jmp .done
.no_pause:

    ;; Direction input
    mov esi, [snake_dir]

    push 0x26
    call _input_was_pressed
    add esp, 4
    test eax, eax
    jz .not_up
    cmp esi, DIR_DOWN
    je .not_up
    mov dword [snake_dir], DIR_UP
.not_up:

    push 0x28
    call _input_was_pressed
    add esp, 4
    test eax, eax
    jz .not_down
    cmp esi, DIR_UP
    je .not_down
    mov dword [snake_dir], DIR_DOWN
.not_down:

    push 0x25
    call _input_was_pressed
    add esp, 4
    test eax, eax
    jz .not_left
    cmp esi, DIR_RIGHT
    je .not_left
    mov dword [snake_dir], DIR_LEFT
.not_left:

    push 0x27
    call _input_was_pressed
    add esp, 4
    test eax, eax
    jz .not_right
    cmp esi, DIR_LEFT
    je .not_right
    mov dword [snake_dir], DIR_RIGHT
.not_right:

    ;; Tick counter
    inc dword [tick_counter]
    mov eax, [tick_counter]
    xor edx, edx
    mov ecx, 6
    div ecx
    test edx, edx
    jnz .done

    ;; Move snake body
    mov esi, [snake_len]
    dec esi
.shift:
    cmp esi, 0
    jle .shift_done
    movzx eax, byte [snake_x + esi - 1]
    mov [snake_x + esi], al
    movzx eax, byte [snake_y + esi - 1]
    mov [snake_y + esi], al
    dec esi
    jmp .shift
.shift_done:

    ;; Move head
    movzx esi, byte [snake_x]
    movzx edi, byte [snake_y]

    mov eax, [snake_dir]
    cmp eax, DIR_UP
    jne .mu
    dec edi
    jmp .moved
.mu:
    cmp eax, DIR_DOWN
    jne .md
    inc edi
    jmp .moved
.md:
    cmp eax, DIR_LEFT
    jne .ml
    dec esi
    jmp .moved
.ml:
    inc esi
.moved:

    ;; Wall collision
    cmp esi, 0
    jl .die
    cmp esi, GRID_W
    jge .die
    cmp edi, 1
    jl .die
    cmp edi, GRID_H
    jge .die

    ;; Self collision
    mov ebx, 1
    mov ecx, [snake_len]
.self_check:
    cmp ebx, ecx
    jge .self_ok
    movzx eax, byte [snake_x + ebx]
    cmp eax, esi
    jne .self_next
    movzx eax, byte [snake_y + ebx]
    cmp eax, edi
    je .die
.self_next:
    inc ebx
    jmp .self_check
.self_ok:

    mov [snake_x], sil
    mov [snake_y], dil

    ;; Food collision
    cmp esi, [food_x]
    jne .no_food
    cmp edi, [food_y]
    jne .no_food
    inc dword [score]
    inc dword [snake_len]
    call _spawn_food
.no_food:
    jmp .done

.die:
    mov dword [game_state], STATE_GAMEOVER

.done:
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

;; =============================================================================
;; _game_render
;; =============================================================================
_game_render:
    push ebp
    mov ebp, esp
    push ebx
    push esi

    ;; Title
    push title_str
    push 0
    push 29
    call _gfx_draw_text
    add esp, 12

    ;; Score
    push score_str
    push 0
    push 2
    call _gfx_draw_text
    add esp, 12

    ;; Score number
    mov eax, [score]
    add eax, '0'
    cmp eax, '9'
    jle .single
    mov eax, '9'
.single:
    push eax
    push 0
    push 9
    call _gfx_put_char
    add esp, 12

    ;; Border
    xor ebx, ebx
.border:
    push '-'
    push 1
    push ebx
    call _gfx_put_char
    add esp, 12
    inc ebx
    cmp ebx, GRID_W
    jl .border

    ;; Food
    push '*'
    push dword [food_y]
    push dword [food_x]
    call _gfx_put_char
    add esp, 12

    ;; Snake
    xor esi, esi
.draw_snake:
    cmp esi, [snake_len]
    jge .snake_done

    mov eax, 'O'
    test esi, esi
    jnz .body
    mov eax, '@'
.body:
    push eax
    movzx eax, byte [snake_y + esi]
    push eax
    movzx eax, byte [snake_x + esi]
    push eax
    call _gfx_put_char
    add esp, 12

    inc esi
    jmp .draw_snake
.snake_done:

    ;; Messages
    cmp dword [game_state], STATE_GAMEOVER
    jne .not_go
    push gameover_str
    push 12
    push 22
    call _gfx_draw_text
    add esp, 12
.not_go:

    cmp dword [game_state], STATE_PAUSED
    jne .not_p
    push pause_str
    push 12
    push 30
    call _gfx_draw_text
    add esp, 12
.not_p:

    pop esi
    pop ebx
    pop ebp
    ret

;; =============================================================================
;; _game_should_quit
;; =============================================================================
_game_should_quit:
    mov eax, [quit_flag]
    ret
