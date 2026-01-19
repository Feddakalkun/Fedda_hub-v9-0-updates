# Fix Dependency Conflicts from Installation
# Resolves conflicts between VoxCPM/Gradio and other packages

$ErrorActionPreference = "Stop"
$RootPath = Split-Path -Parent $PSScriptRoot
$PyExe = Join-Path $RootPath "python_embeded\python.exe"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " FIXING DEPENDENCY CONFLICTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Fix 1: Pillow version conflict
Write-Host "[1/2] Fixing Pillow version..." -ForegroundColor Yellow
Write-Host "  Issue: rembg requires Pillow >= 12.1.0, but gradio installed 11.3.0" -ForegroundColor Gray

$Process = Start-Process -FilePath $PyExe -ArgumentList "-m pip install 'pillow>=12.1.0,<13.0.0' --upgrade" -NoNewWindow -Wait -PassThru

if ($Process.ExitCode -eq 0) {
    Write-Host "  [OK] Pillow upgraded to compatible version" -ForegroundColor Green
}
else {
    Write-Host "  [FAIL] Could not upgrade Pillow" -ForegroundColor Red
}

# Fix 2: OpenCV conflict
Write-Host "`n[2/2] Fixing OpenCV variants..." -ForegroundColor Yellow
Write-Host "  Issue: albumentations requires opencv-python-headless" -ForegroundColor Gray
Write-Host "  Strategy: Install opencv-contrib-python (includes all features)" -ForegroundColor Gray

# Install opencv-contrib-python which satisfies both opencv-python and opencv-python-headless needs
$Process = Start-Process -FilePath $PyExe -ArgumentList "-m pip install opencv-contrib-python --upgrade" -NoNewWindow -Wait -PassThru

if ($Process.ExitCode -eq 0) {
    Write-Host "  [OK] OpenCV variants fixed" -ForegroundColor Green
}
else {
    Write-Host "  [FAIL] Could not fix OpenCV" -ForegroundColor Red
}

# Verify fixes
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

& $PyExe -c @"
import sys
errors = []

# Test Pillow
try:
    import PIL
    from packaging import version
    pil_version = version.parse(PIL.__version__)
    if pil_version >= version.parse('12.1.0'):
        print('[OK] Pillow', PIL.__version__)
    else:
        print('[WARN] Pillow', PIL.__version__, '(still below 12.1.0)')
        errors.append('pillow')
except Exception as e:
    print('[FAIL] Pillow:', e)
    errors.append('pillow')

# Test OpenCV
try:
    import cv2
    print('[OK] OpenCV', cv2.__version__)
except Exception as e:
    print('[FAIL] OpenCV:', e)
    errors.append('opencv')

# Test rembg
try:
    import rembg
    print('[OK] rembg can be imported')
except Exception as e:
    print('[FAIL] rembg:', e)
    errors.append('rembg')

# Test albumentations
try:
    import albumentations
    print('[OK] albumentations can be imported')
except Exception as e:
    print('[FAIL] albumentations:', e)
    errors.append('albumentations')

if errors:
    print(f'\n[WARN] Some packages still have issues: {errors}')
    sys.exit(1)
else:
    print('\n[OK] All dependencies verified!')
    sys.exit(0)
"@

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] All conflicts resolved!" -ForegroundColor Green
}
else {
    Write-Host "`n[WARNING] Some issues remain. Check output above." -ForegroundColor Yellow
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
