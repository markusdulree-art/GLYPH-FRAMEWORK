@echo off
REM ============================================
REM GLYPH Build Script - Windows x86 (32-bit)
REM Platform: Windows x86 (32-bit)
REM Assembler: NASM
REM Linker: GCC (MinGW-w32, i686)
REM ============================================
REM Usage: build32.bat [game]
REM   build32.bat         - Build snake (default)
REM   build32.bat snake   - Build snake
REM ============================================

setlocal enabledelayedexpansion

set GAME=%1
if "%GAME%"=="" set GAME=snake

echo.
echo   ╔═══════════════════════════════════════╗
echo   ║     GLYPH Framework Build             ║
echo   ║     Platform: Windows x86 (32-bit)    ║
echo   ║     Toolchain: NASM + GCC (i686)      ║
echo   ║     Game: %GAME%                      
echo   ╚═══════════════════════════════════════╝
echo.

if not exist build mkdir build

echo [1/8] Assembling core32\frame.asm...
nasm -f win32 core32\frame.asm -o build\frame32.obj
if errorlevel 1 goto :error

echo [2/8] Assembling core32\input.asm...
nasm -f win32 core32\input.asm -o build\input32.obj
if errorlevel 1 goto :error

echo [3/8] Assembling core32\timing.asm...
nasm -f win32 core32\timing.asm -o build\timing32.obj
if errorlevel 1 goto :error

echo [4/8] Assembling platform\win32\entry.asm...
nasm -f win32 platform\win32\entry.asm -o build\entry32.obj
if errorlevel 1 goto :error

echo [5/8] Assembling platform\win32\console.asm...
nasm -f win32 platform\win32\console.asm -o build\console32.obj
if errorlevel 1 goto :error

echo [6/8] Assembling platform\win32\input.asm...
nasm -f win32 platform\win32\input.asm -o build\input_win32.obj
if errorlevel 1 goto :error

echo [7/8] Assembling platform\win32\timing.asm...
nasm -f win32 platform\win32\timing.asm -o build\timing_win32.obj
if errorlevel 1 goto :error

echo [8/8] Assembling game32\%GAME%.asm...
if not exist game32\%GAME%.asm (
    echo ERROR: Game '%GAME%' not found for 32-bit!
    echo Available 32-bit games: snake
    goto :error
)
nasm -f win32 game32\%GAME%.asm -o build\game32.obj
if errorlevel 1 goto :error

echo.
echo Linking with GCC (32-bit)...

REM Try different 32-bit GCC names
where i686-w64-mingw32-gcc >nul 2>&1
if %errorlevel%==0 (
    echo Using i686-w64-mingw32-gcc...
    i686-w64-mingw32-gcc -m32 -o build\glyph32.exe build\entry32.obj build\frame32.obj build\input32.obj build\timing32.obj build\console32.obj build\input_win32.obj build\timing_win32.obj build\game32.obj -nostdlib -lkernel32 -luser32 -Wl,--subsystem,console -Wl,-e__start
    if errorlevel 1 goto :error
    goto :success
)

where mingw32-gcc >nul 2>&1
if %errorlevel%==0 (
    echo Using mingw32-gcc...
    mingw32-gcc -o build\glyph32.exe build\entry32.obj build\frame32.obj build\input32.obj build\timing32.obj build\console32.obj build\input_win32.obj build\timing_win32.obj build\game32.obj -nostdlib -lkernel32 -luser32 -Wl,--subsystem,console -Wl,-e__start
    if errorlevel 1 goto :error
    goto :success
)

where gcc >nul 2>&1
if %errorlevel%==0 (
    echo Using gcc -m32...
    gcc -m32 -o build\glyph32.exe build\entry32.obj build\frame32.obj build\input32.obj build\timing32.obj build\console32.obj build\input_win32.obj build\timing_win32.obj build\game32.obj -nostdlib -lkernel32 -luser32 -Wl,--subsystem,console -Wl,-e__start
    if errorlevel 1 goto :error
    goto :success
)

echo ERROR: No 32-bit GCC found!
echo Please install MinGW-w32 (i686-w64-mingw32-gcc)
echo Or ensure your GCC supports -m32
goto :error

:success
echo.
echo   ╔═══════════════════════════════════════╗
echo   ║     BUILD SUCCESSFUL!                 ║
echo   ║     Run: build\glyph32.exe            ║
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
