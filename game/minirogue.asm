;; =============================================================================
;; GLYPH - MiniRogue Game Example (64-bit)
;; Platform: Windows x64 | Assembler: NASM | Linker: GCC
;; =============================================================================
;; Simple roguelike dungeon crawler
;; =============================================================================

bits 64
default rel

extern gfx_put_char
extern gfx_put_cell
extern gfx_draw_text
extern input_was_pressed

global game_init
global game_update
global game_render
global game_should_quit

;; Constants
MAP_W           equ 60
MAP_H           equ 20
MAP_OFFSET_X    equ 10
MAP_OFFSET_Y    equ 2

TILE_FLOOR      equ '.'
TILE_WALL       equ '#'
TILE_PLAYER     equ '@'
TILE_ENEMY      equ 'E'
TILE_GOLD       equ '$'
TILE_EXIT       equ '>'

COLOR_FLOOR     equ 8       ; Dark gray
COLOR_WALL      equ 7       ; Light gray  
COLOR_PLAYER    equ 14      ; Yellow
COLOR_ENEMY     equ 12      ; Light red
COLOR_GOLD      equ 14      ; Yellow
COLOR_EXIT      equ 10      ; Light green

MAX_ENEMIES     equ 5
MAX_GOLD        equ 10

section .bss
    quit_flag       resq 1
    game_over       resq 1
    game_won        resq 1
    
    player_x        resq 1
    player_y        resq 1
    player_hp       resq 1
    player_gold     resq 1
    
    ;; Map: 1 = wall, 0 = floor
    map_data        resb MAP_W * MAP_H
    
    ;; Enemies: x, y, alive (3 qwords each)
    enemy_x         resq MAX_ENEMIES
    enemy_y         resq MAX_ENEMIES
    enemy_alive     resq MAX_ENEMIES
    
    ;; Gold: x, y, exists
    gold_x          resq MAX_GOLD
    gold_y          resq MAX_GOLD
    gold_exists     resq MAX_GOLD
    
    exit_x          resq 1
    exit_y          resq 1
    
    level           resq 1
    rand_seed       resq 1
    message         resb 64
    msg_timer       resq 1

section .data
    title_str       db "=== MINIROGUE ===", 0
    hp_str          db "HP: ", 0
    gold_str        db "Gold: ", 0
    level_str       db "Level: ", 0
    controls_str    db "Arrow Keys: Move | ESC: Quit", 0
    win_str         db "You escaped! Press ENTER", 0
    dead_str        db "You died! Press ENTER", 0
    hit_msg         db "Ouch! -1 HP", 0
    gold_msg        db "Found gold!", 0

section .text

;; =============================================================================
;; game_init
;; =============================================================================
game_init:
    sub rsp, 40
    
    lea rax, [rand_seed]
    mov qword [rax], 31337
    lea rax, [level]
    mov qword [rax], 1
    
    call generate_level
    
    add rsp, 40
    ret

;; Simple RNG
random:
    lea rax, [rand_seed]
    mov rax, [rax]
    imul rax, 1103515245
    add rax, 12345
    lea rbx, [rand_seed]
    mov [rbx], rax
    shr rax, 16
    ret

generate_level:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    
    lea rax, [quit_flag]
    mov qword [rax], 0
    lea rax, [game_over]
    mov qword [rax], 0
    lea rax, [game_won]
    mov qword [rax], 0
    lea rax, [msg_timer]
    mov qword [rax], 0
    
    ;; Fill map with walls
    lea rdi, [map_data]
    mov rcx, MAP_W * MAP_H
.fill_walls:
    mov byte [rdi], 1
    inc rdi
    dec rcx
    jnz .fill_walls
    
    ;; Carve out rooms (simple random rectangles)
    mov r15, 8                  ; Number of rooms
.carve_rooms:
    ;; Random room position
    call random
    xor rdx, rdx
    mov rcx, MAP_W - 12
    div rcx
    add rdx, 2
    mov r12, rdx                ; room_x
    
    call random
    xor rdx, rdx
    mov rcx, MAP_H - 8
    div rcx
    add rdx, 2
    mov r13, rdx                ; room_y
    
    ;; Random room size
    call random
    xor rdx, rdx
    mov rcx, 6
    div rcx
    add rdx, 4
    mov r14, rdx                ; room_w
    
    call random
    xor rdx, rdx
    mov rcx, 4
    div rcx
    add rdx, 3
    push r14
    mov r14, rdx                ; room_h
    pop rbx                     ; room_w in rbx
    
    ;; Carve room
    xor rcx, rcx                ; y offset
.room_y:
    cmp rcx, r14
    jge .room_done
    
    xor rdx, rdx                ; x offset
.room_x:
    cmp rdx, rbx
    jge .next_room_y
    
    ;; Calculate map index
    mov rax, r13
    add rax, rcx
    imul rax, MAP_W
    add rax, r12
    add rax, rdx
    
    ;; Set to floor
    lea rdi, [map_data]
    mov byte [rdi + rax], 0
    
    inc rdx
    jmp .room_x
    
.next_room_y:
    inc rcx
    jmp .room_y
    
.room_done:
    dec r15
    jnz .carve_rooms
    
    ;; Place player
.find_player_spot:
    call random
    xor rdx, rdx
    mov rcx, MAP_W - 4
    div rcx
    add rdx, 2
    mov r12, rdx
    
    call random
    xor rdx, rdx
    mov rcx, MAP_H - 4
    div rcx
    add rdx, 2
    mov r13, rdx
    
    ;; Check if floor
    mov rax, r13
    imul rax, MAP_W
    add rax, r12
    lea rdi, [map_data]
    cmp byte [rdi + rax], 0
    jne .find_player_spot
    
    lea rax, [player_x]
    mov [rax], r12
    lea rax, [player_y]
    mov [rax], r13
    lea rax, [player_hp]
    mov qword [rax], 10
    lea rax, [player_gold]
    mov qword [rax], 0
    
    ;; Place exit (far from player)
.find_exit_spot:
    call random
    xor rdx, rdx
    mov rcx, MAP_W - 4
    div rcx
    add rdx, 2
    mov r12, rdx
    
    call random
    xor rdx, rdx
    mov rcx, MAP_H - 4
    div rcx
    add rdx, 2
    mov r13, rdx
    
    ;; Check if floor and far from player
    mov rax, r13
    imul rax, MAP_W
    add rax, r12
    lea rdi, [map_data]
    cmp byte [rdi + rax], 0
    jne .find_exit_spot
    
    ;; Check distance from player
    lea rax, [player_x]
    mov rax, [rax]
    sub rax, r12
    imul rax, rax
    mov rbx, rax
    lea rax, [player_y]
    mov rax, [rax]
    sub rax, r13
    imul rax, rax
    add rbx, rax
    cmp rbx, 100                ; min distance squared
    jl .find_exit_spot
    
    lea rax, [exit_x]
    mov [rax], r12
    lea rax, [exit_y]
    mov [rax], r13
    
    ;; Place enemies
    xor r15, r15
.place_enemies:
    cmp r15, MAX_ENEMIES
    jge .enemies_done
    
.find_enemy_spot:
    call random
    xor rdx, rdx
    mov rcx, MAP_W - 4
    div rcx
    add rdx, 2
    mov r12, rdx
    
    call random
    xor rdx, rdx
    mov rcx, MAP_H - 4
    div rcx
    add rdx, 2
    mov r13, rdx
    
    mov rax, r13
    imul rax, MAP_W
    add rax, r12
    lea rdi, [map_data]
    cmp byte [rdi + rax], 0
    jne .find_enemy_spot
    
    ;; Check not on player
    lea rax, [player_x]
    cmp r12, [rax]
    jne .enemy_ok
    lea rax, [player_y]
    cmp r13, [rax]
    je .find_enemy_spot
    
.enemy_ok:
    lea rax, [enemy_x]
    mov [rax + r15*8], r12
    lea rax, [enemy_y]
    mov [rax + r15*8], r13
    lea rax, [enemy_alive]
    mov qword [rax + r15*8], 1
    
    inc r15
    jmp .place_enemies
.enemies_done:

    ;; Place gold
    xor r15, r15
.place_gold:
    cmp r15, MAX_GOLD
    jge .gold_done
    
.find_gold_spot:
    call random
    xor rdx, rdx
    mov rcx, MAP_W - 4
    div rcx
    add rdx, 2
    mov r12, rdx
    
    call random
    xor rdx, rdx
    mov rcx, MAP_H - 4
    div rcx
    add rdx, 2
    mov r13, rdx
    
    mov rax, r13
    imul rax, MAP_W
    add rax, r12
    lea rdi, [map_data]
    cmp byte [rdi + rax], 0
    jne .find_gold_spot
    
    lea rax, [gold_x]
    mov [rax + r15*8], r12
    lea rax, [gold_y]
    mov [rax + r15*8], r13
    lea rax, [gold_exists]
    mov qword [rax + r15*8], 1
    
    inc r15
    jmp .place_gold
.gold_done:

    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

;; =============================================================================
;; game_update
;; =============================================================================
game_update:
    push rbx
    push r12
    push r13
    sub rsp, 40
    
    ;; Decrement message timer
    lea rax, [msg_timer]
    cmp qword [rax], 0
    je .no_msg_dec
    dec qword [rax]
.no_msg_dec:
    
    ;; Check ESC
    mov rcx, 0x1B
    call input_was_pressed
    test rax, rax
    jz .no_quit
    lea rax, [quit_flag]
    mov qword [rax], 1
    jmp .done
.no_quit:

    ;; Game over states
    lea rax, [game_over]
    mov rbx, [rax]
    lea rax, [game_won]
    or rbx, [rax]
    test rbx, rbx
    jz .not_ended
    
    mov rcx, 0x0D
    call input_was_pressed
    test rax, rax
    jz .done
    
    ;; Next level or restart
    lea rax, [game_won]
    cmp qword [rax], 0
    je .restart
    lea rax, [level]
    inc qword [rax]
    cmp qword [rax], 5
    jg .final_win
    call generate_level
    jmp .done
.final_win:
    lea rax, [level]
    mov qword [rax], 1
.restart:
    call generate_level
    jmp .done
.not_ended:

    ;; Movement
    lea rax, [player_x]
    mov r12, [rax]
    lea rax, [player_y]
    mov r13, [rax]
    
    mov rcx, 0x26               ; UP
    call input_was_pressed
    test rax, rax
    jz .not_up
    dec r13
    jmp .try_move
.not_up:

    mov rcx, 0x28               ; DOWN
    call input_was_pressed
    test rax, rax
    jz .not_down
    inc r13
    jmp .try_move
.not_down:

    mov rcx, 0x25               ; LEFT
    call input_was_pressed
    test rax, rax
    jz .not_left
    dec r12
    jmp .try_move
.not_left:

    mov rcx, 0x27               ; RIGHT
    call input_was_pressed
    test rax, rax
    jz .done
    inc r12

.try_move:
    ;; Bounds check
    cmp r12, 0
    jl .done
    cmp r12, MAP_W
    jge .done
    cmp r13, 0
    jl .done
    cmp r13, MAP_H
    jge .done
    
    ;; Wall check
    mov rax, r13
    imul rax, MAP_W
    add rax, r12
    lea rdi, [map_data]
    cmp byte [rdi + rax], 1
    je .done
    
    ;; Move player
    lea rax, [player_x]
    mov [rax], r12
    lea rax, [player_y]
    mov [rax], r13
    
    ;; Check exit
    lea rax, [exit_x]
    cmp r12, [rax]
    jne .not_exit
    lea rax, [exit_y]
    cmp r13, [rax]
    jne .not_exit
    lea rax, [game_won]
    mov qword [rax], 1
    jmp .done
.not_exit:

    ;; Check gold collision
    xor rbx, rbx
.check_gold:
    cmp rbx, MAX_GOLD
    jge .gold_check_done
    
    lea rax, [gold_exists]
    cmp qword [rax + rbx*8], 0
    je .next_gold
    
    lea rax, [gold_x]
    cmp r12, [rax + rbx*8]
    jne .next_gold
    lea rax, [gold_y]
    cmp r13, [rax + rbx*8]
    jne .next_gold
    
    ;; Collect gold
    lea rax, [gold_exists]
    mov qword [rax + rbx*8], 0
    lea rax, [player_gold]
    inc qword [rax]
    
    ;; Message
    lea rax, [msg_timer]
    mov qword [rax], 60
    
.next_gold:
    inc rbx
    jmp .check_gold
.gold_check_done:

    ;; Check enemy collision
    xor rbx, rbx
.check_enemy:
    cmp rbx, MAX_ENEMIES
    jge .done
    
    lea rax, [enemy_alive]
    cmp qword [rax + rbx*8], 0
    je .next_enemy
    
    lea rax, [enemy_x]
    cmp r12, [rax + rbx*8]
    jne .next_enemy
    lea rax, [enemy_y]
    cmp r13, [rax + rbx*8]
    jne .next_enemy
    
    ;; Hit enemy - both take damage
    lea rax, [enemy_alive]
    mov qword [rax + rbx*8], 0
    lea rax, [player_hp]
    dec qword [rax]
    
    lea rax, [msg_timer]
    mov qword [rax], 60
    
    ;; Check death
    lea rax, [player_hp]
    cmp qword [rax], 0
    jg .next_enemy
    lea rax, [game_over]
    mov qword [rax], 1
    
.next_enemy:
    inc rbx
    jmp .check_enemy

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
    push r14
    push r15
    sub rsp, 40
    
    ;; Title
    mov rcx, 31
    xor rdx, rdx
    lea r8, [title_str]
    call gfx_draw_text
    
    ;; Stats
    mov rcx, 2
    mov rdx, 23
    lea r8, [hp_str]
    call gfx_draw_text
    
    lea rax, [player_hp]
    mov rax, [rax]
    add rax, '0'
    mov rcx, 6
    mov rdx, 23
    mov r8, rax
    call gfx_put_char
    
    mov rcx, 15
    mov rdx, 23
    lea r8, [gold_str]
    call gfx_draw_text
    
    lea rax, [player_gold]
    mov rax, [rax]
    add rax, '0'
    mov rcx, 21
    mov rdx, 23
    mov r8, rax
    call gfx_put_char
    
    mov rcx, 30
    mov rdx, 23
    lea r8, [level_str]
    call gfx_draw_text
    
    lea rax, [level]
    mov rax, [rax]
    add rax, '0'
    mov rcx, 37
    mov rdx, 23
    mov r8, rax
    call gfx_put_char
    
    mov rcx, 45
    mov rdx, 23
    lea r8, [controls_str]
    call gfx_draw_text
    
    ;; Draw map
    xor r14, r14                ; y
.draw_map_y:
    cmp r14, MAP_H
    jge .map_done
    
    xor r15, r15                ; x
.draw_map_x:
    cmp r15, MAP_W
    jge .next_map_y
    
    mov rax, r14
    imul rax, MAP_W
    add rax, r15
    lea rdi, [map_data]
    movzx ebx, byte [rdi + rax]
    
    lea rcx, [r15 + MAP_OFFSET_X]
    lea rdx, [r14 + MAP_OFFSET_Y]
    
    test ebx, ebx
    jz .draw_floor
    mov r8, TILE_WALL
    jmp .draw_tile
.draw_floor:
    mov r8, TILE_FLOOR
.draw_tile:
    call gfx_put_char
    
    inc r15
    jmp .draw_map_x
    
.next_map_y:
    inc r14
    jmp .draw_map_y
.map_done:

    ;; Draw exit
    lea rax, [exit_x]
    mov rcx, [rax]
    add rcx, MAP_OFFSET_X
    lea rax, [exit_y]
    mov rdx, [rax]
    add rdx, MAP_OFFSET_Y
    mov r8, TILE_EXIT
    call gfx_put_char
    
    ;; Draw gold
    xor r12, r12
.draw_gold:
    cmp r12, MAX_GOLD
    jge .gold_draw_done
    
    lea rax, [gold_exists]
    cmp qword [rax + r12*8], 0
    je .next_gold_draw
    
    lea rax, [gold_x]
    mov rcx, [rax + r12*8]
    add rcx, MAP_OFFSET_X
    lea rax, [gold_y]
    mov rdx, [rax + r12*8]
    add rdx, MAP_OFFSET_Y
    mov r8, TILE_GOLD
    call gfx_put_char
    
.next_gold_draw:
    inc r12
    jmp .draw_gold
.gold_draw_done:

    ;; Draw enemies
    xor r12, r12
.draw_enemies:
    cmp r12, MAX_ENEMIES
    jge .enemies_draw_done
    
    lea rax, [enemy_alive]
    cmp qword [rax + r12*8], 0
    je .next_enemy_draw
    
    lea rax, [enemy_x]
    mov rcx, [rax + r12*8]
    add rcx, MAP_OFFSET_X
    lea rax, [enemy_y]
    mov rdx, [rax + r12*8]
    add rdx, MAP_OFFSET_Y
    mov r8, TILE_ENEMY
    call gfx_put_char
    
.next_enemy_draw:
    inc r12
    jmp .draw_enemies
.enemies_draw_done:

    ;; Draw player
    lea rax, [player_x]
    mov rcx, [rax]
    add rcx, MAP_OFFSET_X
    lea rax, [player_y]
    mov rdx, [rax]
    add rdx, MAP_OFFSET_Y
    mov r8, TILE_PLAYER
    call gfx_put_char
    
    ;; Messages
    lea rax, [game_over]
    cmp qword [rax], 0
    je .no_dead_msg
    mov rcx, 27
    mov rdx, 12
    lea r8, [dead_str]
    call gfx_draw_text
.no_dead_msg:

    lea rax, [game_won]
    cmp qword [rax], 0
    je .no_win_msg
    mov rcx, 26
    mov rdx, 12
    lea r8, [win_str]
    call gfx_draw_text
.no_win_msg:

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
