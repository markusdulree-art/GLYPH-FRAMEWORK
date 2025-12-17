@echo off
REM ============================================
REM GLYPH Build Script - Windows x64 (64-bit)
REM Platform: Windows x64 (64-bit)  
REM Assembler: NASM
REM Linker: GCC (MinGW-w64)
REM ============================================
REM Usage: build.bat [game]
REM   build.bat           - Build snake (default)
REM   build.bat snake     - Build snake
REM   build.bat pong      - Build pong
REM   build.bat breakout  - Build breakout
REM   build.bat minirogue - Build minirogue
REM ============================================

setlocal enabledelayedexpansion

set GAME=%1
if "%GAME%"=="" set GAME=snake

echo.
echo   ╔═══════════════════════════════════════╗
echo   ║     GLYPH Framework Build             ║
echo   ║     Platform: Windows x64             ║
echo   ║     Toolchain: NASM + GCC             ║
echo   ║     Game: %GAME%                      
echo   ╚═══════════════════════════════════════╝
echo.

if not exist build mkdir build

echo [1/8] Assembling core\frame.asm...
nasm -f win64 core\frame.asm -o build\frame.obj
if errorlevel 1 goto :error

echo [2/8] Assembling core\input.asm...
nasm -f win64 core\input.asm -o build\input.obj
if errorlevel 1 goto :error

echo [3/8] Assembling core\timing.asm...
nasm -f win64 core\timing.asm -o build\timing.obj
if errorlevel 1 goto :error

echo [4/8] Assembling platform\win64\entry.asm...
nasm -f win64 platform\win64\entry.asm -o build\entry.obj
if errorlevel 1 goto :error

echo [5/8] Assembling platform\win64\console.asm...
nasm -f win64 platform\win64\console.asm -o build\console.obj
if errorlevel 1 goto :error

echo [6/8] Assembling platform\win64\input.asm...
nasm -f win64 platform\win64\input.asm -o build\input_win.obj
if errorlevel 1 goto :error

echo [7/8] Assembling platform\win64\timing.asm...
nasm -f win64 platform\win64\timing.asm -o build\timing_win.obj
if errorlevel 1 goto :error

echo [8/8] Assembling game\%GAME%.asm...
if not exist game\%GAME%.asm (
    echo ERROR: Game '%GAME%' not found!
    echo Available games: snake, pong, breakout, minirogue
    goto :error
)
nasm -f win64 game\%GAME%.asm -o build\game.obj
if errorlevel 1 goto :error

echo.
echo Linking with GCC...
gcc -o build\glyph.exe build\entry.obj build\frame.obj build\input.obj build\timing.obj build\console.obj build\input_win.obj build\timing_win.obj build\game.obj -nostdlib -lkernel32 -luser32 -Wl,--subsystem,console -Wl,-e_start
if errorlevel 1 goto :error

echo.
echo   ╔═══════════════════════════════════════╗
echo   ║     BUILD SUCCESSFUL!                 ║
echo   ║     Run: build\glyph.exe              ║
echo   ╚═══════════════════════════════════════╝
goto :end

:error
echo.
echo   ╔═══════════════════════════════════════╗
echo   ║     BUILD FAILED                      ║
echo   ╚═══════════════════════════════════════╝
exit /b 1

:end
endlocal
