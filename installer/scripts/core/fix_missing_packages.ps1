# ============================================================================
# Fix Missing Packages - Production Quality Installer
# ============================================================================

$ErrorActionPreference = "Stop"
$RootPath = Split-Path -Parent $PSScriptRoot
$PyExe = Join-Path $RootPath "python_embeded\python.exe"

function Write-Status {
    param([string]$Message, [string]$Type = "INFO")
    $Color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    Write-Host "[$Type] $Message" -ForegroundColor $Color
}

function Detect-GPUCapability {
    try {
        $nvidiaGPU = Get-WmiObject Win32_VideoController -ErrorAction SilentlyContinue | 
                     Where-Object { $_.Name -match "NVIDIA" }
        
        if ($nvidiaGPU) {
            Write-Status "NVIDIA GPU detected: $($nvidiaGPU.Name)" "SUCCESS"
            try {
                $nvidiaSmi = & nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $driverVersion = [version]($nvidiaSmi -replace '[^0-9.]','')
                    if ($driverVersion.Major -ge 545) {
                        return "cuda124"
                    }
                    elseif ($driverVersion.Major -ge 450) {
                        return "cuda118"
                    }
                }
            }
            catch {
                return "cuda124"  # Default assumption
            }
            return "cuda124"
        }
        
        Write-Status "No NVIDIA GPU detected, using CPU mode" "WARNING"
        return "cpu"
    }
    catch {
        Write-Status "GPU detection failed, defaulting to CPU" "WARNING"
        return "cpu"
    }
}

function Install-Package {
    param([string]$PackageName, [string]$ExtraArgs = "")
    
    Write-Status "Installing $PackageName..." "INFO"
    
    $ArgList = "-m pip install $PackageName $ExtraArgs --no-warn-script-location"
    $Process = Start-Process -FilePath $PyExe -ArgumentList $ArgList -NoNewWindow -Wait -PassThru
    
    if ($Process.ExitCode -eq 0) {
        Write-Status "$PackageName installed successfully" "SUCCESS"
        return $true
    } else {
        Write-Status "$PackageName installation failed (exit code: $($Process.ExitCode))" "ERROR"
        return $false
    }
}

Write-Status "=== Starting Missing Packages Installation ===" "INFO"

# Detect GPU mode
$gpuMode = Detect-GPUCapability
Write-Status "GPU Mode: $gpuMode" "INFO"


# 1. Install build tools first
Write-Status "`n[1/6] Installing Build Tools..." "INFO"
Install-Package "ninja"
Install-Package "scikit-build-core"
Install-Package "Cython"

# 2. Fix pynvml deprecation warning
Write-Status "`n[2/6] Fixing pynvml deprecation..." "INFO"
& $PyExe -m pip uninstall -y pynvml 2>&1 | Out-Null
Install-Package "nvidia-ml-py"

# 3. Install insightface (critical for face recognition)
Write-Status "`n[3/6] Installing insightface..." "INFO"
# Try prebuilt wheel first, then fallback to source
if (-not (Install-Package "insightface" "--prefer-binary --no-build-isolation")) {
    Write-Status "Trying alternative insightface installation method..." "WARNING"
    Install-Package "insightface" "--no-build-isolation"
}

# 4. Install onnxruntime-gpu (for rembg and other nodes)
Write-Status "`n[4/6] Installing onnxruntime-gpu..." "INFO"
Install-Package "onnxruntime-gpu"

# 5. Install llama-cpp-python (for LLM nodes)
Write-Status "`n[5/6] Installing llama-cpp-python..." "INFO"
if ($gpuMode -eq "cuda124") {
    Write-Status "Installing llama-cpp-python with CUDA 12.4 support..." "INFO"
    if (-not (Install-Package "llama-cpp-python" "--prefer-binary --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu124")) {
        Write-Status "CUDA 12.4 wheel failed, trying CUDA 11.8..." "WARNING"
        Install-Package "llama-cpp-python" "--prefer-binary --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu118"
    }
}
elseif ($gpuMode -eq "cuda118") {
    Write-Status "Installing llama-cpp-python with CUDA 11.8 support..." "INFO"
    Install-Package "llama-cpp-python" "--prefer-binary --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu118"
}
else {
    Write-Status "Installing llama-cpp-python (CPU-only)..." "INFO"
    Install-Package "llama-cpp-python" "--prefer-binary"
}

# 6. Verify opencv setup (ensure proper variant installed)
Write-Status "`n[6/6] Verifying OpenCV installation..." "INFO"
& $PyExe -c "import cv2; print(f'OpenCV version: {cv2.__version__}')"

Write-Status "`n=== Installation Complete! ===" "SUCCESS"
Write-Status "Running verification test..." "INFO"

# Run verification test
& $PyExe -c @"
import sys
packages = ['cv2', 'insightface', 'ninja', 'onnxruntime']
failed = []
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✓ {pkg}')
    except ImportError as e:
        print(f'✗ {pkg}: {e}')
        failed.append(pkg)

if failed:
    print(f'\nFailed to import: {failed}')
    sys.exit(1)
else:
    print('\n✓ All critical packages verified!')
    sys.exit(0)
"@

if ($LASTEXITCODE -eq 0) {
    Write-Status "`nAll packages installed and verified successfully!" "SUCCESS"
} else {
    Write-Status "`nSome packages failed verification. Please review errors above." "ERROR"
}

Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
