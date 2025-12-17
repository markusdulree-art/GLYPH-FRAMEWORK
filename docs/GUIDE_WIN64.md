# GLYPH Developer Guide — Windows x64

> Platform: Windows 64-bit
> Architecture: x86-64 (AMD64)
> Assembler: NASM
> Linker: GCC (MinGW-w64)


---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture Overview](#architecture-overview)
3. [Windows x64 Calling Convention](#windows-x64-calling-convention)
4. [Register Reference](#register-reference)
5. [Function Patterns](#function-patterns)
6. [Graphics API](#graphics-api)
7. [Input API](#input-api)
8. [Timing API](#timing-api)
9. [Writing Your First Game](#writing-your-first-game)
10. [Memory Layout](#memory-layout)
11. [Common Patterns](#common-patterns)
12. [Debugging Tips](#debugging-tips)
13. [API Reference](#api-reference)

---

## Quick Start

### Prerequisites

| Tool | Version | Download |
|------|---------|----------|
| NASM | 2.15+ | [nasm.us](https://nasm.us/) |
| GCC | MinGW-w64 | [mingw-w64.org](https://www.mingw-w64.org/) |

### Build & Run

```batch
cd glyph
.\build.bat
.\build\glyph.exe
```

### Controls (Snake Demo)

| Key | Action |
|-----|--------|
| ↑ ↓ ← → | Move snake |
| Space | Pause/Resume |
| Enter | Restart (after game over) |
| Escape | Quit |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      YOUR GAME                              │
│                    (game/*.asm)                             │
└──────────────────────────┬──────────────────────────────────┘
                           │ calls
┌──────────────────────────▼──────────────────────────────────┐
│                     CORE LAYER                              │
│              (Portable, No OS Calls)                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │ frame.asm   │ │ input.asm   │ │ timing.asm  │            │
│  │ Framebuffer │ │ Key States  │ │ Fixed Step  │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
└──────────────────────────┬──────────────────────────────────┘
                           │ calls
┌──────────────────────────▼──────────────────────────────────┐
│                   PLATFORM LAYER                            │
│                 (Windows x64 Specific)                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │ entry.asm   │ │ console.asm │ │ timing.asm  │            │
│  │ Main Loop   │ │ Rendering   │ │ QPC Timer   │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
└──────────────────────────┬──────────────────────────────────┘
                           │ syscalls
┌──────────────────────────▼──────────────────────────────────┐
│                   WINDOWS KERNEL                            │
│         kernel32.dll, user32.dll                            │
└─────────────────────────────────────────────────────────────┘
```

### The Golden Rule

| Layer | Knows About | Never Touches |
|-------|-------------|---------------|
| **Core** | Nothing platform-specific | Any OS API |
| **Platform** | Windows APIs only | Your game logic |
| **Game** | Core API only | Platform internals |

---

## Windows x64 Calling Convention

This is **critical** knowledge for writing correct assembly.

### Argument Passing

| Argument | Register | Size |
|----------|----------|------|
| 1st | RCX | 64-bit |
| 2nd | RDX | 64-bit |
| 3rd | R8 | 64-bit |
| 4th | R9 | 64-bit |
| 5th+ | Stack | 64-bit each |

### Return Value

| Location | Usage |
|----------|-------|
| RAX | Integer/pointer return |
| XMM0 | Floating point return |

### Shadow Space (MANDATORY!)

**Every function call requires 32 bytes of "shadow space"** reserved on the stack, even if passing fewer than 4 arguments.

```asm
sub rsp, 32         ; Reserve shadow space
call SomeFunction
add rsp, 32         ; Clean up (or leave if making more calls)
```

### Stack Alignment

The stack **MUST** be 16-byte aligned before any `call` instruction.

```
Before call:  RSP mod 16 = 0
After call:   RSP mod 16 = 8 (return address pushed)
```

### Register Preservation

| Volatile (Caller-Saved) | Non-Volatile (Callee-Saved) |
|------------------------|----------------------------|
| RAX, RCX, RDX | RBX, RBP |
| R8, R9, R10, R11 | RDI, RSI |
| XMM0-XMM5 | R12, R13, R14, R15 |

**Volatile**: Function can destroy these. Caller must save if needed.
**Non-Volatile**: Function must preserve these. Restore before returning.

---

## Register Reference

### Logical Mapping (GLYPH Convention)

| Logical | Physical | Purpose |
|---------|----------|---------|
| A0 | RCX | Argument 0 |
| A1 | RDX | Argument 1 |
| A2 | R8 | Argument 2 |
| A3 | R9 | Argument 3 |
| R0 | RAX | Return value |
| TMP0 | R10 | Scratch (volatile) |
| TMP1 | R11 | Scratch (volatile) |

### Size Variants

| 64-bit | 32-bit | 16-bit | 8-bit |
|--------|--------|--------|-------|
| RAX | EAX | AX | AL |
| RCX | ECX | CX | CL |
| RDX | EDX | DX | DL |
| R8 | R8D | R8W | R8B |

### Safe Registers for Loops

Use **non-volatile** registers for loop counters and persistent state:

```asm
push r12            ; Save
push r13

mov r12, 0          ; Loop counter
mov r13, 100        ; Loop limit

.loop:
    ; ... do work (can make calls here safely) ...
    inc r12
    cmp r12, r13
    jl .loop

pop r13             ; Restore
pop r12
```

---

## Function Patterns

### Minimal Function (No Calls)

```asm
my_function:
    ; Just compute and return
    mov rax, rcx        ; Return first arg
    ret
```

### Standard Function (Makes Calls)

```asm
my_function:
    sub rsp, 40         ; 32 shadow + 8 alignment

    mov rcx, some_arg   ; Set up arguments
    call other_function

    add rsp, 40
    ret
```

### Function with Preserved Registers

```asm
my_function:
    push rbx            ; Save non-volatiles
    push r12
    sub rsp, 40

    mov rbx, rcx        ; Store arg in safe register
    mov r12, rdx

    ; ... make calls, use rbx and r12 freely ...

    add rsp, 40
    pop r12             ; Restore in reverse order
    pop rbx
    ret
```

### Stack Math Cheat Sheet

```
Pushes:           Stack adjustment:
0 pushes          sub rsp, 40    (32 shadow + 8 align)
1 push            sub rsp, 32    (32 shadow, push aligned)
2 pushes          sub rsp, 40    (32 shadow + 8 align)
3 pushes          sub rsp, 32    
```

---

## Graphics API

### Framebuffer Concepts

The screen is an 80×25 grid of **cells**. Each cell is 4 bytes:

```
┌─────────┬──────────┬──────────┬─────────┐
│ Glyph   │ FG Color │ BG Color │ Flags   │
│ (1 byte)│ (1 byte) │ (1 byte) │ (1 byte)│
└─────────┴──────────┴──────────┴─────────┘
```

### Double Buffering

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ Back Buffer  │ ──▶  │ Front Buffer │ ──▶  │   Screen     │
│ (You write)  │      │ (Comparison) │      │  (Display)   │
└──────────────┘      └──────────────┘      └──────────────┘
     gfx_put_*            gfx_present          console_render
```

### Color Palette

| Code | Color | Code | Color |
|------|-------|------|-------|
| 0 | Black | 8 | Dark Gray |
| 1 | Blue | 9 | Light Blue |
| 2 | Green | 10 | Light Green |
| 3 | Cyan | 11 | Light Cyan |
| 4 | Red | 12 | Light Red |
| 5 | Magenta | 13 | Light Magenta |
| 6 | Brown | 14 | Yellow |
| 7 | Light Gray | 15 | White |

### Functions

#### `gfx_clear`
Clear the back buffer to spaces with default colors.

```asm
call gfx_clear
```

#### `gfx_put_char`
Draw a character at (x, y) with default colors.

```asm
mov rcx, 10         ; x position (0-79)
mov rdx, 5          ; y position (0-24)
mov r8, '@'         ; character
call gfx_put_char
```

#### `gfx_draw_text`
Draw a null-terminated string.

```asm
section .data
    msg db "Hello, GLYPH!", 0

section .text
    mov rcx, 10         ; x
    mov rdx, 5          ; y
    lea r8, [msg]       ; pointer to string
    call gfx_draw_text
```

#### `gfx_present`
Sync back buffer to front buffer for display.

```asm
call gfx_present    ; Returns dirty cell count in RAX
```

---

## Input API

### Polling Model

Input is **polled**, not event-driven. Every frame:

1. Platform polls keyboard state
2. Core computes pressed/released edges
3. Your game queries the state

### Functions

#### `input_is_down`
Check if a key is currently held.

```asm
mov rcx, 0x1B       ; KEY_ESCAPE
call input_is_down
test rax, rax
jnz .escape_held
```

#### `input_was_pressed`
Check if a key was **just pressed** this frame (edge detection).

```asm
mov rcx, 0x20       ; KEY_SPACE
call input_was_pressed
test rax, rax
jnz .space_just_pressed
```

### Key Codes

```asm
; Arrow keys
KEY_LEFT    equ 0x25
KEY_UP      equ 0x26
KEY_RIGHT   equ 0x27
KEY_DOWN    equ 0x28

; Common keys
KEY_SPACE   equ 0x20
KEY_ENTER   equ 0x0D
KEY_ESCAPE  equ 0x1B

; Letters (A-Z = 0x41-0x5A)
KEY_W       equ 0x57
KEY_A       equ 0x41
KEY_S       equ 0x53
KEY_D       equ 0x44
```

---

## Timing API

### Fixed Timestep

The game loop runs at a **fixed 60 FPS** logical rate:

```
┌─────────────────────────────────────────────────────────┐
│                    FRAME START                          │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  WHILE (accumulator >= 16.67ms):                │   │
│  │      game_update()     ← Fixed rate (60 Hz)     │   │
│  │      accumulator -= 16.67ms                     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  game_render()             ← Once per frame            │
│  display()                                              │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Why Fixed Timestep?

| Problem | Fixed Timestep Solution |
|---------|------------------------|
| Fast PC runs too fast | Same number of updates/second |
| Slow PC feels laggy | Multiple updates catch up |
| Physics inconsistent | Deterministic simulation |
| Gameplay varies | Identical behavior everywhere |

---

## Writing Your First Game

### Required Exports

Your game must provide exactly 4 functions:

```asm
global game_init        ; Called once at startup
global game_update      ; Called every fixed timestep
global game_render      ; Called every frame
global game_should_quit ; Return 1 to exit
```

### Minimal Template

```asm
bits 64
default rel

;; Imports
extern gfx_put_char
extern gfx_draw_text
extern input_was_pressed

;; Exports
global game_init
global game_update
global game_render
global game_should_quit

section .bss
    quit_flag   resq 1
    player_x    resq 1
    player_y    resq 1

section .data
    title_msg   db "My Game", 0

section .text

;; ─────────────────────────────────────────────────────────
;; game_init - Called once at startup
;; ─────────────────────────────────────────────────────────
game_init:
    sub rsp, 40

    lea rax, [quit_flag]
    mov qword [rax], 0

    lea rax, [player_x]
    mov qword [rax], 40         ; Center X

    lea rax, [player_y]
    mov qword [rax], 12         ; Center Y

    add rsp, 40
    ret

;; ─────────────────────────────────────────────────────────
;; game_update - Called at fixed 60 Hz
;; ─────────────────────────────────────────────────────────
game_update:
    push r12
    sub rsp, 32

    ; Check ESC
    mov rcx, 0x1B
    call input_was_pressed
    test rax, rax
    jz .no_quit
    lea rax, [quit_flag]
    mov qword [rax], 1
.no_quit:

    ; Check arrow keys and move player
    mov rcx, 0x25               ; LEFT
    call input_was_pressed
    test rax, rax
    jz .not_left
    lea rax, [player_x]
    dec qword [rax]
.not_left:

    mov rcx, 0x27               ; RIGHT
    call input_was_pressed
    test rax, rax
    jz .not_right
    lea rax, [player_x]
    inc qword [rax]
.not_right:

    add rsp, 32
    pop r12
    ret

;; ─────────────────────────────────────────────────────────
;; game_render - Called every frame
;; ─────────────────────────────────────────────────────────
game_render:
    sub rsp, 40

    ; Draw title
    mov rcx, 36
    xor rdx, rdx
    lea r8, [title_msg]
    call gfx_draw_text

    ; Draw player
    lea rax, [player_x]
    mov rcx, [rax]
    lea rax, [player_y]
    mov rdx, [rax]
    mov r8, '@'
    call gfx_put_char

    add rsp, 40
    ret

;; ─────────────────────────────────────────────────────────
;; game_should_quit - Return 1 to exit
;; ─────────────────────────────────────────────────────────
game_should_quit:
    lea rax, [quit_flag]
    mov rax, [rax]
    ret
```

---

## Memory Layout

### Cell Structure

```
Offset 0: Glyph (ASCII character, 1 byte)
Offset 1: Foreground color (0-15, 1 byte)
Offset 2: Background color (0-15, 1 byte)
Offset 3: Flags (reserved, 1 byte)

Total: 4 bytes per cell
Grid:  80 × 25 = 2000 cells
Buffer: 8000 bytes
```

### Buffer Layout

```
Address Calculation:
offset = (y * 80 + x) * 4

Example: Cell at (10, 5)
offset = (5 * 80 + 10) * 4 = 1640
```

---

## Common Patterns

### Speed Control (Tick Counter)

```asm
section .bss
    move_timer  resq 1

section .text
game_update:
    ; Only move every 10 ticks
    lea rax, [move_timer]
    inc qword [rax]
    cmp qword [rax], 10
    jb .skip_move

    mov qword [rax], 0      ; Reset timer
    ; ... do movement ...

.skip_move:
    ret
```

### Simple Random Number

```asm
section .bss
    rand_seed   resq 1

section .text
random:
    lea rax, [rand_seed]
    mov rax, [rax]
    imul rax, 1103515245
    add rax, 12345
    lea rbx, [rand_seed]
    mov [rbx], rax
    shr rax, 16             ; Use upper bits
    ret

; Get random 0 to N-1:
random_range:               ; rcx = max
    push rbx
    sub rsp, 32
    mov rbx, rcx            ; Save max
    call random
    xor rdx, rdx
    div rbx                 ; rax = quotient, rdx = remainder
    mov rax, rdx            ; Return remainder
    add rsp, 32
    pop rbx
    ret
```

### Drawing a Box

```asm
;; draw_box(x, y, width, height)
draw_box:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40

    mov r12, rcx            ; x
    mov r13, rdx            ; y
    mov r14, r8             ; width
    mov r15, r9             ; height

    ; Top border
    xor rbx, rbx
.top:
    lea rcx, [r12 + rbx]
    mov rdx, r13
    mov r8, '-'
    call gfx_put_char
    inc rbx
    cmp rbx, r14
    jl .top

    ; Bottom border
    xor rbx, rbx
.bottom:
    lea rcx, [r12 + rbx]
    lea rdx, [r13 + r15 - 1]
    mov r8, '-'
    call gfx_put_char
    inc rbx
    cmp rbx, r14
    jl .bottom

    ; ... sides similarly ...

    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
```

---

## Debugging Tips

### Common Mistakes

| Symptom | Likely Cause |
|---------|--------------|
| Crash on call | Missing shadow space |
| Stack corruption | Misaligned stack |
| Wrong values after call | Used volatile register |
| Input not working | Forgot `input_begin_frame` |
| Nothing displays | Forgot `gfx_present` |

### Debug Print Pattern

```asm
; Quick debug: print a character at top-left
mov rcx, 0
mov rdx, 0
mov r8, 'X'         ; Change to see different states
call gfx_put_char
```

### Stack Frame Visualization

```
High addresses
┌──────────────────────┐
│   Caller's frame     │
├──────────────────────┤
│   Return address     │  ← RSP at entry
├──────────────────────┤
│   Shadow space       │  32 bytes
│   (required even     │
│    if unused)        │
├──────────────────────┤
│   Your locals        │  ← RSP after sub
├──────────────────────┤
│   Alignment padding  │  (if needed)
└──────────────────────┘
Low addresses
```

---

## API Reference

### Graphics Functions

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `gfx_init` | - | - | Initialize framebuffer |
| `gfx_clear` | - | - | Clear to default |
| `gfx_put_char` | RCX=x, RDX=y, R8=char | - | Draw character |
| `gfx_put_cell` | RCX=x, RDX=y, R8=char, R9=fg, [rsp+40]=bg | - | Draw colored cell |
| `gfx_draw_text` | RCX=x, RDX=y, R8=string | - | Draw string |
| `gfx_present` | - | RAX=dirty count | Sync to front buffer |

### Input Functions

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `input_init` | - | - | Initialize input |
| `input_begin_frame` | - | - | Update edge detection |
| `input_is_down` | RCX=keycode | RAX=0/1 | Is key held? |
| `input_was_pressed` | RCX=keycode | RAX=0/1 | Just pressed? |
| `input_was_released` | RCX=keycode | RAX=0/1 | Just released? |

### Timing Functions

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `timing_init` | - | - | Initialize timing |
| `timing_frame_start` | - | - | Begin frame timing |
| `timing_should_update` | - | RAX=0/1 | Time for update? |
| `timing_update` | - | - | Consume one timestep |
| `timing_get_fps` | - | RAX=fps | Get current FPS |

---

## Platform-Specific Notes

### Windows Console Limitations

- Maximum reliable refresh: ~60 FPS
- Color palette: Fixed 16 colors
- Character encoding: ASCII only
- Window resizing: May cause artifacts

### Windows API Calls Used

| API | Purpose |
|-----|---------|
| `GetStdHandle` | Console handles |
| `WriteConsoleOutputA` | Fast grid rendering |
| `GetAsyncKeyState` | Keyboard polling |
| `QueryPerformanceCounter` | High-res timing |
| `Sleep` | CPU throttling |

---

<p align="center">
<em>"Every cycle has a reason."</em>
</p>
