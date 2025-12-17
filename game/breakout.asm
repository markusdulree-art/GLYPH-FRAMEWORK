;; =============================================================================
;; GLYPH - Breakout Game Example (64-bit)
;; Platform: Windows x64 | Assembler: NASM | Linker: GCC
;; =============================================================================
;; Brick breaker game with paddle and bouncing ball
;; =============================================================================

bits 64
default rel

extern gfx_put_char
extern gfx_put_cell
extern gfx_draw_text
extern input_is_down
extern input_was_pressed

global game_init
global game_update
global game_render
global game_should_quit

;; Constants
SCREEN_W        equ 80
SCREEN_H        equ 25
PADDLE_Y        equ 23
PADDLE_WIDTH    equ 8
BRICK_ROWS      equ 4
BRICK_COLS      equ 16
BRICK_WIDTH     equ 4
BRICK_START_Y   equ 3

section .bss
    quit_flag       resq 1
    game_over       resq 1
    game_won        resq 1
    
    paddle_x        resq 1
    
    ball_x          resq 1
    ball_y          resq 1
    ball_dx         resq 1
    ball_dy         resq 1
    ball_active     resq 1
    
    bricks          resb BRICK_ROWS * BRICK_COLS    ; 1 = exists, 0 = destroyed
    bricks_left     resq 1
    
    score           resq 1
    lives           resq 1
    tick_counter    resq 1

section .data
    title_str       db "=== BREAKOUT ===", 0
    score_str       db "Score: ", 0
    lives_str       db "Lives: ", 0
    gameover_str    db "GAME OVER - Press ENTER", 0
    win_str         db "YOU WIN! - Press ENTER", 0
    start_str       db "Press SPACE to launch", 0

section .text

;; =============================================================================
;; game_init
;; =============================================================================
game_init:
    sub rsp, 40
    
    call reset_game
    
    add rsp, 40
    ret

reset_game:
    push rbx
    push r12
    sub rsp, 32
    
    lea rax, [quit_flag]
    mov qword [rax], 0
    lea rax, [game_over]
    mov qword [rax], 0
    lea rax, [game_won]
    mov qword [rax], 0
    
    lea rax, [paddle_x]
    mov qword [rax], 36
    
    lea rax, [ball_active]
    mov qword [rax], 0
    
    lea rax, [score]
    mov qword [rax], 0
    lea rax, [lives]
    mov qword [rax], 3
    
    lea rax, [tick_counter]
    mov qword [rax], 0
    
    ;; Initialize bricks
    lea r12, [bricks]
    mov rbx, BRICK_ROWS * BRICK_COLS
.init_bricks:
    mov byte [r12], 1
    inc r12
    dec rbx
    jnz .init_bricks
    
    lea rax, [bricks_left]
    mov qword [rax], BRICK_ROWS * BRICK_COLS
    
    call reset_ball
    
    add rsp, 32
    pop r12
    pop rbx
    ret

reset_ball:
    lea rax, [paddle_x]
    mov rbx, [rax]
    add rbx, PADDLE_WIDTH / 2
    
    lea rax, [ball_x]
    mov [rax], rbx
    lea rax, [ball_y]
    mov qword [rax], PADDLE_Y - 1
    lea rax, [ball_dx]
    mov qword [rax], 1
    lea rax, [ball_dy]
    mov qword [rax], -1
    lea rax, [ball_active]
    mov qword [rax], 0
    ret

;; =============================================================================
;; game_update
;; =============================================================================
game_update:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 40
    
    ;; Check ESC
    mov rcx, 0x1B
    call input_was_pressed
    test rax, rax
    jz .no_quit
    lea rax, [quit_flag]
    mov qword [rax], 1
    jmp .done
.no_quit:

    ;; Game over / win state
    lea rax, [game_over]
    mov rbx, [rax]
    lea rax, [game_won]
    or rbx, [rax]
    test rbx, rbx
    jz .not_ended
    
    mov rcx, 0x0D               ; Enter
    call input_was_pressed
    test rax, rax
    jz .done
    call reset_game
    jmp .done
.not_ended:

    ;; Paddle movement (LEFT/RIGHT or A/D)
    mov rcx, 0x25               ; LEFT
    call input_is_down
    test rax, rax
    jnz .move_left
    mov rcx, 0x41               ; A
    call input_is_down
    test rax, rax
    jz .not_left
.move_left:
    lea rax, [paddle_x]
    cmp qword [rax], 1
    jle .not_left
    sub qword [rax], 2
.not_left:

    mov rcx, 0x27               ; RIGHT
    call input_is_down
    test rax, rax
    jnz .move_right
    mov rcx, 0x44               ; D
    call input_is_down
    test rax, rax
    jz .not_right
.move_right:
    lea rax, [paddle_x]
    mov rbx, [rax]
    add rbx, PADDLE_WIDTH
    cmp rbx, SCREEN_W - 1
    jge .not_right
    add qword [rax], 2
.not_right:

    ;; Launch ball with space
    lea rax, [ball_active]
    cmp qword [rax], 0
    jne .ball_is_active
    
    mov rcx, 0x20               ; SPACE
    call input_was_pressed
    test rax, rax
    jz .done
    lea rax, [ball_active]
    mov qword [rax], 1
    jmp .done
    
.ball_is_active:

    ;; Tick control
    lea rax, [tick_counter]
    inc qword [rax]
    mov rax, [rax]
    xor rdx, rdx
    mov rcx, 2
    div rcx
    test rdx, rdx
    jnz .done

    ;; Move ball
    lea rax, [ball_x]
    mov r12, [rax]
    lea rax, [ball_dx]
    add r12, [rax]
    
    lea rax, [ball_y]
    mov r13, [rax]
    lea rax, [ball_dy]
    add r13, [rax]
    
    ;; Wall collisions
    cmp r12, 1
    jg .not_left_wall
    lea rax, [ball_dx]
    neg qword [rax]
    mov r12, 1
.not_left_wall:

    cmp r12, SCREEN_W - 2
    jl .not_right_wall
    lea rax, [ball_dx]
    neg qword [rax]
    mov r12, SCREEN_W - 2
.not_right_wall:

    cmp r13, 1
    jg .not_top_wall
    lea rax, [ball_dy]
    neg qword [rax]
    mov r13, 1
.not_top_wall:

    ;; Bottom - lose life
    cmp r13, PADDLE_Y + 1
    jl .not_bottom
    
    lea rax, [lives]
    dec qword [rax]
    cmp qword [rax], 0
    jg .still_alive
    lea rax, [game_over]
    mov qword [rax], 1
    jmp .done
.still_alive:
    call reset_ball
    jmp .done
.not_bottom:

    ;; Paddle collision
    cmp r13, PADDLE_Y
    jne .not_paddle
    
    lea rax, [paddle_x]
    mov rbx, [rax]
    cmp r12, rbx
    jl .not_paddle
    add rbx, PADDLE_WIDTH
    cmp r12, rbx
    jge .not_paddle
    
    lea rax, [ball_dy]
    mov qword [rax], -1
    mov r13, PADDLE_Y - 1
.not_paddle:

    ;; Brick collision
    cmp r13, BRICK_START_Y
    jl .no_brick_hit
    cmp r13, BRICK_START_Y + BRICK_ROWS
    jge .no_brick_hit
    
    ;; Calculate brick position
    mov rax, r13
    sub rax, BRICK_START_Y      ; row
    mov r14, rax
    
    mov rax, r12
    sub rax, 4                  ; offset
    js .no_brick_hit
    xor rdx, rdx
    mov rcx, BRICK_WIDTH
    div rcx                     ; col
    cmp rax, BRICK_COLS
    jge .no_brick_hit
    
    ;; Calculate brick index: row * BRICK_COLS + col
    imul rbx, r14, BRICK_COLS
    add rbx, rax
    
    lea rax, [bricks]
    cmp byte [rax + rbx], 0
    je .no_brick_hit
    
    ;; Destroy brick
    mov byte [rax + rbx], 0
    lea rax, [bricks_left]
    dec qword [rax]
    lea rax, [score]
    add qword [rax], 10
    
    ;; Bounce
    lea rax, [ball_dy]
    neg qword [rax]
    
    ;; Check win
    lea rax, [bricks_left]
    cmp qword [rax], 0
    jg .no_brick_hit
    lea rax, [game_won]
    mov qword [rax], 1
    
.no_brick_hit:

    ;; Update ball position
    lea rax, [ball_x]
    mov [rax], r12
    lea rax, [ball_y]
    mov [rax], r13

.done:
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

;; =============================================================================
;; game_render
;; =============================================================================
game_render:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    
    ;; Title
    mov rcx, 32
    xor rdx, rdx
    lea r8, [title_str]
    call gfx_draw_text
    
    ;; Score
    mov rcx, 2
    mov rdx, 1
    lea r8, [score_str]
    call gfx_draw_text
    
    lea rax, [score]
    mov rax, [rax]
    ;; Simple 3-digit score display
    mov rcx, rax
    xor rdx, rdx
    mov rbx, 100
    div rbx
    add rax, '0'
    push rcx
    mov rcx, 9
    mov rdx, 1
    mov r8, rax
    call gfx_put_char
    pop rax
    
    xor rdx, rdx
    mov rbx, 10
    div rbx
    push rdx
    add rax, '0'
    mov rcx, 10
    mov rdx, 1
    mov r8, rax
    call gfx_put_char
    pop rax
    add rax, '0'
    mov rcx, 11
    mov rdx, 1
    mov r8, rax
    call gfx_put_char
    
    ;; Lives
    mov rcx, 65
    mov rdx, 1
    lea r8, [lives_str]
    call gfx_draw_text
    
    lea rax, [lives]
    mov rax, [rax]
    add rax, '0'
    mov rcx, 72
    mov rdx, 1
    mov r8, rax
    call gfx_put_char
    
    ;; Bricks
    xor r14, r14                ; row
.brick_row:
    cmp r14, BRICK_ROWS
    jge .bricks_done
    
    xor r15, r15                ; col
.brick_col:
    cmp r15, BRICK_COLS
    jge .next_row
    
    ;; Check if brick exists
    imul rax, r14, BRICK_COLS
    add rax, r15
    lea rbx, [bricks]
    cmp byte [rbx + rax], 0
    je .next_brick
    
    ;; Draw brick (4 chars wide)
    ;; Color based on row
    mov r8, r14
    add r8, 9                   ; Colors 9-12 (light colors)
    
    mov r12, r15
    imul r12, BRICK_WIDTH
    add r12, 4
    
    mov r13, r14
    add r13, BRICK_START_Y
    
    ;; Draw 4 characters
    xor rbx, rbx
.draw_brick_char:
    cmp rbx, BRICK_WIDTH
    jge .next_brick
    
    lea rcx, [r12 + rbx]
    mov rdx, r13
    push rbx
    push r8
    mov r8, '#'
    call gfx_put_char
    pop r8
    pop rbx
    
    inc rbx
    jmp .draw_brick_char
    
.next_brick:
    inc r15
    jmp .brick_col
    
.next_row:
    inc r14
    jmp .brick_row
    
.bricks_done:

    ;; Paddle
    lea rax, [paddle_x]
    mov r12, [rax]
    xor r13, r13
.draw_paddle:
    cmp r13, PADDLE_WIDTH
    jge .paddle_done
    
    lea rcx, [r12 + r13]
    mov rdx, PADDLE_Y
    mov r8, '='
    call gfx_put_char
    
    inc r13
    jmp .draw_paddle
.paddle_done:

    ;; Ball
    lea rax, [ball_active]
    cmp qword [rax], 0
    je .ball_on_paddle
    
    lea rax, [ball_x]
    mov rcx, [rax]
    lea rax, [ball_y]
    mov rdx, [rax]
    jmp .draw_ball
    
.ball_on_paddle:
    lea rax, [paddle_x]
    mov rcx, [rax]
    add rcx, PADDLE_WIDTH / 2
    mov rdx, PADDLE_Y - 1
    
.draw_ball:
    mov r8, 'O'
    call gfx_put_char
    
    ;; Messages
    lea rax, [ball_active]
    cmp qword [rax], 0
    jne .no_start_msg
    mov rcx, 28
    mov rdx, 20
    lea r8, [start_str]
    call gfx_draw_text
.no_start_msg:

    lea rax, [game_over]
    cmp qword [rax], 0
    je .no_gameover
    mov rcx, 27
    mov rdx, 12
    lea r8, [gameover_str]
    call gfx_draw_text
.no_gameover:

    lea rax, [game_won]
    cmp qword [rax], 0
    je .no_win
    mov rcx, 28
    mov rdx, 12
    lea r8, [win_str]
    call gfx_draw_text
.no_win:

    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

;; =============================================================================
;; game_should_quit
;; =============================================================================
game_should_quit:
    lea rax, [quit_flag]
    mov rax, [rax]
    ret
