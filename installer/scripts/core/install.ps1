# ============================================================================ 
# FEDDAKALKUN ComfyUI - Ultimate Portable Installer
# ============================================================================ 

$ErrorActionPreference = "Stop"
$ScriptPath = $PSScriptRoot
# Go up two levels: scripts/core -> scripts -> installer -> root
$RootPath = Split-Path (Split-Path (Split-Path $ScriptPath -Parent) -Parent) -Parent
$RootPath = (Resolve-Path $RootPath).Path  # Ensure absolute path
Set-Location $RootPath

# Toggle to pause after each major step for review
$PauseEachStep = $false

Write-Host "Installation root: $RootPath"


# ============================================================================ 
# ENHANCED LOGGING SYSTEM
# ============================================================================ 
$LogsDir = Join-Path $RootPath "logs"
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir | Out-Null }

# Separate log files for different phases
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile = Join-Path $LogsDir "install_log_$Timestamp.txt"
$ErrorLogFile = Join-Path $LogsDir "install_errors_$Timestamp.txt"
$SummaryLogFile = Join-Path $LogsDir "install_summary.txt"
$ProgressFile = Join-Path $LogsDir "install_progress.json"

# Installation state tracking
$InstallState = @{
    StartTime      = Get-Date
    Phase          = "Initialization"
    CompletedSteps = @()
    FailedSteps    = @()
    Warnings       = @()
    GPUMode        = "unknown"
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"  # INFO, WARNING, ERROR, SUCCESS
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    
    # Color-coded console output
    $Color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host $LogEntry -ForegroundColor $Color
    
    # Write to main log file
    $MaxRetries = 5
    $RetryCount = 0
    while ($RetryCount -lt $MaxRetries) {
        try {
            Add-Content -Path $LogFile -Value $LogEntry -ErrorAction Stop
            break
        }
        catch {
            $RetryCount++
            Start-Sleep -Milliseconds 100
            if ($RetryCount -eq $MaxRetries) {
                Write-Host "[WARNING] Could not write to log file after $MaxRetries attempts" -ForegroundColor Yellow
            }
        }
    }
    
    # Write errors to separate error log
    if ($Level -eq "ERROR") {
        try {
            Add-Content -Path $ErrorLogFile -Value $LogEntry -ErrorAction SilentlyContinue
            $InstallState.FailedSteps += $Message
        }
        catch { }
    }
    
    # Track warnings
    if ($Level -eq "WARNING") {
        $InstallState.Warnings += $Message
    }
}

function Write-Phase {
    param([string]$PhaseName)
    $InstallState.Phase = $PhaseName
    Write-Log "`n========================================" "INFO"
    Write-Log "  PHASE: $PhaseName" "INFO"
    Write-Log "========================================" "INFO"
    Save-Progress
}

function Write-Step {
    param([string]$StepName, [string]$Status = "STARTED")
    if ($Status -eq "COMPLETED") {
        Write-Log "✓ $StepName" "SUCCESS"
        $InstallState.CompletedSteps += $StepName
    }
    elseif ($Status -eq "FAILED") {
        Write-Log "✗ $StepName" "ERROR"
    }
    elseif ($Status -eq "SKIPPED") {
        Write-Log "○ $StepName (skipped)" "INFO"
    }
    else {
        Write-Log "→ $StepName..." "INFO"
    }
    Save-Progress
}

function Save-Progress {
    try {
        $ProgressData = @{
            LastUpdate     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Phase          = $InstallState.Phase
            CompletedSteps = $InstallState.CompletedSteps
            FailedSteps    = $InstallState.FailedSteps
            Warnings       = $InstallState.Warnings
            GPUMode        = $InstallState.GPUMode
        }
        $ProgressData | ConvertTo-Json -Depth 10 | Set-Content -Path $ProgressFile -ErrorAction SilentlyContinue
    }
    catch {
        # Silent fail - progress tracking is non-critical
    }
}

function Write-Summary {
    $Duration = ((Get-Date) - $InstallState.StartTime).ToString("hh\:mm\:ss")
    $SummaryContent = @"
================================================================================
FEDDA HUB INSTALLATION SUMMARY
================================================================================
Installation Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Duration: $Duration
GPU Mode: $($InstallState.GPUMode)

COMPLETED STEPS ($($InstallState.CompletedSteps.Count)):
$($InstallState.CompletedSteps | ForEach-Object { "  ✓ $_" } | Out-String)

FAILED STEPS ($($InstallState.FailedSteps.Count)):
$($InstallState.FailedSteps | ForEach-Object { "  ✗ $_" } | Out-String)

WARNINGS ($($InstallState.Warnings.Count)):
$($InstallState.Warnings | ForEach-Object { "  ⚠ $_" } | Out-String)

LOG FILES:
  Main Log: $LogFile
  Error Log: $ErrorLogFile
  
STATUS: $(if ($InstallState.FailedSteps.Count -eq 0) { "SUCCESS ✓" } else { "COMPLETED WITH ERRORS ⚠" })
================================================================================
"@
    
    Write-Host "`n$SummaryContent" -ForegroundColor Cyan
    Set-Content -Path $SummaryLogFile -Value $SummaryContent
    Write-Log "Installation summary saved to: $SummaryLogFile" "INFO"
}

function Download-File {
    param([string]$Url, [string]$Dest)
    if (-not (Test-Path $Dest)) {
        Write-Log "Downloading $(Split-Path $Dest -Leaf)..."
        
        $success = $false
        

        $success = $false
        
        # PRIMARY METHOD: Curl (Fastest)
        try {
            & curl.exe -L -o $Dest $Url --progress-bar --fail --retry 3 --retry-delay 2
            if ($LASTEXITCODE -eq 0) {
                $success = $true
            }
        }
        catch {
            Write-Log "Curl failed: $($_.Exception.Message)"
        }

        
        # Final fallback to Invoke-WebRequest
        if (-not $success) {
            try {
                Write-Log "Falling back to Invoke-WebRequest..."
                Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
                $success = $true
            }
            catch {
                Write-Log "ERROR: All download methods failed for $Url"
                throw $_
            }
        }
        
        if ($success) {
            Write-Log "Successfully downloaded $(Split-Path $Dest -Leaf)"
        }
    }
}

function Extract-Zip {
    param([string]$ZipFile, [string]$DestDir)
    Write-Log "Extracting $(Split-Path $ZipFile -Leaf)..."
    Expand-Archive -Path $ZipFile -DestinationPath $DestDir -Force
}

# Pause helper for step-by-step review
function Pause-Step {
    if ($PauseEachStep) {
        Read-Host "Step complete. Press Enter to continue"
    }
}

# ============================================================================ 
# GPU DETECTION for Cross-Platform Compatibility
# ============================================================================ 
function Detect-GPUCapability {
    Write-Log "`n[GPU Detection] Analyzing system hardware..." "INFO"
    
    try {
        # Check for NVIDIA GPU
        $nvidiaGPU = Get-WmiObject Win32_VideoController -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -match "NVIDIA" }
        
        if ($nvidiaGPU) {
            Write-Log "[GPU Detection] ✓ NVIDIA GPU found: $($nvidiaGPU.Name)" "SUCCESS"
            
            # Try to get CUDA version from nvidia-smi
            try {
                $nvidiaSmi = & nvidia-smi --query-gpu=driver_version --format=csv, noheader 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "[GPU Detection] ✓ NVIDIA Driver: $nvidiaSmi" "SUCCESS"
                    $driverVersion = [version]($nvidiaSmi -replace '[^0-9.]', '')
                    
                    # Driver 545+ supports CUDA 12.x
                    if ($driverVersion.Major -ge 545) {
                        Write-Log "[GPU Detection] ✓ CUDA 12.4 compatible driver detected" "SUCCESS"
                        $InstallState.GPUMode = "cuda124"
                        return "cuda124"
                    }
                    # Driver 450-544 supports CUDA 11.x
                    elseif ($driverVersion.Major -ge 450) {
                        Write-Log "[GPU Detection] ⚠ Older driver detected, using CUDA 11.8" "WARNING"
                        $InstallState.GPUMode = "cuda118"
                        return "cuda118"
                    }
                }
            }
            catch {
                Write-Log "[GPU Detection] ⚠ nvidia-smi not found, assuming CUDA 12.4 support" "WARNING"
            }
            
            # Default to CUDA 12.4 if NVIDIA GPU detected but can't determine version
            $InstallState.GPUMode = "cuda124"
            return "cuda124"
        }
        
        # Check for AMD GPU
        $amdGPU = Get-WmiObject Win32_VideoController -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -match "AMD|Radeon" }
        
        if ($amdGPU) {
            Write-Log "[GPU Detection] ⚠ AMD GPU found: $($amdGPU.Name)" "WARNING"
            Write-Log "[GPU Detection] DirectML support will be used (CPU fallback for now)" "WARNING"
            $InstallState.GPUMode = "cpu"
            return "cpu"  # Future: Add DirectML support
        }
        
        # No dedicated GPU found
        Write-Log "[GPU Detection] ℹ No dedicated GPU detected" "WARNING"
        Write-Log "[GPU Detection] Installing CPU-only version (slower but compatible)" "INFO"
        $InstallState.GPUMode = "cpu"
        return "cpu"
        
    }
    catch {
        Write-Log "[GPU Detection] ⚠ GPU detection failed: $($_.Exception.Message)" "ERROR"
        Write-Log "[GPU Detection] Defaulting to CPU-only for maximum compatibility" "WARNING"
        $InstallState.GPUMode = "cpu"
        return "cpu"
    }
}

Write-Phase "Bootstrap - Portable Tools Setup"
Write-Log "Installation root: $RootPath" "INFO"
Write-Log "=========================================" "INFO"
Write-Log "Portable Installation Started" "INFO"
Write-Log "=========================================" "INFO"

# ============================================================================ 
# 1. BOOTSTRAP PORTABLE TOOLS
# ============================================================================ 

# --- 1.1 Portable Python ---
$PyDir = Join-Path $RootPath "python_embeded"
$PyExe = Join-Path $PyDir "python.exe"

if (-not (Test-Path $PyExe)) {
    Write-Step "Setting up Portable Python 3.11.9" "STARTED"
    $PyZip = Join-Path $RootPath "python_embed.zip"
    Download-File "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip" $PyZip
    
    New-Item -ItemType Directory -Path $PyDir -Force | Out-Null
    Extract-Zip $PyZip $PyDir
    Remove-Item $PyZip -Force

    # --- CRITICAL FIX: Configure python311._pth ---
    # 1. Enable site-packages (import site)
    # 2. Add ../ComfyUI to path so 'import comfy' works
    $PthFile = Join-Path $PyDir "python311._pth"
    $Content = Get-Content $PthFile
    $Content = $Content -replace "#import site", "import site"
    
    if ($Content -notcontains "../ComfyUI") {
        $Content += "../ComfyUI"
    }
    
    Set-Content -Path $PthFile -Value $Content
    Write-Log "Portable Python configured (Path fixed)." "SUCCESS"

    # Install Pip
    Write-Log "Installing Pip..." "INFO"
    $GetPip = Join-Path $RootPath "get-pip.py"
    Download-File "https://bootstrap.pypa.io/get-pip.py" $GetPip
    Start-Process -FilePath $PyExe -ArgumentList "$GetPip" -NoNewWindow -Wait
    Remove-Item $GetPip -Force
    Write-Step "Setting up Portable Python 3.11.9" "COMPLETED"
}
else {
    Write-Step "Setting up Portable Python 3.11.9" "SKIPPED"
}

Pause-Step

# --- 1.2 Portable Git (MinGit) ---
$GitDir = Join-Path $RootPath "git_embeded"
$GitExe = Join-Path $GitDir "cmd\git.exe"

if (-not (Test-Path $GitExe)) {
    Write-Log "[ComfyUI 2/9] Setting up Portable Git..."
    $GitZip = Join-Path $RootPath "mingit.zip"
    Download-File "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/MinGit-2.43.0-64-bit.zip" $GitZip
    
    New-Item -ItemType Directory -Path $GitDir -Force | Out-Null
    Extract-Zip $GitZip $GitDir
    Remove-Item $GitZip -Force
    Write-Log "Portable Git configured."
}
else {
    Write-Log "[ComfyUI 2/9] Portable Git found."
}

Pause-Step

# --- 1.3 Portable Node.js ---
$NodeDir = Join-Path $RootPath "node_embeded"
$NodeExe = Join-Path $NodeDir "node.exe"

if (-not (Test-Path $NodeExe)) {
    Write-Log "[ComfyUI 3/9] Setting up Portable Node.js..."
    $NodeZip = Join-Path $RootPath "node.zip"
    Download-File "https://nodejs.org/dist/v20.11.0/node-v20.11.0-win-x64.zip" $NodeZip
    
    Extract-Zip $NodeZip $RootPath
    $ExtractedNode = Get-ChildItem -Path $RootPath -Directory -Filter "node-v*-win-x64" | Select-Object -First 1
    if ($ExtractedNode) {
        Rename-Item -Path $ExtractedNode.FullName -NewName "node_embeded"
    }
    Remove-Item $NodeZip -Force
    Write-Log "Portable Node.js configured."
}
else {
    Write-Log "[ComfyUI 3/9] Portable Node.js found."
}

Pause-Step

# Helper to run commands with portable environment
$env:PATH = "$GitDir\cmd;$NodeDir;$PyDir;$PyDir\Scripts;$env:PATH"

function Run-Pip {
    param(
        [string]$Arguments,
        [string]$StepName = "",
        [bool]$Critical = $false
    )
    
    if ($StepName) {
        Write-Step $StepName "STARTED"
    }
    
    $Timestamp = Get-Date -Format 'HHmmss_fff'
    $PipOutFile = Join-Path $LogsDir "pip_${Timestamp}_out.log"
    $PipErrFile = Join-Path $LogsDir "pip_${Timestamp}_err.log"
    Write-Log "Running: pip $Arguments" "INFO"
    
    try {
        $Process = Start-Process -FilePath $PyExe -ArgumentList "-m pip $Arguments" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $PipOutFile -RedirectStandardError $PipErrFile
        $ExitCode = $Process.ExitCode
    }
    catch {
        Write-Log "Failed to execute pip subprocess: $_" "ERROR"
        if ($Critical) { throw }
        return 1
    }
    
    # Output content to console for visibility and save to logical log
    $FullOutput = ""
    if (Test-Path $PipOutFile) {
        $OutContent = Get-Content $PipOutFile -Raw
        if ($OutContent) {
            Write-Host $OutContent -ForegroundColor Gray
            $FullOutput += "STDOUT:`n$OutContent`n"
        }
        Remove-Item $PipOutFile -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $PipErrFile) {
        $ErrContent = Get-Content $PipErrFile -Raw
        if ($ErrContent) {
            Write-Host $ErrContent -ForegroundColor DarkYellow
            $FullOutput += "STDERR:`n$ErrContent`n"
        }
        Remove-Item $PipErrFile -Force -ErrorAction SilentlyContinue
    }
    
    # Save combined output to a single pip log for this run
    $PipLogFile = Join-Path $LogsDir "pip_$Timestamp.log"
    if ($FullOutput) {
        Set-Content -Path $PipLogFile -Value $FullOutput
    }
    
    if ($ExitCode -ne 0) {
        $ErrorMsg = "Pip command failed (Exit Code: $ExitCode)"
        Write-Log $ErrorMsg "WARNING" 
        Write-Log "Full output saved to: $PipLogFile" "INFO"
        
        if ($StepName) {
            Write-Step $StepName "FAILED"
        }
        
        if ($Critical) {
            Write-Log "CRITICAL FAILURE - Installation cannot continue" "ERROR"
            throw $ErrorMsg
        }
    }
    else {
        if ($StepName) {
            Write-Step $StepName "COMPLETED"
        }
    }
    
    return $ExitCode
}

function Run-Git {
    param(
        [string]$Arguments,
        [string]$StepName = ""
    )
    
    if ($StepName) {
        Write-Step $StepName "STARTED"
    }
    
    $Timestamp = Get-Date -Format 'HHmmss_fff'
    $GitOutFile = Join-Path $LogsDir "git_${Timestamp}_out.log"
    $GitErrFile = Join-Path $LogsDir "git_${Timestamp}_err.log"
    Write-Log "Running: git $Arguments" "INFO"
    
    try {
        $Process = Start-Process -FilePath $GitExe -ArgumentList "$Arguments" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $GitOutFile -RedirectStandardError $GitErrFile
        $ExitCode = $Process.ExitCode
    }
    catch {
        Write-Log "Failed to execute git subprocess: $_" "ERROR"
        return 1
    }
    
    # Output content to console
    $FullOutput = ""
    if (Test-Path $GitOutFile) {
        $OutContent = Get-Content $GitOutFile -Raw
        if ($OutContent) {
            Write-Host $OutContent -ForegroundColor Gray
            $FullOutput += "STDOUT:`n$OutContent`n"
        }
        Remove-Item $GitOutFile -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $GitErrFile) {
        $ErrContent = Get-Content $GitErrFile -Raw
        if ($ErrContent) {
            Write-Host $ErrContent -ForegroundColor DarkYellow
            $FullOutput += "STDERR:`n$ErrContent`n"
        }
        Remove-Item $GitErrFile -Force -ErrorAction SilentlyContinue
    }

    if ($ExitCode -ne 0) {
        Write-Log "Git command failed (Exit Code: $ExitCode): $Arguments" "WARNING"
        
        # Save output for failed git commands
        $GitLogFile = Join-Path $LogsDir "git_$Timestamp.log"
        if ($FullOutput) {
            Set-Content -Path $GitLogFile -Value $FullOutput
            Write-Log "Git output saved to: $GitLogFile" "INFO"
        }

        if ($StepName) {
            Write-Step $StepName "FAILED"
        }
    }
    else {
        if ($StepName) {
            Write-Step $StepName "COMPLETED"
        }
    }
    
    return $ExitCode
}

# ============================================================================ 
# 3. COMPONENT INSTALLERS
# ============================================================================ 

function Install-FanvueHub {
    Write-Log "`n[Fedda Hub] Installing dependencies..."
    
    # In new structure, Next.js app is in root (package.json, src/, prisma/ at root level)
    # Check if we have package.json in root
    $PackageJson = Join-Path $RootPath "package.json"
    
    if (-not (Test-Path $PackageJson)) {
        Write-Log "ERROR: package.json not found in root!"
        Write-Log "Fedda Hub requires Next.js app files (package.json, src/, prisma/) in repository root"
        return
    }

    Set-Location $RootPath
    
    # Use portable node to install dependencies
    Write-Log "[Fedda Hub] Running npm install..."
    & "$NodeExe" "npm" "install" "--legacy-peer-deps"
    
    # Check if prisma folder exists
    $PrismaDir = Join-Path $RootPath "prisma"
    if (Test-Path $PrismaDir) {
        Write-Log "[Fedda Hub] Initializing Database..."
        & "$NodeExe" "npx" "prisma" "generate"
        & "$NodeExe" "npx" "prisma" "db" "push"
    }
    else {
        Write-Log "[Fedda Hub] No prisma folder found, skipping database setup"
    }
    
    Write-Log "[Fedda Hub] Setup complete."
    Pause-Step
}

function Install-Ollama {
    Write-Log "`n[Ollama] Setting up Ollama..."
    $OllamaDir = Join-Path $RootPath "ollama_embeded"
    $OllamaExe = Join-Path $OllamaDir "ollama.exe"
    
    if (-not (Test-Path $OllamaExe)) {
        New-Item -ItemType Directory -Path $OllamaDir -Force | Out-Null
        
        $OllamaZip = Join-Path $OllamaDir "ollama.zip"
        $OllamaUrl = "https://github.com/ollama/ollama/releases/download/v0.5.4/ollama-windows-amd64.zip"
        
        Write-Log "Downloading Ollama portable binary..."
        Download-File $OllamaUrl $OllamaZip
        
        Write-Log "Extracting Ollama..."
        Extract-Zip $OllamaZip $OllamaDir
        Remove-Item $OllamaZip -Force
        
        Write-Log "[Ollama] Installed successfully."
    }
    else {
        Write-Log "[Ollama] Already installed."
    }
    Pause-Step
}

function Install-VoxCPM {
    Write-Log "`n[VoxCPM] Setting up VoxCPM..."
    $VoxDir = Join-Path $RootPath "VoxCPM"
    
    if (-not (Test-Path $VoxDir)) {
        Write-Log "Cloning VoxCPM..."
        Run-Git "clone https://github.com/OpenBMB/VoxCPM.git `"$VoxDir`""
    }
    
    if (Test-Path $VoxDir) {
        Write-Log "Installing VoxCPM dependencies (via portable pip)..."
        Set-Location $VoxDir
        Run-Pip "install ."
        Set-Location $RootPath
        Write-Log "[VoxCPM] Installed successfully."
    }
    else {
        Write-Log "ERROR: VoxCPM directory missing."
    }
    Pause-Step
}

# ============================================================================ 
# 2. INSTALLATION LOGIC
# ============================================================================ 

# 4. Setup ComfyUI Repository
Write-Phase "ComfyUI Repository Setup"
$ComfyDir = Join-Path $RootPath "ComfyUI"
if (-not (Test-Path $ComfyDir)) {
    $gitResult = Run-Git "clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git `"$ComfyDir`"" "Cloning ComfyUI repository"
    if ($gitResult -eq 0) {
        Write-Log "ComfyUI cloned successfully." "SUCCESS"
    }
    else {
        Write-Log "ERROR: Failed to clone ComfyUI repository." "ERROR"
        Write-Log "Check your internet connection and try again." "ERROR"
        Write-Summary
        Read-Host "Press Enter to exit"
        exit 1
    }
}
else {
    Write-Step "Cloning ComfyUI repository" "SKIPPED"
    Write-Log "ComfyUI directory already exists - using existing installation" "INFO"
}

Pause-Step

# 5. Core Dependencies
Write-Phase "Core Dependencies - PyTorch & GPU Acceleration"
$ComfyDir = Join-Path $RootPath "ComfyUI"


$pipUpgradeResult = Run-Pip "install --upgrade pip wheel setuptools" "Upgrading pip, wheel, and setuptools"
if ($pipUpgradeResult -ne 0) {
    Write-Log "Pip upgrade failed - continuing with existing version" "WARNING"
}


# Detect GPU and install appropriate PyTorch version
$gpuMode = Detect-GPUCapability

if ($gpuMode -eq "cuda124") {
    Write-Log "Installing PyTorch 2.5.1 (CUDA 12.4 - GPU Accelerated)" "INFO"
    Write-Log "This will provide maximum performance on your NVIDIA GPU" "INFO"
    Run-Pip "install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 --index-url https://download.pytorch.org/whl/cu124" "PyTorch 2.5.1 + CUDA 12.4" $true
    
    Write-Log "Installing Xformers 0.0.28.post3 (GPU acceleration)" "INFO"
    $xformersResult = Run-Pip "install xformers==0.0.28.post3 --index-url https://download.pytorch.org/whl/cu124" "Xformers 0.0.28.post3"
    if ($xformersResult -ne 0) {
        Write-Log "⚠ Xformers installation failed - ComfyUI will still work but slower" "WARNING"
    }
    
    Write-Log "Installing Windows-compatible Triton (for SageAttention)" "INFO"
    $tritonResult = Run-Pip "install https://github.com/woct0rdho/triton-windows/releases/download/v3.1.0-windows.post5/triton-3.1.0-cp311-cp311-win_amd64.whl" "Triton for Windows"
    
    if ($tritonResult -eq 0) {
        Write-Log "Installing SageAttention 1.0.6" "INFO"
        $sageResult = Run-Pip "install sageattention==1.0.6" "SageAttention 1.0.6"
        if ($sageResult -ne 0) {
            Write-Log "⚠ SageAttention installation failed - Optional feature, not critical" "WARNING"
        }
    }
    else {
        Write-Log "⚠ Triton failed - Skipping SageAttention (requires Triton)" "WARNING"
    }
}
elseif ($gpuMode -eq "cuda118") {
    Write-Log "Installing PyTorch 2.5.1 (CUDA 11.8 - Compatible with older drivers)" "INFO"
    Run-Pip "install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 --index-url https://download.pytorch.org/whl/cu118" "PyTorch 2.5.1 + CUDA 11.8" $true
    
    Write-Log "Installing Xformers 0.0.28.post3 (CUDA 11.8)" "INFO"
    $xformersResult = Run-Pip "install xformers==0.0.28.post3 --index-url https://download.pytorch.org/whl/cu118" "Xformers 0.0.28.post3"
    if ($xformersResult -ne 0) {
        Write-Log "⚠ Xformers installation failed - ComfyUI will still work but slower" "WARNING"
    }
    
    Write-Log "Skipping Triton and SageAttention (requires CUDA 12.x)" "WARNING"
}
else {
    Write-Log "Installing PyTorch 2.5.1 (CPU-Only)" "WARNING"
    Write-Log "NOTE: This will be slower than GPU acceleration but works on any PC" "INFO"
    Run-Pip "install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 --index-url https://download.pytorch.org/whl/cpu" "PyTorch 2.5.1 (CPU)" $true
    
    Write-Log "Skipping Xformers (GPU-only package)" "INFO"
    Write-Log "Skipping Triton and SageAttention (GPU-only packages)" "INFO"
}

Write-Log "Installing ComfyUI requirements..." "INFO"
$ReqFile = Join-Path $ComfyDir "requirements.txt"
Run-Pip "install -r $ReqFile" "ComfyUI requirements"

Write-Log "Installing core dependencies..." "INFO"
Run-Pip "install numpy scipy matplotlib pillow tqdm requests psutil" "Core Python packages"

Pause-Step


# 6. Custom Nodes Installation
Write-Phase "Custom Nodes Installation"
$InstallerDir = Join-Path $RootPath "installer"
$NodesConfig = Get-Content (Join-Path $InstallerDir "config\nodes.json") | ConvertFrom-Json
$CustomNodesDir = Join-Path $ComfyDir "custom_nodes"

$InstalledCount = 0
$SkippedCount = 0
$FailedCount = 0

foreach ($Node in $NodesConfig) {
    # Skip local nodes (e.g., AutoModelFetcher)
    if ($Node.local -eq $true) {
        Write-Log "[$($Node.name)] - Local node, skipping git clone"
        continue
    }
    
    $NodeDir = Join-Path $CustomNodesDir $Node.folder
    if (-not (Test-Path $NodeDir)) {
        Write-Log "Installing $($Node.name)..."
        Run-Git "clone --depth 1 $($Node.url) `"$NodeDir`""
        if ($LASTEXITCODE -eq 0) {
            Write-Log "[$($Node.name)] - Installed successfully"
            $InstalledCount++
            
            # Install node requirements if requirements.txt exists
            $NodeReqFile = Join-Path $NodeDir "requirements.txt"
            if (Test-Path $NodeReqFile) {
                Write-Log "[$($Node.name)] - Installing node requirements..."
                
                # Create a filtered requirements file (skip insightface - installed globally)
                $RequirementsContent = Get-Content $NodeReqFile
                $FilteredRequirements = $RequirementsContent | Where-Object { $_ -notmatch '^\s*insightface' }
                
                if ($FilteredRequirements.Count -lt $RequirementsContent.Count) {
                    Write-Log "[$($Node.name)] - Skipping insightface (already installed globally)"
                    $TempReqFile = Join-Path $NodeDir "requirements_filtered.txt"
                    Set-Content -Path $TempReqFile -Value $FilteredRequirements
                    Run-Pip "install -r `"$TempReqFile`" --no-warn-script-location"
                    Remove-Item $TempReqFile -Force
                }
                else {
                    Run-Pip "install -r `"$NodeReqFile`" --no-warn-script-location"
                }
            }
            
            # Create __init__.py if missing
            $InitFile = Join-Path $NodeDir "__init__.py"
            if (-not (Test-Path $InitFile)) {
                # Ensure the directory exists first
                if (-not (Test-Path $NodeDir)) {
                    New-Item -ItemType Directory -Path $NodeDir -Force | Out-Null
                }
                $InitContent = @"
# $($Node.folder) - Custom nodes for ComfyUI
import sys
import os
from pathlib import Path

current_dir = os.path.dirname(__file__)
if current_dir not in sys.path:
    sys.path.append(current_dir)

NODE_CLASS_MAPPINGS = {}
NODE_DISPLAY_NAME_MAPPINGS = {}
__all__ = ['NODE_CLASS_MAPPINGS', 'NODE_DISPLAY_NAME_MAPPINGS']
"@
                Set-Content -Path $InitFile -Value $InitContent
            }
        }
        else {
            Write-Log "[$($Node.name)] - Failed to install"
            $FailedCount++
        }
    }
    else {
        Write-Log "[$($Node.name)] - Already present"
        $SkippedCount++
    }
}

# --- CRITICAL FIX: Patch Efficiency Nodes ---
$EffNodeFile = Join-Path $CustomNodesDir "Efficiency-Nodes\py\smZ_cfg_denoiser.py"
if (Test-Path $EffNodeFile) {
    Write-Log "Patching Efficiency Nodes..."
    $EffContent = Get-Content $EffNodeFile -Raw
    if ($EffContent -match "CompVisVDenoiser") {
        $EffContent = $EffContent.Replace(
            "from comfy.samplers import KSampler, CompVisVDenoiser, KSamplerX0Inpaint",
            "from comfy.samplers import KSampler, KSamplerX0Inpaint"
        )
        $EffContent = $EffContent.Replace(
            "from comfy.k_diffusion.external import CompVisDenoiser",
            "from comfy.k_diffusion.external import CompVisDenoiser, CompVisVDenoiser"
        )
        Set-Content -Path $EffNodeFile -Value $EffContent
        Write-Log "Efficiency Nodes patched successfully."
    }
}

# Enforce compatible OpenCV setup (opencv-python for transparent-background, contrib for extras)
Write-Log "Cleaning up OpenCV variants (headless conflicts)..."
Run-Pip "uninstall -y opencv-python-headless opencv-contrib-python-headless"
Write-Log "Installing opencv-python (required by transparent-background)..."
Run-Pip "install opencv-python>=4.6.0.66"
Write-Log "Installing opencv-contrib-python (optional extras)..."
Run-Pip "install opencv-contrib-python"

Pause-Step

# 7. Comprehensive Dependencies (Updated with fixes)
Write-Log "`n[ComfyUI 7/9] Installing comprehensive dependencies..."

# 7.1 Install Build Tools first (Fix for llama-cpp-python and insightface)
Write-Log "Installing build dependencies..."
Run-Pip "install scikit-build-core cmake ninja Cython"

# 7.1.5 Install insightface early with pre-built wheel (avoid compilation)
Write-Log "Installing insightface (pre-built wheel)..."
Run-Pip "install insightface --prefer-binary --no-build-isolation"

# 7.2 Main Dependencies
$Deps = @(
    "accelerate", "transformers", "diffusers", "safetensors",
    "huggingface-hub", "onnxruntime-gpu", "onnxruntime", "omegaconf",
    "aiohttp", "aiohttp-sse",
    "pytube", "yt-dlp", "moviepy", "youtube-transcript-api",
    "numba",
    "imageio", "imageio-ffmpeg", "av",
    "gdown", "pandas", "reportlab", "google-auth>=2.45.0", "google-auth-oauthlib", "google-auth-httplib2",
    "GPUtil", "wandb",
    "piexif", "rembg",
    "pillow-heif",
    "librosa", "soundfile",
    "webdriver-manager", "beautifulsoup4", "lxml", "shapely",
    "deepdiff", "fal_client", "matplotlib", "scipy", "scikit-image", "scikit-learn",
    "timm", "colour-science", "blend-modes", "loguru"
)
Run-Pip "install $($Deps -join ' ')"

# 7.3 Install llama-cpp-python separately (GPU-aware)
Write-Log "Installing llama-cpp-python..."
if ($gpuMode -eq "cuda124") {
    # Try CUDA 12.4 wheel first
    Write-Log "Installing llama-cpp-python with CUDA 12.4 support..."
    Run-Pip "install llama-cpp-python --prefer-binary --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu124"
}
elseif ($gpuMode -eq "cuda118") {
    # Fallback to CUDA 11.8 wheel
    Write-Log "Installing llama-cpp-python with CUDA 11.8 support..."
    Run-Pip "install llama-cpp-python --prefer-binary --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu118"
}
else {
    # CPU-only version
    Write-Log "Installing llama-cpp-python (CPU-only)..."
    Run-Pip "install llama-cpp-python --prefer-binary"
}

Pause-Step


# 8. Install Custom Assets (styles.csv only - workflows excluded in free version)
Write-Log "`n[ComfyUI 8/9] Installing Custom Assets..."

# Install styles.csv to ComfyUI root
$InstallerDir = Join-Path $RootPath "installer"
$StylesSrc = Join-Path $InstallerDir "assets\styles.csv"
if (Test-Path $StylesSrc) {
    Copy-Item -Path $StylesSrc -Destination $ComfyDir -Force
    Write-Log "Installed styles.csv for Styles CSV Loader node."
}
else {
    Write-Log "styles.csv not found, skipping."
}


Pause-Step

# ============================================================================ 
# 8.5 INSTALL CHARACTER WORKFLOW NODES (Optional but Recommended)
# ============================================================================ 

Write-Log "`n[ComfyUI 8.5/9] Installing Character Workflow Nodes..."
Write-Log "  - ComfyUI-Impact-Pack (SAM, FaceDetailer)"
Write-Log "  - ComfyUI InstantID (facial identity)"
Write-Log "  - AutoCropFaces (intelligent detection)"
Write-Log "  - Chibi Nodes (UI components)"

$CustomNodesDir = Join-Path $ComfyDir "custom_nodes"

# Helper function for node installation
function Install-CustomNode {
    param([string]$NodeName, [string]$RepoUrl, [string]$FolderName)
    
    $NodeDir = Join-Path $CustomNodesDir $FolderName
    
    if (-not (Test-Path $NodeDir)) {
        Write-Log "  Installing $NodeName..."
        try {
            Set-Location $CustomNodesDir
            & git clone $RepoUrl $FolderName
            
            # Install requirements if requirements.txt exists and is not empty
            $ReqFile = Join-Path $NodeDir "requirements.txt"
            if (Test-Path $ReqFile) {
                $reqContent = Get-Content $ReqFile -Raw
                if ($reqContent.Trim().Length -gt 0) {
                    Write-Log "    Installing dependencies for $NodeName..."
                    & $PyExe -m pip install -r $ReqFile
                }
                else {
                    Write-Log "    requirements.txt is empty, skipping pip install."
                }
            }
            else {
                Write-Log "    No requirements.txt found, skipping pip install."
            }
            
            Write-Log "  ✓ $NodeName installed successfully"
        }
        catch {
            Write-Log "  ⚠️  WARNING: Failed to install $NodeName (non-fatal)"
            Write-Log "    You can install it manually later or skip it"
        }
    }
    else {
        Write-Log "  ✓ $NodeName already installed"
    }
}


# Install character workflow nodes
Install-CustomNode "ComfyUI-Impact-Pack" "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git" "ComfyUI-Impact-Pack"
Install-CustomNode "ComfyUI InstantID" "https://github.com/cubiq/ComfyUI_InstantID.git" "comfyui_instantid"
Install-CustomNode "AutoCropFaces" "https://github.com/liusida/ComfyUI-AutoCropFaces.git" "ComfyUI-AutoCropFaces"
Install-CustomNode "Chibi Nodes" "https://github.com/CheapCyborg/Chibi-Nodes.git" "chibi"
Install-CustomNode "ComfyUI_LayerStyle_Advance" "https://github.com/chflame163/ComfyUI_LayerStyle_Advance.git" "ComfyUI_LayerStyle_Advance"

Set-Location $RootPath
Write-Log "Character workflow nodes installation complete."

Pause-Step

# 9. Configure ComfyUI-Manager Security (Weak Mode)
Write-Log "`n[ComfyUI 9/9] Configuring ComfyUI-Manager Security..."
$ManagerConfigDir = Join-Path $ComfyDir "user\default\ComfyUI-Manager"
$ManagerConfigFile = Join-Path $ManagerConfigDir "config.ini"

if (-not (Test-Path $ManagerConfigDir)) {
    New-Item -ItemType Directory -Path $ManagerConfigDir -Force | Out-Null
}

if (-not (Test-Path $ManagerConfigFile)) {
    $ConfigContent = @"
[default]
preview_method = latent2rgb
git_exe =
use_uv = False
channel_url = https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/node_db/dev
share_option = all
bypass_ssl = False
file_logging = True
component_policy = mine
update_policy = stable-comfyui
windows_selector_event_loop_policy = False
model_download_by_agent = False
downgrade_blacklist =
security_level = weak
always_lazy_install = False
network_mode = public
db_mode = cache
host = 0.0.0.0
port = 8188
allow_remote = true
auto_update = false
auto_start = false
username =
password =
token =
"@
    Set-Content -Path $ManagerConfigFile -Value $ConfigContent
    Write-Log "Security level set to 'weak' (Developer Mode)."
}
else {
    Write-Log "ComfyUI-Manager config already exists. Skipping."
}

Pause-Step

# 9.5 Cleanup legacy ComfyUI-Manager backup (if exists)
$LegacyBackup = Join-Path $ComfyDir "user\__manager\.legacy-manager-backup"
if (Test-Path $LegacyBackup) {
    Write-Log "Cleaning up legacy ComfyUI-Manager backup..."
    Remove-Item -Path $LegacyBackup -Recurse -Force
    Write-Log "Legacy backup removed."
}

# 10. Install All Components
Write-Log "`n=========================================="
Write-Log " Installing Ecosystem Components"
Write-Log "=========================================="

# VoxCPM removed - using ComfyUI TTS nodes instead (indextts2vc, vibevoice, etc.)
# Install-VoxCPM

Install-Ollama
Install-FanvueHub

# 10.5. Fix Dependency Conflicts (Gradio vs rembg)
Write-Log "`n[Dependency Fix] Resolving package conflicts..."
Write-Log "Upgrading Pillow to satisfy rembg requirements (>= 12.1.0)..."
Run-Pip "install `"pillow>=12.1.0,<13.0.0`" --upgrade"
Write-Log "Note: Gradio claims to require Pillow <12.0, but works fine with 12.1.0"
Pause-Step

# 10.6. Install Voice Samples
Write-Log "`n[Voice Pack] Installing TTS voice samples..."
$VoiceScriptPath = Join-Path $ScriptPath "install_voices.ps1"
if (Test-Path $VoiceScriptPath) {
    try {
        & $VoiceScriptPath
        Write-Log "[Voice Pack] Installation complete."
    }
    catch {
        Write-Log "[Voice Pack] Installation failed (non-critical): $($_.Exception.Message)"
    }
}
else {
    Write-Log "[Voice Pack] Script not found, skipping..."
}
Pause-Step

# 11. Final Cleanup
Write-Phase "Finalization"
Write-Step "Creating shortcuts and cleanup" "SKIPPED"
Write-Log "Desktop shortcuts skipped (use run.bat to launch)" "INFO"
Pause-Step

Write-Phase "Installation Complete"
Write-Log "`n================================================" "SUCCESS"
Write-Log " FEDDA HUB SETUP COMPLETE!" "SUCCESS"
Write-Log "================================================" "SUCCESS"

# Generate and display summary
Write-Summary

# Keep window open for user review
Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")