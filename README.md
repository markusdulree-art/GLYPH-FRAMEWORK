<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%20x64%20%7C%20x86-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Language-Assembly%20(NASM)-green" alt="Language">
  <img src="https://img.shields.io/badge/License-Source--Available-orange" alt="License">
</p>

<h1 align="center">GLYPH</h1>

<p align="center">
  <strong>A low-level 2D / text-first framework for ultra-low-spec hardware, written in pure Assembly.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Games-Snake%20%7C%20Pong%20%7C%20Breakout%20%7C%20Roguelike-purple" alt="Games">
</p>

---

## 🎮 Demo Games

| Game | Description | Controls |
|------|-------------|----------|
| **Snake** | Classic snake game | Arrow keys, Space (pause) |
| **Pong** | Single-player vs CPU | W/S keys |
| **Breakout** | Brick breaker | Left/Right arrows, Space (launch) |
| **MiniRogue** | Dungeon crawler | Arrow keys (move) |

---

## 🚀 Quick Start

### Prerequisites

- **NASM** (Netwide Assembler) — [Download](https://nasm.us/)
- **GCC** (MinGW-w64) — [Download](https://www.mingw-w64.org/)

### Build & Run

```batch
# Clone the repository
git clone https://github.com/YOUR_USERNAME/glyph.git
cd glyph

# Build (64-bit)
.\build.bat snake        # or: pong, breakout, minirogue

# Run
.\build\glyph.exe
```

### 32-bit Build

```batch
.\build32.bat snake
.\build\glyph32.exe
```

---

## 📖 Philosophy

> *"Every cycle has a reason."*

GLYPH is for developers who value **simplicity**, **control**, and **longevity**.

- **No hidden magic** — Every instruction is explicit
- **No runtime dependencies** — Just the OS kernel
- **No bloat** — Under 10k lines per platform
- **Text-first** — ASCII is not a limitation, it's a language

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      YOUR GAME                               │
│                    (game/*.asm)                              │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                     CORE LAYER                               │
│              (Portable, No OS Calls)                         │
│         frame.asm  │  input.asm  │  timing.asm              │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   PLATFORM LAYER                             │
│              (Windows x64 / x86)                             │
│     entry.asm │ console.asm │ input.asm │ timing.asm        │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                    WINDOWS KERNEL                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
glyph/
├── core/                   # Portable core (64-bit)
├── core32/                 # Portable core (32-bit)
├── platform/
│   ├── win64/              # Windows x64 backend
│   └── win32/              # Windows x86 backend
├── game/                   # Example games (64-bit)
├── game32/                 # Example games (32-bit)
├── include/                # ABI normalization headers
├── docs/                   # Platform-specific guides
├── build.bat               # 64-bit build script
└── build32.bat             # 32-bit build script
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [MANIFESTO.md](MANIFESTO.md) | Philosophy and project overview |
| [GUIDE.md](GUIDE.md) | Platform selection guide |
| [docs/GUIDE_WIN64.md](docs/GUIDE_WIN64.md) | Comprehensive Windows x64 guide |
| [docs/GUIDE_WIN32.md](docs/GUIDE_WIN32.md) | Comprehensive Windows x86 guide |

---

## 🎯 Features

| Feature | Description |
|---------|-------------|
| **Framebuffer** | 80×25 character grid, 16 colors, double-buffered |
| **Input** | Keyboard polling with pressed/released edge detection |
| **Timing** | Fixed timestep (60 FPS), deterministic behavior |
| **Rendering** | Direct console output via WriteConsoleOutputA |
| **ABI Layer** | Logical registers mapped per-platform |

---

## 🛠️ Writing Your Own Game

Create a new file in `game/` with these exports:

```asm
global game_init        ; Called once at startup
global game_update      ; Called every fixed timestep (60 Hz)
global game_render      ; Called every frame
global game_should_quit ; Return 1 to exit
```

Then build with:

```batch
.\build.bat mygame
```

See the [Developer Guide](docs/GUIDE_WIN64.md) for full API reference.

---

## ⚖️ License

**GLYPH Framework**: Source-available, non-commercial.

- ✅ Free to use, study, modify, and share
- ✅ Free for personal and educational projects
- ❌ Commercial use requires a license

**Your Games**: You own them completely. No restrictions.

See [LICENSE](LICENSE) for details.

---

## 🤝 Contributing

Contributions welcome! Keep the philosophy in mind:

1. **Keep it simple** — If it can't be understood in 10 minutes, reconsider
2. **Keep it small** — Under 10k lines per backend
3. **Keep it explicit** — No magic, no hidden behavior
4. **Assembly first** — The machine is the point

---

## 🎮 Target Audience

- Developers who like constraints
- People who enjoy understanding the machine  
- Anyone who wants total control without bloat

---

<p align="center">
  <strong>GLYPH</strong> — Framework for the machine-minded.
  <br><br>
  <em>"I revived an ancient laptop with this."</em>
  <br>
  — Someone, hopefully, someday.
</p>
