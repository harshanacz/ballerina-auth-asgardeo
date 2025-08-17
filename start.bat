@echo off

echo 🚀 Starting Ballerina Authentication Application
echo ==============================================

REM Check if Ballerina is installed
where bal >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Ballerina is not installed. Please install Ballerina first.
    echo    Download from: https://ballerina.io/downloads/
    pause
    exit /b 1
)

REM Check if Node.js is installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed. Please install Node.js first.
    echo    Download from: https://nodejs.org/
    pause
    exit /b 1
)

echo ✅ Dependencies check passed
echo.

echo 🔧 Starting Ballerina Authentication Service...
cd bal-backend
start "Ballerina Auth Service" cmd /k "bal run"
cd ..
echo ✅ Ballerina service starting...

timeout /t 3 /nobreak >nul

echo 🔧 Starting Next.js Frontend...
cd client

REM Install dependencies if node_modules doesn't exist
if not exist "node_modules" (
    echo 📦 Installing Next.js dependencies...
    call npm install
)

start "Next.js Frontend" cmd /k "npm run dev"
cd ..
echo ✅ Next.js app starting...

echo.
echo 🎉 Application started successfully!
echo 📍 Frontend: http://localhost:3000
echo 📍 Backend API: http://localhost:8080
echo.
echo Press any key to exit...
pause >nul
