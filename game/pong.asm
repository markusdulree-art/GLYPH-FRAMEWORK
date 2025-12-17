;; =============================================================================
;; GLYPH - Pong Game Example (64-bit)
;; Platform: Windows x64 | Assembler: NASM | Linker: GCC
;; =============================================================================
;; Classic Pong - single player vs CPU
;; =============================================================================

bits 64
default rel

extern gfx_put_char
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
PADDLE_HEIGHT   equ 5
PADDLE_X_LEFT   equ 2
PADDLE_X_RIGHT  equ 77
BALL_SPEED      equ 1

section .bss
    quit_flag       resq 1
    
    ;; Paddles (Y position = top of paddle)
    paddle_left_y   resq 1
    paddle_right_y  resq 1
    
    ;; Ball
    ball_x          resq 1
    ball_y          resq 1
    ball_dx         resq 1      ; -1 or 1
    ball_dy         resq 1      ; -1, 0, or 1
    
    ;; Scores
    score_left      resq 1
    score_right     resq 1
    
    ;; Timing
    tick_counter    resq 1

section .data
    title_str       db "=== PONG ===", 0
    score_sep       db " - ", 0
    controls_str    db "W/S: Move | ESC: Quit", 0

section .text

;; =============================================================================
;; game_init
;; =============================================================================
game_init:
    sub rsp, 40
    
    lea rax, [quit_flag]
    mov qword [rax], 0
    
    ;; Center paddles
    lea rax, [paddle_left_y]
    mov qword [rax], 10
    lea rax, [paddle_right_y]
    mov qword [rax], 10
    
    ;; Center ball
    call reset_ball
    
    ;; Reset scores
    lea rax, [score_left]
    mov qword [rax], 0
    lea rax, [score_right]
    mov qword [rax], 0
    
    lea rax, [tick_counter]
    mov qword [rax], 0
    
    add rsp, 40
    ret

reset_ball:
    lea rax, [ball_x]
    mov qword [rax], 40
    lea rax, [ball_y]
    mov qword [rax], 12
    lea rax, [ball_dx]
    mov qword [rax], 1
    lea rax, [ball_dy]
    mov qword [rax], 0
    ret

;; =============================================================================
;; game_update
;; =============================================================================
game_update:
    push rbx
    push r12
    push r13
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

    ;; Player paddle (W/S)
    mov rcx, 0x57               ; W
    call input_is_down
    test rax, rax
    jz .not_up
    lea rax, [paddle_left_y]
    mov rbx, [rax]
    cmp rbx, 2
    jle .not_up
    dec qword [rax]
.not_up:

    mov rcx, 0x53               ; S
    call input_is_down
    test rax, rax
    jz .not_down
    lea rax, [paddle_left_y]
    mov rbx, [rax]
    add rbx, PADDLE_HEIGHT
    cmp rbx, SCREEN_H - 1
    jge .not_down
    inc qword [rax]
.not_down:

    ;; Tick control
    lea rax, [tick_counter]
    inc qword [rax]
    mov rax, [rax]
    xor rdx, rdx
    mov rcx, 3
    div rcx
    test rdx, rdx
    jnz .done

    ;; CPU paddle AI (follows ball)
    lea rax, [ball_y]
    mov r12, [rax]
    lea rax, [paddle_right_y]
    mov r13, [rax]
    add r13, PADDLE_HEIGHT / 2
    
    cmp r12, r13
    je .cpu_done
    jl .cpu_up
    
    ;; CPU down
    lea rax, [paddle_right_y]
    mov rbx, [rax]
    add rbx, PADDLE_HEIGHT
    cmp rbx, SCREEN_H - 1
    jge .cpu_done
    inc qword [rax]
    jmp .cpu_done
    
.cpu_up:
    lea rax, [paddle_right_y]
    cmp qword [rax], 2
    jle .cpu_done
    dec qword [rax]
    
.cpu_done:

    ;; Move ball
    lea rax, [ball_x]
    mov r12, [rax]
    lea rax, [ball_dx]
    add r12, [rax]
    lea rax, [ball_x]
    mov [rax], r12
    
    lea rax, [ball_y]
    mov r13, [rax]
    lea rax, [ball_dy]
    add r13, [rax]
    lea rax, [ball_y]
    mov [rax], r13
    
    ;; Top/bottom bounce
    cmp r13, 2
    jg .not_top
    lea rax, [ball_dy]
    neg qword [rax]
    lea rax, [ball_y]
    mov qword [rax], 2
.not_top:
    cmp r13, SCREEN_H - 2
    jl .not_bottom
    lea rax, [ball_dy]
    neg qword [rax]
    lea rax, [ball_y]
    mov qword [rax], SCREEN_H - 2
.not_bottom:

    ;; Left paddle collision
    cmp r12, PADDLE_X_LEFT + 1
    jne .not_left_paddle
    
    lea rax, [paddle_left_y]
    mov rbx, [rax]
    cmp r13, rbx
    jl .score_right
    add rbx, PADDLE_HEIGHT
    cmp r13, rbx
    jge .score_right
    
    ;; Bounce
    lea rax, [ball_dx]
    mov qword [rax], 1
    
    ;; Add spin based on where it hit
    lea rax, [paddle_left_y]
    mov rbx, [rax]
    add rbx, PADDLE_HEIGHT / 2
    sub r13, rbx
    lea rax, [ball_dy]
    mov [rax], r13
    jmp .not_left_paddle
    
.score_right:
    cmp r12, 1
    jg .not_left_paddle
    lea rax, [score_right]
    inc qword [rax]
    call reset_ball
    jmp .done
    
.not_left_paddle:

    ;; Right paddle collision
    cmp r12, PADDLE_X_RIGHT - 1
    jne .not_right_paddle
    
    lea rax, [paddle_right_y]
    mov rbx, [rax]
    cmp r13, rbx
    jl .score_left
    add rbx, PADDLE_HEIGHT
    cmp r13, rbx
    jge .score_left
    
    ;; Bounce
    lea rax, [ball_dx]
    mov qword [rax], -1
    jmp .not_right_paddle
    
.score_left:
    cmp r12, SCREEN_W - 2
    jl .not_right_paddle
    lea rax, [score_left]
    inc qword [rax]
    call reset_ball
    
.not_right_paddle:

.done:
    add rsp, 40
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
    sub rsp, 40
    
    ;; Title
    mov rcx, 34
    xor rdx, rdx
    lea r8, [title_str]
    call gfx_draw_text
    
    ;; Scores
    lea rax, [score_left]
    mov rax, [rax]
    add rax, '0'
    mov rcx, 38
    mov rdx, 1
    mov r8, rax
    call gfx_put_char
    
    mov rcx, 39
    mov rdx, 1
    lea r8, [score_sep]
    call gfx_draw_text
    
    lea rax, [score_right]
    mov rax, [rax]
    add rax, '0'
    mov rcx, 42
    mov rdx, 1
    mov r8, rax
    call gfx_put_char
    
    ;; Controls
    mov rcx, 28
    mov rdx, 24
    lea r8, [controls_str]
    call gfx_draw_text
    
    ;; Left paddle
    lea rax, [paddle_left_y]
    mov r12, [rax]
    xor r13, r13
.left_paddle:
    cmp r13, PADDLE_HEIGHT
    jge .left_done
    mov rcx, PADDLE_X_LEFT
    lea rdx, [r12 + r13]
    mov r8, '|'
    call gfx_put_char
    inc r13
    jmp .left_paddle
.left_done:

    ;; Right paddle
    lea rax, [paddle_right_y]
    mov r12, [rax]
    xor r13, r13
.right_paddle:
    cmp r13, PADDLE_HEIGHT
    jge .right_done
    mov rcx, PADDLE_X_RIGHT
    lea rdx, [r12 + r13]
    mov r8, '|'
    call gfx_put_char
    inc r13
    jmp .right_paddle
.right_done:

    ;; Ball
    lea rax, [ball_x]
    mov rcx, [rax]
    lea rax, [ball_y]
    mov rdx, [rax]
    mov r8, 'O'
    call gfx_put_char
    
    ;; Center line (dashed)
    mov r12, 2
.center_line:
    cmp r12, SCREEN_H - 1
    jge .center_done
    mov rcx, 40
    mov rdx, r12
    mov r8, ':'
    call gfx_put_char
    add r12, 2
    jmp .center_line
.center_done:

    add rsp, 40
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
