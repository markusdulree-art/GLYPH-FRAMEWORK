;; GLYPH - Windows x64 Platform Entry Point
bits 64
default rel

STD_INPUT_HANDLE    equ -10
STD_OUTPUT_HANDLE   equ -11
ENABLE_WINDOW_INPUT equ 0x0008
ENABLE_EXTENDED_FLAGS equ 0x0080

extern GetStdHandle
extern SetConsoleMode
extern GetConsoleMode
extern SetConsoleTitleA
extern SetConsoleCursorInfo
extern ExitProcess
extern Sleep

extern gfx_init
extern gfx_clear
extern gfx_present
extern input_init
extern input_begin_frame
extern timing_init
extern timing_frame_start
extern timing_should_update
extern timing_update

extern console_init
extern console_render
extern console_poll_input

extern game_init
extern game_update
extern game_render
extern game_should_quit

global _start
global platform_shutdown
global stdout_handle
global stdin_handle

section .data
    window_title    db "GLYPH", 0
    cursor_info     dd 100, 0
    cursor_visible  dd 100, 1

section .bss
    stdout_handle   resq 1
    stdin_handle    resq 1
    original_mode   resd 1

section .text

_start:
    and rsp, -16
    sub rsp, 32
    
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    lea rbx, [stdout_handle]
    mov [rbx], rax
    
    mov ecx, STD_INPUT_HANDLE
    call GetStdHandle
    lea rbx, [stdin_handle]
    mov [rbx], rax
    
    lea rbx, [stdin_handle]
    mov rcx, [rbx]
    lea rdx, [original_mode]
    call GetConsoleMode
    
    lea rcx, [window_title]
    call SetConsoleTitleA
    
    lea rbx, [stdin_handle]
    mov rcx, [rbx]
    mov edx, ENABLE_EXTENDED_FLAGS | ENABLE_WINDOW_INPUT
    call SetConsoleMode
    
    call hide_cursor
    
    call gfx_init
    call input_init
    call timing_init
    call console_init
    call game_init
    
.main_loop:
    call timing_frame_start
    call console_poll_input
    call input_begin_frame
    
.update_loop:
    call timing_should_update
    test eax, eax
    jz .render
    call game_update
    call timing_update
    jmp .update_loop
    
.render:
    call gfx_clear
    call game_render
    call gfx_present
    call console_render
    
    call game_should_quit
    test eax, eax
    jnz .exit
    
    mov ecx, 1
    call Sleep
    jmp .main_loop
    
.exit:
    call platform_shutdown
    xor ecx, ecx
    call ExitProcess

platform_shutdown:
    sub rsp, 40
    lea rbx, [stdin_handle]
    mov rcx, [rbx]
    lea rax, [original_mode]
    mov edx, [rax]
    call SetConsoleMode
    call show_cursor
    add rsp, 40
    ret

hide_cursor:
    sub rsp, 40
    lea rbx, [stdout_handle]
    mov rcx, [rbx]
    lea rdx, [cursor_info]
    call SetConsoleCursorInfo
    add rsp, 40
    ret

show_cursor:
    sub rsp, 40
    lea rbx, [stdout_handle]
    mov rcx, [rbx]
    lea rdx, [cursor_visible]
    call SetConsoleCursorInfo
    add rsp, 40
    ret
