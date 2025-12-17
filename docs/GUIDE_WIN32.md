# GLYPH Developer Guide — Windows x86 (32-bit)

<p align="center">
  <strong>Platform:</strong> Windows 32-bit<br>
  <strong>Architecture:</strong> x86 (i386/i686)<br>
  <strong>Assembler:</strong> NASM<br>
  <strong>Linker:</strong> GCC (MinGW-w32)
</p>

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture Overview](#architecture-overview)
3. [Windows x86 Calling Convention](#windows-x86-calling-convention)
4. [Register Reference](#register-reference)
5. [Function Patterns](#function-patterns)
6. [Key Differences from x64](#key-differences-from-x64)
7. [Graphics API](#graphics-api)
8. [Input API](#input-api)
9. [Timing API](#timing-api)
10. [Writing Your First Game](#writing-your-first-game)
11. [Memory Considerations](#memory-considerations)
12. [Common Patterns](#common-patterns)
13. [Debugging Tips](#debugging-tips)
14. [API Reference](#api-reference)

---

## Quick Start

### Prerequisites

| Tool | Version | Download |
|------|---------|----------|
| NASM | 2.15+ | [nasm.us](https://nasm.us/) |
| GCC | MinGW-w32 (32-bit!) | [mingw-w64.org](https://www.mingw-w64.org/) |

### Build & Run

```batch
cd glyph
.\build32.bat
.\build\glyph32.exe
```

### ⚠️ Important: Use 32-bit MinGW

You **must** use the 32-bit version of MinGW, not the 64-bit version. The 32-bit toolchain is often called:
- `i686-w64-mingw32-gcc`
- `mingw32-gcc`

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      YOUR GAME                               │
│                    (game/*.asm)                              │
└──────────────────────────┬──────────────────────────────────┘
                           │ calls
┌──────────────────────────▼──────────────────────────────────┐
│                     CORE LAYER                               │
│              (Portable, No OS Calls)                         │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │ frame.asm   │ │ input.asm   │ │ timing.asm  │            │
│  │ Framebuffer │ │ Key States  │ │ Fixed Step  │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
└──────────────────────────┬──────────────────────────────────┘
                           │ calls
┌──────────────────────────▼──────────────────────────────────┐
│                   PLATFORM LAYER                             │
│                 (Windows x86 Specific)                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │ entry.asm   │ │ console.asm │ │ timing.asm  │            │
│  │ Main Loop   │ │ Rendering   │ │ QPC Timer   │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
└──────────────────────────┬──────────────────────────────────┘
                           │ syscalls
┌──────────────────────────▼──────────────────────────────────┐
│                   WINDOWS KERNEL (32-bit)                    │
│         kernel32.dll, user32.dll                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Windows x86 Calling Convention

### cdecl Convention (Used by GLYPH)

GLYPH uses **cdecl** exclusively. This is important!

| Aspect | cdecl Rule |
|--------|------------|
| Arguments | Pushed right-to-left on stack |
| Return value | EAX (or EDX:EAX for 64-bit) |
| Stack cleanup | **Caller** cleans the stack |
| Preserved | EBX, EBP, ESI, EDI |
| Volatile | EAX, ECX, EDX |

### Argument Passing

All arguments are passed on the **stack**:

```
Before call:        After call starts:
                    ┌──────────────────┐
push arg3           │      arg3        │ [ESP+16]
push arg2           │      arg2        │ [ESP+12]
push arg1           │      arg1        │ [ESP+8]
push arg0           │      arg0        │ [ESP+4]
call function       │  return address  │ [ESP]
                    └──────────────────┘
```

### Stack Cleanup (Critical!)

After every call, you must clean up:

```asm
push 42             ; 1 argument (4 bytes)
call my_function
add esp, 4          ; Clean up 1 argument

push arg2           ; 2 arguments (8 bytes)
push arg1
call other_function
add esp, 8          ; Clean up 2 arguments
```

### Frame Pointer Convention

Standard function prologue/epilogue:

```asm
my_function:
    push ebp            ; Save old base pointer
    mov ebp, esp        ; Establish new frame
    sub esp, 16         ; Reserve local space (if needed)

    ; Arguments:
    ; [ebp+8]  = arg0
    ; [ebp+12] = arg1
    ; [ebp+16] = arg2

    ; Local variables:
    ; [ebp-4]  = local0
    ; [ebp-8]  = local1

    mov esp, ebp        ; Restore stack
    pop ebp             ; Restore base pointer
    ret
```

### Stack Layout with Frame Pointer

```
High addresses
┌──────────────────────┐
│      arg2            │ [EBP+16]
├──────────────────────┤
│      arg1            │ [EBP+12]
├──────────────────────┤
│      arg0            │ [EBP+8]
├──────────────────────┤
│   Return Address     │ [EBP+4]
├──────────────────────┤
│   Old EBP            │ [EBP] ← EBP points here
├──────────────────────┤
│   local0             │ [EBP-4]
├──────────────────────┤
│   local1             │ [EBP-8]
├──────────────────────┤
│   ...                │ ← ESP points here
└──────────────────────┘
Low addresses
```

---

## Register Reference

### General Purpose Registers (32-bit)

| Register | Volatile? | Typical Use |
|----------|-----------|-------------|
| EAX | Yes | Return value, accumulator |
| EBX | **No** | Base pointer (general) |
| ECX | Yes | Counter, scratch |
| EDX | Yes | Data, I/O, scratch |
| ESI | **No** | Source index |
| EDI | **No** | Destination index |
| EBP | **No** | Base/frame pointer |
| ESP | - | Stack pointer (don't mess with it) |

### Size Variants

| 32-bit | 16-bit | 8-bit High | 8-bit Low |
|--------|--------|------------|-----------|
| EAX | AX | AH | AL |
| EBX | BX | BH | BL |
| ECX | CX | CH | CL |
| EDX | DX | DH | DL |
| ESI | SI | - | - |
| EDI | DI | - | - |

### Logical Mapping (GLYPH Convention)

Unlike x64, arguments come from the stack:

| Logical | Physical | Purpose |
|---------|----------|---------|
| A0 | [EBP+8] | Argument 0 |
| A1 | [EBP+12] | Argument 1 |
| A2 | [EBP+16] | Argument 2 |
| A3 | [EBP+20] | Argument 3 |
| R0 | EAX | Return value |
| TMP0 | ECX | Scratch (volatile) |
| TMP1 | EDX | Scratch (volatile) |

---

## Function Patterns

### Minimal Function (No Calls, No Frame)

```asm
;; int add(int a, int b)
_add:
    mov eax, [esp+4]    ; a
    add eax, [esp+8]    ; + b
    ret
```

### Standard Function (With Frame Pointer)

```asm
_my_function:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]    ; First argument
    ; ... do work ...

    pop ebp
    ret
```

### Function That Makes Calls

```asm
_my_function:
    push ebp
    mov ebp, esp
    push ebx            ; Save non-volatiles we use
    push esi

    mov ebx, [ebp+8]    ; Store arg in safe register

    push ebx            ; Arg to another function
    call _other_func
    add esp, 4          ; Clean up!

    pop esi             ; Restore in reverse order
    pop ebx
    pop ebp
    ret
```

### Function With Local Variables

```asm
_my_function:
    push ebp
    mov ebp, esp
    sub esp, 16         ; 4 local dwords

    mov dword [ebp-4], 0    ; local0 = 0
    mov dword [ebp-8], 42   ; local1 = 42

    ; ... use locals ...

    mov esp, ebp        ; Clean locals
    pop ebp
    ret
```

---

## Key Differences from x64

### Summary Table

| Aspect | x86 (32-bit) | x64 (64-bit) |
|--------|--------------|--------------|
| Pointer size | 4 bytes | 8 bytes |
| Arguments | Stack only | Registers (RCX, RDX, R8, R9) |
| Shadow space | None | 32 bytes required |
| More registers | 8 GPRs | 16 GPRs |
| Stack cleanup | Caller (cdecl) | Caller |
| Alignment | 4 bytes | 16 bytes |
| Symbol prefix | Underscore `_` | None |

### Symbol Naming

On Win32, C symbols have an underscore prefix:

```asm
global _my_function     ; 32-bit
extern _printf

; vs

global my_function      ; 64-bit
extern printf
```

### Fewer Registers

You have only 6 truly usable GPRs (EAX, EBX, ECX, EDX, ESI, EDI), and 3 of those are volatile.

**Strategy**: Use the stack more, or be clever with register allocation.

### No R8-R15

The extra registers (R8-R15) simply don't exist on x86. Code that uses them won't assemble.

---

## Graphics API

### Same Logical API

The graphics API is identical in function signatures, just different calling convention:

```asm
;; gfx_put_char(x, y, char)
push 'X'            ; character
push 5              ; y
push 10             ; x
call _gfx_put_char
add esp, 12         ; Clean 3 dwords

;; gfx_draw_text(x, y, string)
push msg_ptr        ; string pointer
push 0              ; y
push 10             ; x
call _gfx_draw_text
add esp, 12
```

### Drawing Patterns

```asm
;; Draw a character
_draw_char:
    push ebp
    mov ebp, esp

    push '@'                ; char
    push dword [ebp+12]     ; y
    push dword [ebp+8]      ; x
    call _gfx_put_char
    add esp, 12

    pop ebp
    ret
```

---

## Input API

### Same Logical API

```asm
;; Check if ESC pressed
push 0x1B               ; KEY_ESCAPE
call _input_was_pressed
add esp, 4
test eax, eax
jnz .escape_pressed
```

### Movement Pattern

```asm
;; Check arrow keys
push 0x25               ; KEY_LEFT
call _input_is_down
add esp, 4
test eax, eax
jz .not_left
    dec dword [player_x]
.not_left:

push 0x27               ; KEY_RIGHT
call _input_is_down
add esp, 4
test eax, eax
jz .not_right
    inc dword [player_x]
.not_right:
```

---

## Timing API

### Same as x64

```asm
call _timing_frame_start

.update_loop:
    call _timing_should_update
    test eax, eax
    jz .render

    call _game_update
    call _timing_update
    jmp .update_loop

.render:
```

---

## Writing Your First Game

### Required Exports (Note Underscores!)

```asm
global _game_init
global _game_update
global _game_render
global _game_should_quit
```

### Minimal Template

```asm
bits 32

;; Imports
extern _gfx_put_char
extern _gfx_draw_text
extern _input_was_pressed

;; Exports
global _game_init
global _game_update
global _game_render
global _game_should_quit

section .bss
    quit_flag   resd 1
    player_x    resd 1
    player_y    resd 1

section .data
    title_msg   db "My Game (32-bit)", 0

section .text

;; ─────────────────────────────────────────────────────────
;; game_init
;; ─────────────────────────────────────────────────────────
_game_init:
    push ebp
    mov ebp, esp

    mov dword [quit_flag], 0
    mov dword [player_x], 40
    mov dword [player_y], 12

    pop ebp
    ret

;; ─────────────────────────────────────────────────────────
;; game_update
;; ─────────────────────────────────────────────────────────
_game_update:
    push ebp
    mov ebp, esp
    push ebx

    ;; Check ESC
    push 0x1B
    call _input_was_pressed
    add esp, 4
    test eax, eax
    jz .no_quit
    mov dword [quit_flag], 1
.no_quit:

    ;; Check LEFT
    push 0x25
    call _input_was_pressed
    add esp, 4
    test eax, eax
    jz .not_left
    dec dword [player_x]
.not_left:

    ;; Check RIGHT
    push 0x27
    call _input_was_pressed
    add esp, 4
    test eax, eax
    jz .not_right
    inc dword [player_x]
.not_right:

    pop ebx
    pop ebp
    ret

;; ─────────────────────────────────────────────────────────
;; game_render
;; ─────────────────────────────────────────────────────────
_game_render:
    push ebp
    mov ebp, esp

    ;; Draw title
    push title_msg
    push 0
    push 32
    call _gfx_draw_text
    add esp, 12

    ;; Draw player
    push '@'
    push dword [player_y]
    push dword [player_x]
    call _gfx_put_char
    add esp, 12

    pop ebp
    ret

;; ─────────────────────────────────────────────────────────
;; game_should_quit
;; ─────────────────────────────────────────────────────────
_game_should_quit:
    mov eax, [quit_flag]
    ret
```

---

## Memory Considerations

### Pointer Size

All pointers are 4 bytes. Using `resq` (reserve quadword) is wasteful; prefer `resd`:

```asm
section .bss
    player_x    resd 1      ; 4 bytes, not 8
    score       resd 1
    flags       resd 1
```

### Address Limits

Maximum addressable memory: 4 GB (usually 2-3 GB usable due to kernel space).

### Structure Packing

Align structures to 4 bytes:

```asm
struc Entity
    .x      resd 1      ; offset 0
    .y      resd 1      ; offset 4
    .type   resd 1      ; offset 8
    .size:              ; total: 12 bytes
endstruc
```

---

## Common Patterns

### Speed Control

```asm
section .bss
    tick_count  resd 1

section .text
_game_update:
    push ebp
    mov ebp, esp

    inc dword [tick_count]
    mov eax, [tick_count]
    
    ;; Only act every 6 ticks
    xor edx, edx
    mov ecx, 6
    div ecx
    test edx, edx
    jnz .skip

    ;; ... do movement ...

.skip:
    pop ebp
    ret
```

### Random Number (LCG)

```asm
section .bss
    rand_seed   resd 1

section .text
_random:
    mov eax, [rand_seed]
    imul eax, 1103515245
    add eax, 12345
    mov [rand_seed], eax
    shr eax, 16
    ret

;; random_range(max) -> 0 to max-1
_random_range:
    push ebp
    mov ebp, esp
    push ebx

    mov ebx, [ebp+8]    ; max

    call _random
    xor edx, edx
    div ebx             ; eax = quotient, edx = remainder
    mov eax, edx        ; return remainder

    pop ebx
    pop ebp
    ret
```

### Drawing a Horizontal Line

```asm
;; draw_hline(x, y, length, char)
_draw_hline:
    push ebp
    mov ebp, esp
    push ebx
    push esi

    mov esi, [ebp+8]    ; x
    mov ebx, 0          ; counter

.loop:
    cmp ebx, [ebp+16]   ; compare to length
    jge .done

    push dword [ebp+20] ; char
    push dword [ebp+12] ; y
    lea eax, [esi+ebx]  ; x + counter
    push eax
    call _gfx_put_char
    add esp, 12

    inc ebx
    jmp .loop

.done:
    pop esi
    pop ebx
    pop ebp
    ret
```

---

## Debugging Tips

### Common Mistakes

| Symptom | Likely Cause |
|---------|--------------|
| Crash after call | Forgot `add esp, N` cleanup |
| Wrong argument values | Push order wrong (should be right-to-left) |
| Corrupted values | Used volatile register across call |
| Linker error: undefined `func` | Missing underscore `_func` |
| Segfault in function | Corrupted EBP/ESP |

### Stack Checking Pattern

```asm
_my_function:
    push ebp
    mov ebp, esp

    ;; Save ESP for later check
    mov eax, esp

    ;; ... do work, make calls ...

    ;; Verify ESP is correct
    cmp esp, eax
    jne .stack_error

    pop ebp
    ret

.stack_error:
    ;; ESP changed unexpectedly!
    int3                ; Breakpoint
```

### Debug Print

```asm
;; Quick debug: draw marker at (0,0)
push 'X'
push 0
push 0
call _gfx_put_char
add esp, 12
```

---

## API Reference

### Graphics Functions

| Function | Stack Args | Returns | Description |
|----------|------------|---------|-------------|
| `_gfx_init` | - | - | Initialize framebuffer |
| `_gfx_clear` | - | - | Clear to default |
| `_gfx_put_char` | x, y, char | - | Draw character |
| `_gfx_put_cell` | x, y, char, fg, bg | - | Draw colored cell |
| `_gfx_draw_text` | x, y, string | - | Draw string |
| `_gfx_present` | - | EAX=dirty | Sync to front buffer |

### Input Functions

| Function | Stack Args | Returns | Description |
|----------|------------|---------|-------------|
| `_input_init` | - | - | Initialize input |
| `_input_begin_frame` | - | - | Update edge detection |
| `_input_is_down` | keycode | EAX=0/1 | Is key held? |
| `_input_was_pressed` | keycode | EAX=0/1 | Just pressed? |
| `_input_was_released` | keycode | EAX=0/1 | Just released? |

### Timing Functions

| Function | Stack Args | Returns | Description |
|----------|------------|---------|-------------|
| `_timing_init` | - | - | Initialize timing |
| `_timing_frame_start` | - | - | Begin frame timing |
| `_timing_should_update` | - | EAX=0/1 | Time for update? |
| `_timing_update` | - | - | Consume one timestep |
| `_timing_get_fps` | - | EAX=fps | Get current FPS |

---

## Why Use 32-bit?

### Valid Reasons

- Target ancient hardware that can't run 64-bit Windows
- Embedded systems with x86 processors
- Learning: simpler calling convention in some ways
- Retrocomputing projects
- Maximum compatibility (runs everywhere)

### When to Use 64-bit Instead

- Modern desktop development
- Need more than 4GB RAM
- Want register-based calling (faster)
- Need R8-R15 registers

---

## Build Script (build32.bat)

```batch
@echo off
REM GLYPH Build Script - Windows x86 (32-bit)

echo.
echo   GLYPH Framework Build
echo   Platform: Windows x86 (32-bit)
echo   Toolchain: NASM + GCC (MinGW-w32)
echo.

if not exist build mkdir build

echo [1/8] Assembling core/frame.asm...
nasm -f win32 core/frame32.asm -o build/frame.obj
if errorlevel 1 goto :error

REM ... (rest of build steps)

echo Linking with GCC (32-bit)...
i686-w64-mingw32-gcc -o build/glyph32.exe build/*.obj -nostdlib -lkernel32 -luser32 -Wl,--subsystem,console -Wl,-e__start

echo.
echo   BUILD SUCCESSFUL!
echo   Run: build\glyph32.exe
goto :end

:error
echo   BUILD FAILED
exit /b 1

:end
```

---

<p align="center">
<em>"Every byte counts."</em>
</p>
