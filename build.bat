@echo off
title Laymo - UI Build
echo.
echo Building Laymo UI (one-time step for distribution)...
echo.

cd /d "%~dp0ui"
if not exist "package.json" (
    echo ERROR: ui\package.json not found.
    pause
    exit /b 1
)

echo Running: npm install
call npm install
if errorlevel 1 (
    echo.
    echo ERROR: npm install failed. Install Node.js from https://nodejs.org
    pause
    exit /b 1
)

echo.
echo Running: npm run build
call npm run build
if errorlevel 1 (
    echo.
    echo ERROR: npm run build failed.
    pause
    exit /b 1
)

echo.
echo Build complete. ui\dist is ready.
echo You can now zip the entire bs_laymo folder and share it.
echo End users do NOT need Node.js to use the resource.
echo.
pause
