# GLYPH Developer Guides

> Choose your platform to get started.

---

## Available Platforms

| Platform | Architecture | Guide |
|----------|--------------|-------|
| **Windows x64** | 64-bit (AMD64) | [📖 GUIDE_WIN64.md](docs/GUIDE_WIN64.md) |
| **Windows x86** | 32-bit (i386) | [📖 GUIDE_WIN32.md](docs/GUIDE_WIN32.md) |
| Linux x64 | 64-bit | *Coming soon* |
| ARM64 | 64-bit ARM | *Coming soon* |

---

## Quick Comparison

| Aspect | Windows x64 | Windows x86 |
|--------|-------------|-------------|
| **Pointer size** | 8 bytes | 4 bytes |
| **Arguments** | Registers (RCX, RDX, R8, R9) | Stack only |
| **Shadow space** | 32 bytes required | None |
| **GPR count** | 16 | 8 |
| **Symbol prefix** | None | Underscore `_` |
| **Max RAM** | 16+ EB | 4 GB |

---

## Which Platform Should I Choose?

### Choose Windows x64 if:
- You're developing on a modern 64-bit Windows PC
- You want more registers and cleaner code
- You don't need to support 32-bit-only systems
- **Recommended for most developers**

### Choose Windows x86 if:
- You're targeting ancient hardware
- You need maximum compatibility (runs on both 32/64-bit Windows)
- You're doing retrocomputing or embedded x86
- You want the challenge of working with fewer registers

---

## Project Structure

```
glyph/
├── MANIFESTO.md        # Philosophy and goals
├── GUIDE.md            # This file (index)
├── LICENSE             # License terms
│
├── docs/
│   ├── GUIDE_WIN64.md  # Windows x64 detailed guide
│   └── GUIDE_WIN32.md  # Windows x86 detailed guide
│
├── include/            # ABI normalization headers
│   ├── glyph.inc       # Master include
│   ├── abi.inc         # ABI dispatcher
│   ├── abi_win64.inc   # Win64 specifics
│   ├── abi_win32.inc   # Win32 specifics
│   ├── config.inc      # Configuration constants
│   └── input.inc       # Key codes
│
├── core/               # Portable core (identical across platforms)
│   ├── frame.asm       # Framebuffer
│   ├── input.asm       # Input state
│   └── timing.asm      # Fixed timestep
│
├── platform/
│   ├── win64/          # Windows 64-bit backend
│   │   ├── entry.asm
│   │   ├── console.asm
│   │   ├── input.asm
│   │   └── timing.asm
│   │
│   └── win32/          # Windows 32-bit backend (future)
│       ├── entry.asm
│       ├── console.asm
│       ├── input.asm
│       └── timing.asm
│
├── game/               # Example games
│   └── snake.asm
│
├── build.bat           # Win64 build script
└── build32.bat         # Win32 build script (future)
```

---

## Core Concepts

### 1. The ABI Normalization Layer

GLYPH uses a **logical ABI** that maps to physical registers/stack:

```asm
; Logical (what you write)      Physical (what it becomes)
;   A0                    →     RCX (Win64) or [EBP+8] (Win32)
;   A1                    →     RDX (Win64) or [EBP+12] (Win32)
;   R0                    →     RAX (Win64) or EAX (Win32)
```

Include `glyph.inc` and let the macros handle the rest.

### 2. Core Never Changes

The `/core` directory contains **portable logic**. It:
- Makes no OS calls
- Uses no platform-specific constructs
- Depends only on symbols exported by platform layer

This means adding a new platform = writing new platform glue, not rewriting core.

### 3. Platform Exports Stable Symbols

Platform layer must export these exact symbols:

```asm
; From platform/entry
_start (or main)
platform_shutdown

; From platform/console
console_init
console_render
console_poll_input

; From platform/timing
platform_get_time_us
```

### 4. Game Exports Contract

Your game must export:

```asm
game_init           ; Called once
game_update         ; Called at fixed timestep
game_render         ; Called every frame
game_should_quit    ; Return 1 to exit
```

---

## Getting Started

1. **Read the manifesto**: [MANIFESTO.md](MANIFESTO.md)
2. **Choose your platform guide**:
   - [Windows x64](docs/GUIDE_WIN64.md) ← Start here if unsure
   - [Windows x86](docs/GUIDE_WIN32.md)
3. **Build the demo**: `.\build.bat`
4. **Run it**: `.\build\glyph.exe`
5. **Study the Snake game**: `game/snake.asm`
6. **Write your own game!**

---

## Philosophy Reminder

> This framework exists for developers who value **simplicity**, **control**, and **longevity**.

- No hidden magic
- No runtime dependencies
- Every cycle has a reason
- Assembly is not hidden — it's the point

---

<p align="center">
<strong>Pick a platform. Start building.</strong>
</p>
