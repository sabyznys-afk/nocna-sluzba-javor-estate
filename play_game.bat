@echo off
title NIGHT SHIFT: BLOCK 14 (1995 Residential District Horror)
echo ============================================================
echo   NIGHT SHIFT: BLOCK 14 — Launching Godot 4.7.2...
echo   Controls:
echo     WASD       : Walk
echo     [C]        : Fast Walk
echo     [Shift]    : Sprint (Watch Stamina)
echo     [Ctrl]     : Crouch
echo     [1]-[5]    : Torch / Taser / Keys / Radio / Watch
echo     [H]        : Toggle Walkman Headphones
echo     [F] / [R]  : Toggle Flashlight / Reload 4.5V Battery
echo     [TAB]/[N]  : Field Notebook (Check Anomalies + Write Notes)
echo     [E]        : Interact (Doors, Switches, Drawers, Clocks, CCTV)
echo     [F9]       : Developer Asset Manager (Debug Build)
echo ============================================================

set "GODOT_EXE=C:\Users\arnos\Godot\Godot.exe"
set "PROJECT_DIR=D:\nocna-zmena-blok-14"

if not exist "%GODOT_EXE%" (
    echo [ERROR] Godot executable not found at "%GODOT_EXE%"
    pause
    exit /b 1
)

start "" "%GODOT_EXE%" --path "%PROJECT_DIR%"
