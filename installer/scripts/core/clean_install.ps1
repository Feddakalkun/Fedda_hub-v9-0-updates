# Clean Installation Script
# Removes all installed components to prepare for fresh installation

$ErrorActionPreference = "Continue"
$RootPath = Split-Path -Parent $PSScriptRoot

Write-Host "`n============================================" -ForegroundColor Red
Write-Host " CLEAN INSTALLATION - REMOVING OLD FILES" -ForegroundColor Red
Write-Host "============================================`n" -ForegroundColor Red

Write-Host "WARNING: This will delete:" -ForegroundColor Yellow
Write-Host "  - ComfyUI folder" -ForegroundColor Yellow
Write-Host "  - VoxCPM folder" -ForegroundColor Yellow
Write-Host "  - ollama_embeded folder" -ForegroundColor Yellow
Write-Host "  - Python site-packages (reset)" -ForegroundColor Yellow
Write-Host "  - Fedda Hub node_modules & database" -ForegroundColor Yellow
Write-Host "  - Installation logs" -ForegroundColor Yellow
Write-Host "`nPortable tools (Python, Git, Node) will be kept.`n" -ForegroundColor Gray

$Confirm = Read-Host "Are you sure you want to continue? (yes/no)"

if ($Confirm -ne "yes") {
    Write-Host "`nCleanup cancelled." -ForegroundColor Green
    exit 0
}

Write-Host "`nStarting cleanup...`n" -ForegroundColor Cyan

# 1. Remove ComfyUI
$ComfyDir = Join-Path $RootPath "ComfyUI"
if (Test-Path $ComfyDir) {
    Write-Host "[1/7] Removing ComfyUI..." -NoNewline
    Remove-Item -Path $ComfyDir -Recurse -Force
    Write-Host " Done" -ForegroundColor Green
}
else {
    Write-Host "[1/7] ComfyUI not found, skipping" -ForegroundColor Gray
}

# 2. Remove VoxCPM
$VoxDir = Join-Path $RootPath "VoxCPM"
if (Test-Path $VoxDir) {
    Write-Host "[2/7] Removing VoxCPM..." -NoNewline
    Remove-Item -Path $VoxDir -Recurse -Force
    Write-Host " Done" -ForegroundColor Green
}
else {
    Write-Host "[2/7] VoxCPM not found, skipping" -ForegroundColor Gray
}

# 3. Remove Ollama
$OllamaDir = Join-Path $RootPath "ollama_embeded"
if (Test-Path $OllamaDir) {
    Write-Host "[3/7] Removing Ollama..." -NoNewline
    Remove-Item -Path $OllamaDir -Recurse -Force
    Write-Host " Done" -ForegroundColor Green
}
else {
    Write-Host "[3/7] Ollama not found, skipping" -ForegroundColor Gray
}

# 4. Reset Python site-packages (keep pip, wheel, setuptools)
Write-Host "[4/7] Resetting Python packages..." -NoNewline
$SitePackages = Join-Path $RootPath "python_embeded\Lib\site-packages"
if (Test-Path $SitePackages) {
    # Get list of packages to keep
    $KeepPackages = @('pip', 'wheel', 'setuptools', '_distutils_hack', 'distutils-precedence.pth')
    
    Get-ChildItem $SitePackages | ForEach-Object {
        $keep = $false
        foreach ($pkg in $KeepPackages) {
            if ($_.Name -like "$pkg*") {
                $keep = $true
                break
            }
        }
        
        if (-not $keep -and $_.Name -notmatch '^__' -and $_.Name -ne 'site.py') {
            Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host " Done" -ForegroundColor Green
}
else {
    Write-Host " site-packages not found" -ForegroundColor Yellow
}

# 5. Clean Fedda Hub
Write-Host "[5/7] Cleaning Fedda Hub..." -NoNewline
$HubDir = Join-Path $RootPath "fedda-hub"
if (Test-Path $HubDir) {
    # Remove node_modules
    $NodeModules = Join-Path $HubDir "node_modules"
    if (Test-Path $NodeModules) {
        Remove-Item -Path $NodeModules -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Remove .next build
    $NextBuild = Join-Path $HubDir ".next"
    if (Test-Path $NextBuild) {
        Remove-Item -Path $NextBuild -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Remove database
    $DbFile = Join-Path $HubDir "prisma\dev.db"
    if (Test-Path $DbFile) {
        Remove-Item -Path $DbFile -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host " Done" -ForegroundColor Green
}
else {
    Write-Host " Fedda Hub not found" -ForegroundColor Yellow
}

# 6. Remove logs
Write-Host "[6/7] Removing logs..." -NoNewline
$LogsDir = Join-Path $RootPath "logs"
if (Test-Path $LogsDir) {
    Remove-Item -Path $LogsDir -Recurse -Force
    Write-Host " Done" -ForegroundColor Green
}
else {
    Write-Host " No logs found" -ForegroundColor Gray
}

# 7. Clean temp files
Write-Host "[7/7] Cleaning temp files..." -NoNewline
$TempFiles = @(
    (Join-Path $RootPath "*.zip"),
    (Join-Path $RootPath "get-pip.py")
)
foreach ($pattern in $TempFiles) {
    Get-Item $pattern -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}
Write-Host " Done" -ForegroundColor Green

Write-Host "`n============================================" -ForegroundColor Green
Write-Host " CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Green

Write-Host "Kept:" -ForegroundColor White
Write-Host "  ✓ python_embeded (with pip, wheel, setuptools)" -ForegroundColor Gray
Write-Host "  ✓ git_embeded" -ForegroundColor Gray
Write-Host "  ✓ node_embeded" -ForegroundColor Gray
Write-Host "  ✓ scripts" -ForegroundColor Gray
Write-Host "  ✓ config" -ForegroundColor Gray
Write-Host "  ✓ assets" -ForegroundColor Gray
Write-Host "  ✓ fedda-hub (source code)" -ForegroundColor Gray

Write-Host "`nYou can now run install.bat for a fresh installation.`n" -ForegroundColor Cyan

