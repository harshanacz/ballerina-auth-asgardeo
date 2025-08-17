#!/bin/bash

# Start script for the Ballerina Auth application

echo "🚀 Starting Ballerina Authentication Application"
echo "=============================================="

# Check if Ballerina is installed
if ! command -v bal &> /dev/null; then
    echo "❌ Ballerina is not installed. Please install Ballerina first."
    echo "   Download from: https://ballerina.io/downloads/"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    echo "   Download from: https://nodejs.org/"
    exit 1
fi

echo "✅ Dependencies check passed"
echo ""

# Function to start Ballerina service
start_ballerina() {
    echo "🔧 Starting Ballerina Authentication Service..."
    cd bal-backend
    bal run &
    BALLERINA_PID=$!
    cd ..
    echo "✅ Ballerina service started (PID: $BALLERINA_PID)"
}

# Function to start Next.js app
start_nextjs() {
    echo "🔧 Starting Next.js Frontend..."
    cd client
    
    # Install dependencies if node_modules doesn't exist
    if [ ! -d "node_modules" ]; then
        echo "📦 Installing Next.js dependencies..."
        npm install
    fi
    
    npm run dev &
    NEXTJS_PID=$!
    cd ..
    echo "✅ Next.js app started (PID: $NEXTJS_PID)"
}

# Start services
start_ballerina
sleep 3  # Give Ballerina time to start
start_nextjs

echo ""
echo "🎉 Application started successfully!"
echo "📍 Frontend: http://localhost:3000"
echo "📍 Backend API: http://localhost:8080"
echo ""
echo "Press Ctrl+C to stop all services"

# Wait for user interrupt
trap 'echo ""; echo "🛑 Stopping services..."; kill $BALLERINA_PID $NEXTJS_PID 2>/dev/null; echo "✅ All services stopped"; exit 0' INT

# Keep script running
wait
