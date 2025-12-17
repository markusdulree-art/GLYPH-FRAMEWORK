;; =============================================================================
;; GLYPH - Windows x86 (32-bit) Platform Entry Point
;; Platform: Windows x86 | Assembler: NASM | Linker: GCC (MinGW-w32)
;; =============================================================================
;; Main entry point and game loop for Windows 32-bit console backend.
;; Uses cdecl calling convention throughout.
;; =============================================================================

bits 32

;; Windows API Constants
STD_INPUT_HANDLE    equ -10
STD_OUTPUT_HANDLE   equ -11
ENABLE_WINDOW_INPUT equ 0x0008
ENABLE_EXTENDED_FLAGS equ 0x0080

;; Imports - Windows API (note: no underscore for Windows APIs with @N suffix)
extern _GetStdHandle@4
extern _SetConsoleMode@8
extern _GetConsoleMode@8
extern _SetConsoleTitleA@4
extern _SetConsoleCursorInfo@8
extern _ExitProcess@4
extern _Sleep@4

;; Imports - Core modules
extern _gfx_init
extern _gfx_clear
extern _gfx_present
extern _input_init
extern _input_begin_frame
extern _timing_init
extern _timing_frame_start
extern _timing_should_update
extern _timing_update

;; Imports - Platform modules
extern _console_init
extern _console_render
extern _console_poll_input

;; Imports - Game
extern _game_init
extern _game_update
extern _game_render
extern _game_should_quit

;; Exports
global __start
global _platform_shutdown
global _stdout_handle
global _stdin_handle

section .data
    window_title    db "GLYPH (32-bit)", 0
    cursor_info     dd 100, 0       ; Size=100%, Visible=false
    cursor_visible  dd 100, 1       ; Size=100%, Visible=true

section .bss
    _stdout_handle  resd 1
    _stdin_handle   resd 1
    original_mode   resd 1

section .text

;; =============================================================================
;; __start - Program entry point (no CRT)
;; =============================================================================
__start:
    ;; Get console handles
    push STD_OUTPUT_HANDLE
    call _GetStdHandle@4
    mov [_stdout_handle], eax

    push STD_INPUT_HANDLE
    call _GetStdHandle@4
    mov [_stdin_handle], eax

    ;; Save original console mode
    push original_mode
    push dword [_stdin_handle]
    call _GetConsoleMode@8

    ;; Set console title
    push window_title
    call _SetConsoleTitleA@4

    ;; Set input mode
    push ENABLE_EXTENDED_FLAGS | ENABLE_WINDOW_INPUT
    push dword [_stdin_handle]
    call _SetConsoleMode@8

    ;; Hide cursor
    call _hide_cursor

    ;; Initialize core systems
    call _gfx_init
    call _input_init
    call _timing_init

    ;; Initialize platform console
    call _console_init

    ;; Initialize game
    call _game_init

;; Main loop
.main_loop:
    call _timing_frame_start
    call _console_poll_input
    call _input_begin_frame

.update_loop:
    call _timing_should_update
    test eax, eax
    jz .render

    call _game_update
    call _timing_update
    jmp .update_loop

.render:
    call _gfx_clear
    call _game_render
    call _gfx_present
    call _console_render

    call _game_should_quit
    test eax, eax
    jnz .exit

    push 1
    call _Sleep@4

    jmp .main_loop

.exit:
    call _platform_shutdown
    push 0
    call _ExitProcess@4

;; =============================================================================
;; _platform_shutdown - Clean up before exit
;; =============================================================================
_platform_shutdown:
    push ebp
    mov ebp, esp

    push dword [original_mode]
    push dword [_stdin_handle]
    call _SetConsoleMode@8

    call _show_cursor

    pop ebp
    ret

;; =============================================================================
;; Cursor visibility helpers
;; =============================================================================
_hide_cursor:
    push cursor_info
    push dword [_stdout_handle]
    call _SetConsoleCursorInfo@8
    ret

_show_cursor:
    push cursor_visible
    push dword [_stdout_handle]
    call _SetConsoleCursorInfo@8
    ret
