# GLYPH

```
   ██████╗ ██╗  ██╗   ██╗██████╗ ██╗  ██╗
  ██╔════╝ ██║  ╚██╗ ██╔╝██╔══██╗██║  ██║
  ██║  ███╗██║   ╚████╔╝ ██████╔╝███████║
  ██║   ██║██║    ╚██╔╝  ██╔═══╝ ██╔══██║
  ╚██████╔╝███████╗██║   ██║     ██║  ██║
   ╚═════╝ ╚══════╝╚═╝   ╚═╝     ╚═╝  ╚═╝
```

> A low-level 2D / text-first framework for ultra-low-spec hardware, written in pure Assembly.

---

## Quick Start

```batch
# Build Snake (64-bit)
.\build.bat snake
.\build\glyph.exe

# Build other games
.\build.bat pong
.\build.bat breakout
.\build.bat minirogue
```

---

## Platforms

| Platform | Architecture | Status | Build Script |
|----------|--------------|--------|--------------|
| **Windows x64** | 64-bit (AMD64) | ✅ Complete | `build.bat` |
| **Windows x86** | 32-bit (i386) | ✅ Complete | `build32.bat` |
| Linux x64 | 64-bit | 🔜 Planned | - |
| ARM64 | 64-bit ARM | 🔜 Planned | - |

---

## Example Games

| Game | Description | States |
|------|-------------|--------|
| **Snake** | Classic snake game | Playing, Paused, Game Over |
| **Pong** | Single-player vs CPU | Scoring, Paddle AI |
| **Breakout** | Brick breaker | Bricks, Lives, Win condition |
| **MiniRogue** | Dungeon crawler | Procedural rooms, Enemies, Gold, Levels |

---

## Philosophy

This framework exists for developers who value **simplicity**, **control**, and **longevity**.

It is designed for machines that modern software ignores. It favors clarity over abstraction. It avoids features that cannot be understood end-to-end.

There are no editors. There is no scripting language. There is no hidden runtime.

If you want convenience, use something else.  
If you want understanding, **welcome**.

---

## What This Is

- A low-level 2D / text-first framework
- Pure x86/x64 assembly (NASM syntax)
- Zero dependencies beyond the OS kernel
- ASCII-first rendering with 16-color palette
- Designed for garbage hardware that modern software refuses to run on

## What This Is Not

- A game engine
- A competitor to Godot, Unity, or anything "modern"
- A tech demo
- An abstraction layer hiding complexity

---

## Core Principles

### 1. Everything In Under 10k Lines Per Backend
If a feature violates this, it doesn't belong.

### 2. No Magic
Every cycle has a reason. No callbacks. No events. No opaque pointers.

### 3. 2D Only
No 3D. No perspective. No z-buffers. Flat and proud.

### 4. Text & Simple Graphics First
ASCII is not a limitation — it's a language.

### 5. Zero Dependencies
No CRT. No runtime. Just the OS kernel and your code.

### 6. Assembly Is Not Hidden
Developers see the machine. That's the point.

---

## Technical Specifications

| Specification | Win64 | Win32 |
|---------------|-------|-------|
| **Pointer size** | 8 bytes | 4 bytes |
| **Arguments** | RCX, RDX, R8, R9 | Stack (cdecl) |
| **Shadow space** | 32 bytes | None |
| **GPR count** | 16 | 8 |
| **Symbol prefix** | None | Underscore `_` |
| **Grid Size** | 80×25 | 80×25 |
| **Colors** | 16 | 16 |
| **Frame Rate** | 60 FPS | 60 FPS |

---

## Project Structure

```
glyph/
├── MANIFESTO.md            # This file
├── GUIDE.md                # Platform selection guide
├── LICENSE                 # Source-available license
│
├── docs/
│   ├── GUIDE_WIN64.md      # Comprehensive Win64 guide
│   └── GUIDE_WIN32.md      # Comprehensive Win32 guide
│
├── include/                # ABI Normalization Headers
│   ├── glyph.inc           # Master include
│   ├── abi.inc             # Platform dispatcher
│   ├── abi_win64.inc       # Win64 ABI definitions
│   ├── abi_win32.inc       # Win32 ABI definitions
│   ├── config.inc          # Compile-time constants
│   └── input.inc           # Key codes
│
├── core/                   # Win64 Core (Portable Logic)
│   ├── frame.asm           # Framebuffer
│   ├── input.asm           # Input state
│   └── timing.asm          # Fixed timestep
│
├── core32/                 # Win32 Core
│   ├── frame.asm
│   ├── input.asm
│   └── timing.asm
│
├── platform/
│   ├── win64/              # Windows 64-bit Backend
│   │   ├── entry.asm       # Main loop
│   │   ├── console.asm     # Console rendering
│   │   ├── input.asm       # Keyboard polling
│   │   └── timing.asm      # High-res timer
│   │
│   └── win32/              # Windows 32-bit Backend
│       ├── entry.asm
│       ├── console.asm
│       ├── input.asm
│       └── timing.asm
│
├── game/                   # Win64 Example Games
│   ├── snake.asm
│   ├── pong.asm
│   ├── breakout.asm
│   └── minirogue.asm
│
├── game32/                 # Win32 Example Games
│   └── snake.asm
│
├── build.bat               # Win64 build script
├── build32.bat             # Win32 build script
│
└── build/                  # Compiled output
    ├── glyph.exe           # Win64 executable
    └── glyph32.exe         # Win32 executable
```

---

## Requirements

### Windows x64
- **NASM** 2.15+ — [nasm.us](https://nasm.us/)
- **GCC** MinGW-w64 — [mingw-w64.org](https://www.mingw-w64.org/)

### Windows x86
- **NASM** 2.15+
- **GCC** MinGW-w32 (i686-w64-mingw32-gcc)

---

## Building

### 64-bit (Recommended)
```batch
.\build.bat              # Build snake (default)
.\build.bat pong         # Build specific game
.\build.bat breakout
.\build.bat minirogue
```

### 32-bit
```batch
.\build32.bat            # Build snake for 32-bit
```

---

## License

**GLYPH Framework**: Source-available, non-commercial license.

- ✅ Free to use, study, and modify
- ✅ Free for personal and educational projects  
- ✅ Free to share and contribute
- ❌ Commercial use of the framework requires a license

**Games made with GLYPH**: You own them completely. No restrictions.

See [LICENSE](LICENSE) for full terms.

---

## Target Audience

- People who like constraints
- People who enjoy understanding the machine
- People who want total control without bloat

That audience exists — and they care deeply.

---

## Contributing

Keep the philosophy in mind:

1. **Keep it simple** — No features that can't be understood in 10 minutes
2. **Keep it small** — Under 10k lines per backend
3. **Keep it explicit** — No magic, no hidden behavior
4. **Assembly first** — If it can't be expressed cleanly in ASM, reconsider it

---

<p align="center">
<em>"Every cycle has a reason."</em>
<br><br>
<strong>GLYPH</strong> — Framework for the machine-minded.
</p>
