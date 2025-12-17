;; GLYPH - Snake Game Example
bits 64
default rel

extern gfx_put_char
extern gfx_draw_text
extern input_was_pressed

global game_init
global game_update
global game_render
global game_should_quit

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
    snake_len       resq 1
    snake_dir       resq 1
    food_x          resq 1
    food_y          resq 1
    score           resq 1
    game_state      resq 1
    quit_flag       resq 1
    tick_counter    resq 1
    rand_seed       resq 1

section .data
    title_str       db "=== SNAKE ===", 0
    score_str       db "Score: ", 0
    gameover_str    db "GAME OVER! Press ENTER to restart", 0
    pause_str       db "PAUSED - Press SPACE", 0

section .text

game_init:
    push rbx
    sub rsp, 32
    
    lea rax, [quit_flag]
    mov qword [rax], 0
    lea rax, [game_state]
    mov qword [rax], STATE_PLAYING
    lea rax, [rand_seed]
    mov qword [rax], 12345
    call reset_game
    
    add rsp, 32
    pop rbx
    ret

reset_game:
    push rbx
    sub rsp, 32
    
    lea rax, [snake_len]
    mov qword [rax], 3
    lea rax, [snake_dir]
    mov qword [rax], DIR_RIGHT
    lea rax, [score]
    mov qword [rax], 0
    lea rax, [tick_counter]
    mov qword [rax], 0
    
    lea rax, [snake_x]
    mov byte [rax], 40
    mov byte [rax + 1], 39
    mov byte [rax + 2], 38
    lea rax, [snake_y]
    mov byte [rax], 12
    mov byte [rax + 1], 12
    mov byte [rax + 2], 12
    
    call spawn_food
    
    add rsp, 32
    pop rbx
    ret

spawn_food:
    push rbx
    push r12
    push r13
    sub rsp, 32
    
.retry:
    lea rax, [rand_seed]
    mov rbx, [rax]
    imul rbx, 1103515245
    add rbx, 12345
    mov [rax], rbx
    shr rbx, 16
    mov rax, rbx
    xor rdx, rdx
    mov rcx, 78
    div rcx
    inc rdx
    lea rax, [food_x]
    mov [rax], rdx
    
    lea rax, [rand_seed]
    mov rbx, [rax]
    imul rbx, 1103515245
    add rbx, 12345
    mov [rax], rbx
    shr rbx, 16
    mov rax, rbx
    xor rdx, rdx
    mov rcx, 22
    div rcx
    add rdx, 2
    lea rax, [food_y]
    mov [rax], rdx
    
    lea rax, [snake_len]
    mov r12, [rax]
    xor r13, r13
.check:
    cmp r13, r12
    jge .ok
    lea rax, [snake_x]
    movzx rbx, byte [rax + r13]
    lea rax, [food_x]
    cmp rbx, [rax]
    jne .next
    lea rax, [snake_y]
    movzx rbx, byte [rax + r13]
    lea rax, [food_y]
    cmp rbx, [rax]
    je .retry
.next:
    inc r13
    jmp .check
.ok:
    add rsp, 32
    pop r13
    pop r12
    pop rbx
    ret

game_update:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48
    
    ; Check escape
    mov rcx, 0x1B
    call input_was_pressed
    test rax, rax
    jz .no_quit
    lea rax, [quit_flag]
    mov qword [rax], 1
    jmp .done
.no_quit:

    ; Check game over state
    lea rax, [game_state]
    cmp qword [rax], STATE_GAMEOVER
    jne .not_gameover
    mov rcx, 0x0D
    call input_was_pressed
    test rax, rax
    jz .done
    call reset_game
    lea rax, [game_state]
    mov qword [rax], STATE_PLAYING
    jmp .done
.not_gameover:

    lea rax, [game_state]
    cmp qword [rax], STATE_PAUSED
    jne .not_paused
    mov rcx, 0x20
    call input_was_pressed
    test rax, rax
    jz .done
    lea rax, [game_state]
    mov qword [rax], STATE_PLAYING
    jmp .done
.not_paused:

    ; Space = pause
    mov rcx, 0x20
    call input_was_pressed
    test rax, rax
    jz .no_pause
    lea rax, [game_state]
    mov qword [rax], STATE_PAUSED
    jmp .done
.no_pause:

    ; Input
    lea rax, [snake_dir]
    mov r12, [rax]
    
    mov rcx, 0x26
    call input_was_pressed
    test rax, rax
    jz .not_up
    cmp r12, DIR_DOWN
    je .not_up
    lea rax, [snake_dir]
    mov qword [rax], DIR_UP
.not_up:
    mov rcx, 0x28
    call input_was_pressed
    test rax, rax
    jz .not_down
    cmp r12, DIR_UP
    je .not_down
    lea rax, [snake_dir]
    mov qword [rax], DIR_DOWN
.not_down:
    mov rcx, 0x25
    call input_was_pressed
    test rax, rax
    jz .not_left
    cmp r12, DIR_RIGHT
    je .not_left
    lea rax, [snake_dir]
    mov qword [rax], DIR_LEFT
.not_left:
    mov rcx, 0x27
    call input_was_pressed
    test rax, rax
    jz .not_right
    cmp r12, DIR_LEFT
    je .not_right
    lea rax, [snake_dir]
    mov qword [rax], DIR_RIGHT
.not_right:

    ; Tick counter
    lea rax, [tick_counter]
    inc qword [rax]
    mov rax, [rax]
    xor rdx, rdx
    mov rcx, 6
    div rcx
    test rdx, rdx
    jnz .done
    
    ; Move snake body
    lea rax, [snake_len]
    mov r12, [rax]
    dec r12
.shift:
    cmp r12, 0
    jle .shift_done
    lea rax, [snake_x]
    movzx rbx, byte [rax + r12 - 1]
    mov [rax + r12], bl
    lea rax, [snake_y]
    movzx rbx, byte [rax + r12 - 1]
    mov [rax + r12], bl
    dec r12
    jmp .shift
.shift_done:
    
    ; Move head
    lea rax, [snake_x]
    movzx r12, byte [rax]
    lea rax, [snake_y]
    movzx r13, byte [rax]
    
    lea rax, [snake_dir]
    mov rax, [rax]
    cmp rax, DIR_UP
    jne .mu
    dec r13
    jmp .moved
.mu:
    cmp rax, DIR_DOWN
    jne .md
    inc r13
    jmp .moved
.md:
    cmp rax, DIR_LEFT
    jne .ml
    dec r12
    jmp .moved
.ml:
    inc r12
.moved:
    
    ; Wall collision
    cmp r12, 0
    jl .die
    cmp r12, GRID_W
    jge .die
    cmp r13, 1
    jl .die
    cmp r13, GRID_H
    jge .die
    
    ; Self collision
    mov r14, 1
    lea rax, [snake_len]
    mov r15, [rax]
.self_check:
    cmp r14, r15
    jge .self_ok
    lea rax, [snake_x]
    movzx rbx, byte [rax + r14]
    cmp rbx, r12
    jne .self_next
    lea rax, [snake_y]
    movzx rbx, byte [rax + r14]
    cmp rbx, r13
    je .die
.self_next:
    inc r14
    jmp .self_check
.self_ok:
    
    lea rax, [snake_x]
    mov [rax], r12b
    lea rax, [snake_y]
    mov [rax], r13b
    
    ; Food collision
    lea rax, [food_x]
    cmp r12, [rax]
    jne .no_food
    lea rax, [food_y]
    cmp r13, [rax]
    jne .no_food
    lea rax, [score]
    inc qword [rax]
    lea rax, [snake_len]
    inc qword [rax]
    call spawn_food
.no_food:
    jmp .done
    
.die:
    lea rax, [game_state]
    mov qword [rax], STATE_GAMEOVER
    
.done:
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

game_render:
    push rbx
    push r12
    push r13
    sub rsp, 40
    
    ; Title
    mov rcx, 33
    xor rdx, rdx
    lea r8, [title_str]
    call gfx_draw_text
    
    ; Score label
    mov rcx, 2
    xor rdx, rdx
    lea r8, [score_str]
    call gfx_draw_text
    
    ; Score number
    lea rax, [score]
    mov rax, [rax]
    add rax, '0'
    cmp rax, '9'
    jle .single
    mov rax, '9'
.single:
    mov rcx, 9
    xor rdx, rdx
    mov r8, rax
    call gfx_put_char
    
    ; Border
    xor r12, r12
.border_top:
    mov rcx, r12
    mov rdx, 1
    mov r8, '-'
    call gfx_put_char
    inc r12
    cmp r12, GRID_W
    jl .border_top
    
    ; Food
    lea rax, [food_x]
    mov rcx, [rax]
    lea rax, [food_y]
    mov rdx, [rax]
    mov r8, '*'
    call gfx_put_char
    
    ; Snake
    xor r12, r12
.draw_snake:
    lea rax, [snake_len]
    cmp r12, [rax]
    jge .snake_done
    lea rax, [snake_x]
    movzx rcx, byte [rax + r12]
    lea rax, [snake_y]
    movzx rdx, byte [rax + r12]
    mov r8, 'O'
    test r12, r12
    jnz .body
    mov r8, '@'
.body:
    call gfx_put_char
    inc r12
    jmp .draw_snake
.snake_done:
    
    ; Game over message
    lea rax, [game_state]
    cmp qword [rax], STATE_GAMEOVER
    jne .not_go
    mov rcx, 22
    mov rdx, 12
    lea r8, [gameover_str]
    call gfx_draw_text
.not_go:
    
    lea rax, [game_state]
    cmp qword [rax], STATE_PAUSED
    jne .not_p
    mov rcx, 30
    mov rdx, 12
    lea r8, [pause_str]
    call gfx_draw_text
.not_p:
    
    add rsp, 40
    pop r13
    pop r12
    pop rbx
    ret

game_should_quit:
    lea rax, [quit_flag]
    mov rax, [rax]
    ret
