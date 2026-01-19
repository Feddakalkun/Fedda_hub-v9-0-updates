# GPU Detection Test Script
# Tests the GPU detection logic before running full installation

$ErrorActionPreference = "Continue"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " GPU DETECTION TEST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Video Controller Detection
Write-Host "[Test 1] Detecting Video Controllers..." -ForegroundColor Yellow
$videoControllers = Get-WmiObject Win32_VideoController -ErrorAction SilentlyContinue

if ($videoControllers) {
    foreach ($gpu in $videoControllers) {
        Write-Host "  Found: $($gpu.Name)" -ForegroundColor White
        Write-Host "    Driver Version: $($gpu.DriverVersion)" -ForegroundColor Gray
        Write-Host "    Video Memory: $([math]::Round($gpu.AdapterRAM / 1GB, 2)) GB`n" -ForegroundColor Gray
    }
} else {
    Write-Host "  No video controllers detected!" -ForegroundColor Red
}

# Test 2: NVIDIA GPU Detection
Write-Host "`n[Test 2] NVIDIA GPU Detection..." -ForegroundColor Yellow
$nvidiaGPU = Get-WmiObject Win32_VideoController -ErrorAction SilentlyContinue | 
             Where-Object { $_.Name -match "NVIDIA" }

if ($nvidiaGPU) {
    Write-Host "  [OK] NVIDIA GPU Found: $($nvidiaGPU.Name)" -ForegroundColor Green
    
    # Test 3: nvidia-smi Detection
    Write-Host "`n[Test 3] NVIDIA Driver Detection (nvidia-smi)..." -ForegroundColor Yellow
    try {
        $nvidiaSmi = & nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] nvidia-smi found!" -ForegroundColor Green
            Write-Host "  Driver Version: $nvidiaSmi" -ForegroundColor White
            
            $driverVersion = [version]($nvidiaSmi -replace '[^0-9.]','')
            Write-Host "  Parsed Version: $($driverVersion.Major).$($driverVersion.Minor)" -ForegroundColor White
            
            if ($driverVersion.Major -ge 545) {
                Write-Host "  [OK] CUDA 12.4 Compatible (Driver >= 545)" -ForegroundColor Green
                $recommendedMode = "cuda124"
            }
            elseif ($driverVersion.Major -ge 450) {
                Write-Host "  [WARN] CUDA 11.8 Compatible (Driver 450-544)" -ForegroundColor Yellow
                $recommendedMode = "cuda118"
            }
            else {
                Write-Host "  [WARN] Driver too old for CUDA support" -ForegroundColor Red
                $recommendedMode = "cpu"
            }
        }
        else {
            Write-Host "  [FAIL] nvidia-smi not working" -ForegroundColor Red
            $recommendedMode = "cuda124"  # Assume latest if GPU present
        }
    }
    catch {
        Write-Host "  [FAIL] nvidia-smi not found: $($_.Exception.Message)" -ForegroundColor Red
        $recommendedMode = "cuda124"  # Assume latest if GPU present
    }
}
else {
    Write-Host "  [INFO] No NVIDIA GPU detected" -ForegroundColor Yellow
    
    # Check for AMD
    $amdGPU = Get-WmiObject Win32_VideoController -ErrorAction SilentlyContinue | 
              Where-Object { $_.Name -match "AMD|Radeon" }
    
    if ($amdGPU) {
        Write-Host "  [WARN] AMD GPU Found: $($amdGPU.Name)" -ForegroundColor Yellow
        Write-Host "  DirectML support not yet implemented" -ForegroundColor Yellow
        $recommendedMode = "cpu"
    }
    else {
        Write-Host "  Using integrated graphics" -ForegroundColor Gray
        $recommendedMode = "cpu"
    }
}

# Final Recommendation
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " RECOMMENDATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Installation Mode: " -NoNewline -ForegroundColor White
switch ($recommendedMode) {
    "cuda124" { 
        Write-Host "CUDA 12.4 (GPU Accelerated)" -ForegroundColor Green
        Write-Host "`nPackages that will be installed:" -ForegroundColor White
        Write-Host "  - PyTorch 2.5.1 + CUDA 12.4" -ForegroundColor Gray
        Write-Host "  - Xformers (GPU acceleration)" -ForegroundColor Gray
        Write-Host "  - Triton + SageAttention" -ForegroundColor Gray
        Write-Host "  - llama-cpp-python + CUDA 12.4" -ForegroundColor Gray
    }
    "cuda118" { 
        Write-Host "CUDA 11.8 (GPU Accelerated - Older Driver)" -ForegroundColor Yellow
        Write-Host "`nPackages that will be installed:" -ForegroundColor White
        Write-Host "  - PyTorch 2.5.1 + CUDA 11.8" -ForegroundColor Gray
        Write-Host "  - Xformers (GPU acceleration)" -ForegroundColor Gray
        Write-Host "  - llama-cpp-python + CUDA 11.8" -ForegroundColor Gray
        Write-Host "`nNOTE: Triton and SageAttention require CUDA 12.x" -ForegroundColor Yellow
    }
    "cpu" { 
        Write-Host "CPU-Only (Compatible with all systems)" -ForegroundColor Cyan
        Write-Host "`nPackages that will be installed:" -ForegroundColor White
        Write-Host "  - PyTorch 2.5.1 (CPU-only)" -ForegroundColor Gray
        Write-Host "  - llama-cpp-python (CPU-only)" -ForegroundColor Gray
        Write-Host "`nNOTE: Processing will be slower than GPU acceleration" -ForegroundColor Yellow
    }
}

Write-Host "`n========================================`n" -ForegroundColor Cyan

# Performance expectations
Write-Host "Expected Performance:" -ForegroundColor White
if ($recommendedMode -match "cuda") {
    Write-Host "  Image Generation: ~5-30 seconds (depending on model)" -ForegroundColor Green
    Write-Host "  Video Generation: ~1-5 minutes (depending on length)" -ForegroundColor Green
}
else {
    Write-Host "  Image Generation: ~30-120 seconds (depending on model)" -ForegroundColor Yellow
    Write-Host "  Video Generation: ~5-20 minutes (depending on length)" -ForegroundColor Yellow
    Write-Host "`n  Consider upgrading to an NVIDIA GPU for better performance" -ForegroundColor Cyan
}

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

