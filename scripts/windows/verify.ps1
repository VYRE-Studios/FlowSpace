#!/usr/bin/env pwsh
# FlowSpace Development Environment Verification Script

Write-Host "🚀 FlowSpace Environment Verification" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

$errors = @()
$warnings = @()

# Check Node.js
Write-Host "Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "  ✓ Node.js: $nodeVersion" -ForegroundColor Green
    if ($nodeVersion -match "v(\d+)\.") {
        $major = [int]$matches[1]
        if ($major -lt 18) {
            $warnings += "Node.js version should be 18+, found $nodeVersion"
        }
    }
} catch {
    $errors += "Node.js not found. Install from https://nodejs.org"
}

# Check PostgreSQL
Write-Host "Checking PostgreSQL..." -ForegroundColor Yellow
try {
    $pgResult = psql --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ PostgreSQL: $pgResult" -ForegroundColor Green
    } else {
        $warnings += "PostgreSQL CLI not in PATH"
    }
} catch {
    $warnings += "PostgreSQL not found. Install from https://postgresql.org"
}

# Check Redis
Write-Host "Checking Redis..." -ForegroundColor Yellow
try {
    $redisResult = redis-cli --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Redis: $redisResult" -ForegroundColor Green
    } else {
        $warnings += "Redis CLI not in PATH (optional if using Docker)"
    }
} catch {
    $warnings += "Redis not found (can use Docker instead)"
}

# Check MinIO
Write-Host "Checking MinIO..." -ForegroundColor Yellow
try {
    $minioResult = minio --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ MinIO installed" -ForegroundColor Green
    } else {
        $warnings += "MinIO not found. Download from https://min.io/download"
    }
} catch {
    $warnings += "MinIO not found. Download from https://min.io/download"
}

# Check Flutter
Write-Host "Checking Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-String -Pattern "Flutter (\d+\.\d+\.\d+)"
    if ($flutterVersion) {
        Write-Host "  ✓ Flutter: $($flutterVersion.Matches.Groups[0].Value)" -ForegroundColor Green
    } else {
        $warnings += "Could not parse Flutter version"
    }
} catch {
    $errors += "Flutter not found. Install from https://flutter.dev"
}

# Check backend dependencies
Write-Host "`nChecking backend..." -ForegroundColor Yellow
if (Test-Path "C:\FlowSpace\backend\node_modules") {
    Write-Host "  ✓ Backend dependencies installed" -ForegroundColor Green
} else {
    $warnings += "Backend dependencies not installed. Run: cd backend; npm install"
}

# Check backend .env
if (Test-Path "C:\FlowSpace\backend\.env") {
    Write-Host "  ✓ Backend .env configured" -ForegroundColor Green
} else {
    $errors += "Backend .env missing"
}

# Try to compile backend
Write-Host "  Compiling backend TypeScript..." -ForegroundColor Yellow
Push-Location "C:\FlowSpace\backend"
try {
    $buildResult = npm run build 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Backend compiles successfully" -ForegroundColor Green
    } else {
        $errors += "Backend compilation failed"
    }
} catch {
    $errors += "Could not run backend build"
}
Pop-Location

# Check Prisma schema
if (Test-Path "C:\FlowSpace\backend\prisma\schema.prisma") {
    Write-Host "  ✓ Prisma schema exists" -ForegroundColor Green
} else {
    $errors += "Prisma schema missing"
}

# Check Flutter dependencies
Write-Host "`nChecking Flutter client..." -ForegroundColor Yellow
if (Test-Path "C:\FlowSpace\client_flutter\pubspec.lock") {
    Write-Host "  ✓ Flutter dependencies installed" -ForegroundColor Green
} else {
    $warnings += "Flutter dependencies not installed. Run: cd client_flutter; flutter pub get"
}

# Check running services
Write-Host "`nChecking running services..." -ForegroundColor Yellow

# Check PostgreSQL
try {
    $pgCheck = Test-NetConnection -ComputerName localhost -Port 5432 -WarningAction SilentlyContinue
    if ($pgCheck.TcpTestSucceeded) {
        Write-Host "  ✓ PostgreSQL running on port 5432" -ForegroundColor Green
    } else {
        $warnings += "PostgreSQL not running on port 5432"
    }
} catch {
    $warnings += "Could not check PostgreSQL"
}

# Check Redis
try {
    $redisCheck = Test-NetConnection -ComputerName localhost -Port 6379 -WarningAction SilentlyContinue
    if ($redisCheck.TcpTestSucceeded) {
        Write-Host "  ✓ Redis running on port 6379" -ForegroundColor Green
    } else {
        $warnings += "Redis not running on port 6379"
    }
} catch {
    $warnings += "Could not check Redis"
}

# Check MinIO
try {
    $minioCheck = Test-NetConnection -ComputerName localhost -Port 9000 -WarningAction SilentlyContinue
    if ($minioCheck.TcpTestSucceeded) {
        Write-Host "  ✓ MinIO running on port 9000" -ForegroundColor Green
    } else {
        $warnings += "MinIO not running on port 9000"
    }
} catch {
    $warnings += "Could not check MinIO"
}

# Check Kratos
try {
    $kratosCheck = Test-NetConnection -ComputerName localhost -Port 4433 -WarningAction SilentlyContinue
    if ($kratosCheck.TcpTestSucceeded) {
        Write-Host "  ✓ Kratos running on port 4433" -ForegroundColor Green
    } else {
        $warnings += "Kratos not running on port 4433"
    }
} catch {
    $warnings += "Could not check Kratos"
}

# Summary
Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✅ All checks passed! Environment ready." -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Start PostgreSQL, Redis, MinIO, Kratos services"
    Write-Host "  2. cd backend; npx prisma migrate dev  # Run migrations"
    Write-Host "  3. cd backend; npm run start:dev       # Start API server"
    Write-Host "  4. cd client_flutter; flutter run      # Launch Flutter app"
    exit 0
}

if ($errors.Count -gt 0) {
    Write-Host "❌ Errors found:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
    Write-Host ""
}

if ($warnings.Count -gt 0) {
    Write-Host "⚠️  Warnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($errors.Count -gt 0) {
    Write-Host "Fix errors before proceeding." -ForegroundColor Red
    exit 1
} else {
    Write-Host "Warnings found but can proceed with caution." -ForegroundColor Yellow
    exit 0
}
