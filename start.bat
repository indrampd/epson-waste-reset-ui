@echo off
setlocal
cd /d "%~dp0"

echo === Epson Waste Reset UI ===
echo Based on RxNaison/Epson-Waste-Reset

where node >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: Node.js tidak ditemukan. Silakan download dan install Node.js dari https://nodejs.org/
    pause
    exit /b 1
)

echo Menjalankan EWR UI Server...
start "" "http://127.0.0.1:3827"
node server.js
