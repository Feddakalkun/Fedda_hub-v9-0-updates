# Portability Test Script
# Verifies installation is portable and has no system dependencies

$ErrorActionPreference = "Continue"
$RootPath = Split-Path -Parent $PSScriptRoot
$PassedTests = 0
$FailedTests = 0

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " PORTABILITY VERIFICATION TEST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Python
Write-Host "[1] Testing Python..." -NoNewline
$PyExe = Join-Path $RootPath "python_embeded\python.exe"
if (Test-Path $PyExe) {
    $version = & $PyExe --version 2>&1
    if ($version -match "3.11.9") {
        Write-Host " OK (v3.11.9)" -ForegroundColor Green
        $PassedTests++
    } else {
        Write-Host " FAIL (wrong version)" -ForegroundColor Red
        $FailedTests++
    }
} else {
    Write-Host " FAIL (not found)" -ForegroundColor Red
    $FailedTests++
}

# Test 2: Git
Write-Host "[2] Testing Git..." -NoNewline
$GitExe = Join-Path $RootPath "git_embeded\cmd\git.exe"
if (Test-Path $GitExe) {
    Write-Host " OK" -ForegroundColor Green
    $PassedTests++
} else {
    Write-Host " FAIL (not found)" -ForegroundColor Red
    $FailedTests++
}

# Test 3: Node.js
Write-Host "[3] Testing Node.js..." -NoNewline
$NodeExe = Join-Path $RootPath "node_embeded\node.exe"
if (Test-Path $NodeExe) {
    Write-Host " OK" -ForegroundColor Green
    $PassedTests++
} else {
    Write-Host " FAIL (not found)" -ForegroundColor Red
    $FailedTests++
}

# Test 4: ComfyUI
Write-Host "[4] Testing ComfyUI..." -NoNewline
$ComfyMain = Join-Path $RootPath "ComfyUI\main.py"
if (Test-Path $ComfyMain) {
    Write-Host " OK" -ForegroundColor Green
    $PassedTests++
} else {
    Write-Host " FAIL (not found)" -ForegroundColor Red
    $FailedTests++
}

# Test 5: Fedda Hub
Write-Host "[5] Testing Fedda Hub..." -NoNewline
$HubPackage = Join-Path $RootPath "fedda-hub\package.json"
if (Test-Path $HubPackage) {
    Write-Host " OK" -ForegroundColor Green
    $PassedTests++
} else {
    Write-Host " FAIL (not found)" -ForegroundColor Red
    $FailedTests++
}

# Test 6: PyTorch
Write-Host "[6] Testing PyTorch..." -NoNewline
$torchTest = & $PyExe -c "import torch; print(torch.__version__)" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host " OK ($torchTest)" -ForegroundColor Green
    $PassedTests++
} else {
    Write-Host " FAIL (not installed)" -ForegroundColor Red
    $FailedTests++
}

# Test 7: CUDA availability
Write-Host "[7] Testing CUDA support..." -NoNewline
$cudaTest = & $PyExe -c "import torch; print(torch.cuda.is_available())" 2>&1
if ($cudaTest -match "True") {
    Write-Host " OK (CUDA enabled)" -ForegroundColor Green
    $PassedTests++
} elseif ($cudaTest -match "False") {
    Write-Host " OK (CPU mode)" -ForegroundColor Yellow
    $PassedTests++
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $FailedTests++
}

# Test 8: Critical Python packages
Write-Host "[8] Testing Python packages..." -NoNewline
$packages = @('transformers', 'diffusers', 'accelerate', 'omegaconf')
$allOK = $true
foreach ($pkg in $packages) {
    $test = & $PyExe -c "import $pkg" 2>&1
    if ($LASTEXITCODE -ne 0) {
        $allOK = $false
        break
    }
}
if ($allOK) {
    Write-Host " OK" -ForegroundColor Green
    $PassedTests++
} else {
    Write-Host " FAIL (packages missing)" -ForegroundColor Red
    $FailedTests++
}

# Test 9: ComfyUI Manager
Write-Host "[9] Testing ComfyUI Manager..." -NoNewline
$Manager = Join-Path $RootPath "ComfyUI\custom_nodes\ComfyUI-Manager"
if (Test-Path $Manager) {
    Write-Host " OK" -ForegroundColor Green
    $PassedTests++
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $FailedTests++
}

# Test 10: Installation log
Write-Host "[10] Testing installation log..." -NoNewline
$LogFile = Join-Path $RootPath "logs\install_log.txt"
if (Test-Path $LogFile) {
    Write-Host " OK" -ForegroundColor Green
    $PassedTests++
} else {
    Write-Host " WARN (not installed yet)" -ForegroundColor Yellow
    $PassedTests++
}

# Summary
$TotalTests = $PassedTests + $FailedTests
$PassRate = [math]::Round(($PassedTests / $TotalTests) * 100, 1)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Total Tests: $TotalTests" -ForegroundColor White
Write-Host "Passed: $PassedTests" -ForegroundColor Green
Write-Host "Failed: $FailedTests" -ForegroundColor Red
Write-Host "Pass Rate: $PassRate%" -ForegroundColor $(if ($PassRate -ge 90) { "Green" } else { "Yellow" })

if ($PassRate -ge 95) {
    Write-Host "`n[OK] READY FOR DISTRIBUTION" -ForegroundColor Green
} elseif ($PassRate -ge 80) {
    Write-Host "`n[WARN] Minor issues detected" -ForegroundColor Yellow
} else {
    Write-Host "`n[FAIL] Fix issues before distribution" -ForegroundColor Red
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
