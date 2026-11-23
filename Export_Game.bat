@echo off
chcp 65001 >nul
echo Exporting NIGHT SHIFT: BLOCK 14 for Windows (build\windows\NightShift_Block14.exe)...
if not exist "D:\nocna-zmena-blok-14\build\windows" mkdir "D:\nocna-zmena-blok-14\build\windows"
"C:\Users\arnos\Godot\Godot.exe" --headless --export-release "Windows Desktop" "D:\nocna-zmena-blok-14\build\windows\NightShift_Block14.exe" --path "D:\nocna-zmena-blok-14"
echo.
echo Done! Exported build located at: D:\nocna-zmena-blok-14\build\windows\NightShift_Block14.exe
explorer "D:\nocna-zmena-blok-14\build\windows"
pause
