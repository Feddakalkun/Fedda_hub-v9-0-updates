# 📊 Fedda Hub - Installation Logs Guide

## Overview

The Fedda Hub installer now features **comprehensive logging** to help you understand what's happening during installation and troubleshoot any issues. This guide explains the logging system and how to use it.

---

## 📁 Where Are the Logs?

All installation logs are saved in the `logs/` folder at the root of your Fedda Hub installation:

```
Fedda_hub-v9-0/
└── logs/
    ├── install_log_2026-01-21_17-30-00.txt      # Main installation log
    ├── install_errors_2026-01-21_17-30-00.txt   # Errors only
    ├── install_summary.txt                       # Human-readable summary
    ├── install_progress.json                     # Installation state (for resume)
    └── pip_HHMMSS.log                            # Individual pip command logs
```

### Log Files Explained

| File | Purpose | When to Check |
|------|---------|---------------|
| **install_log_[timestamp].txt** | Complete installation log with all steps | After installation to review what happened |
| **install_errors_[timestamp].txt** | Only errors and critical warnings | If installation failed |
| **install_summary.txt** | Easy-to-read summary with stats | Quick overview of installation results |
| **install_progress.json** | Current installation state (JSON format) | For developers or automated tools |
| **pip_[time].log** | Individual pip command output | Debug specific package installation failures |

---

## 🎨 Color-Coded Console Output

During installation, you'll see color-coded messages:

- **🟢 Green (SUCCESS)**: Step completed successfully
- **⚪ White (INFO)**: Informational messages
- **🟡 Yellow (WARNING)**: Non-critical warnings (installation continues)
- **🔴 Red (ERROR)**: Critical errors (may stop installation)

---

## 📋 Installation Phases

The installer is divided into clear phases:

### 1. **Bootstrap - Portable Tools Setup**
   - Downloads and configures Python 3.11.9
   - Sets up portable Git (MinGit)
   - Installs portable Node.js 20
   
### 2. **ComfyUI Repository Setup**
   - Clones the official ComfyUI repository
   
### 3. **Core Dependencies - PyTorch & GPU Acceleration**
   - **Detects your GPU** (NVIDIA/AMD/CPU)
   - Installs appropriate PyTorch version
   - Installs xformers (GPU acceleration)
   - Installs SageAttention (CUDA 12.4 only)
   
### 4. **Custom Nodes Installation**
   - Installs 40+ custom nodes from the community
   - Each node installation is tracked separately
   
### 5. **Comprehensive Dependencies**
   - Installs all required Python packages
   - Configures OpenCV, llama-cpp-python, etc.
   
### 6. **Ecosystem Components**
   - Ollama (AI Chat Engine)
   - Fedda Hub (Next.js Dashboard)
   - Voice samples (TTS)
   
### 7. **Finalization**
   - Cleanup and final checks
   - **Generates Installation Summary**

---

## 🎯 Understanding GPU Modes

The installer automatically detects your hardware and chooses the best configuration:

### CUDA 12.4 Mode (Best Performance)
```
GPU Mode: cuda124
✓ NVIDIA GPU with driver 545+
✓ PyTorch with CUDA 12.4
✓ Xformers (GPU acceleration)
✓ Triton + SageAttention (bleeding edge)
```

**Who gets this?** Users with recent NVIDIA drivers (545+)

### CUDA 11.8 Mode (Older Drivers)
```
GPU Mode: cuda118
✓ NVIDIA GPU with driver 450-544
✓ PyTorch with CUDA 11.8
✓ Xformers (GPU acceleration)
⚠ No SageAttention (requires CUDA 12.x)
```

**Who gets this?** Users with older NVIDIA drivers

### CPU Mode
```
GPU Mode: cpu
⚠ No dedicated NVIDIA GPU detected
⚠ CPU-only PyTorch (slower)
⚠ No xformers, Triton, or SageAttention
```

**Who gets this?** 
- AMD GPU users (DirectML support coming soon)
- Integrated graphics users
- CPU-only systems

---

## 🔍 Troubleshooting Common Issues

### ❌ Problem: "Pip command failed"

**Symptoms:**
```
[ERROR] Pip command failed (Exit Code: 1): install torch...
```

**Solutions:**
1. Check `logs/pip_HHMMSS.log` for detailed error
2. Check internet connection
3. Try running installer again (it will skip completed steps)
4. Disable antivirus temporarily

---

### ❌ Problem: "Xformers installation failed"

**Symptoms:**
```
[WARNING] Xformers installation failed - ComfyUI will still work but slower
```

**Impact:** Non-critical. ComfyUI will work, but image generation will be slower.

**Solutions:**
1. **Ignore it** - Installation continues normally
2. Update NVIDIA drivers to latest version
3. Manually install later: `python_embeded\python.exe -m pip install xformers`

---

### ❌ Problem: "SageAttention installation failed"

**Symptoms:**
```
[WARNING] SageAttention installation failed - Optional feature, not critical
```

**Impact:** Minimal. SageAttention is an experimental optimization.

**Solutions:**
1. **Ignore it** - This is optional
2. Only works on Windows with CUDA 12.4
3. Requires Triton for Windows

---

### ❌ Problem: "Git clone failed"

**Symptoms:**
```
[ERROR] Git command failed (Exit Code: 128)
```

**Solutions:**
1. Check internet connection
2. GitHub may be temporarily down
3. Firewall/antivirus blocking Git
4. Try again later

---

### ❌ Problem: Custom node installation failed

**Symptoms:**
```
[Custom-Node-Name] - Failed to install
```

**Impact:** That specific node won't be available in ComfyUI

**Solutions:**
1. Check `logs/install_errors_*.txt` for details
2. Node may have conflicting dependencies
3. Install manually later from ComfyUI Manager

---

## 📊 Reading the Installation Summary

After installation, check `logs/install_summary.txt`:

```
================================================================================
FEDDA HUB INSTALLATION SUMMARY
================================================================================
Installation Date: 2026-01-21 17:45:32
Duration: 00:35:12
GPU Mode: cuda124

COMPLETED STEPS (45):
  ✓ Setting up Portable Python 3.11.9
  ✓ Setting up Portable Git
  ✓ PyTorch 2.5.1 + CUDA 12.4
  ✓ Xformers 0.0.28.post3
  ...

FAILED STEPS (2):
  ✗ Triton for Windows
  ✗ SageAttention 1.0.6

WARNINGS (3):
  ⚠ Triton failed - Skipping SageAttention (requires Triton)
  ⚠ SageAttention installation failed - Optional feature, not critical
  ⚠ [CustomNode-X] - Installation failed

LOG FILES:
  Main Log: logs/install_log_2026-01-21_17-30-00.txt
  Error Log: logs/install_errors_2026-01-21_17-30-00.txt
  
STATUS: COMPLETED WITH ERRORS ⚠
================================================================================
```

### What to Look For:

✅ **STATUS: SUCCESS** - Everything worked perfectly!

⚠️ **STATUS: COMPLETED WITH ERRORS** - Installation finished but some optional features failed. Check failed steps:
- If only xformers/SageAttention failed → **Not critical**, ComfyUI will work
- If PyTorch failed → **Critical**, need to troubleshoot
- If custom nodes failed → **Minor**, those nodes won't be available

---

## 🚀 Next Steps After Installation

1. **Check the summary**: Read `logs/install_summary.txt`
2. **If everything succeeded**: Run `run.bat` to start Fedda Hub!
3. **If there were errors**: 
   - Review the error log
   - Check this troubleshooting guide
   - Try running `installer/scripts/core/fix_dependencies.ps1`

---

## 🛠️ Advanced: Manual Fixes

### Re-run Only Failed Steps

The installer tracks progress in `logs/install_progress.json`. If installation fails midway, running `install.bat` again will:
- ✅ Skip completed steps
- ⚒️ Retry failed steps
- 🚀 Continue from where it left off

### Manually Install a Package

```powershell
cd "C:\path\to\Fedda_hub-v9-0"
python_embeded\python.exe -m pip install package-name
```

### Manually Install a Custom Node

```powershell
cd "C:\path\to\Fedda_hub-v9-0\ComfyUI\custom_nodes"
..\..\..\git_embeded\cmd\git.exe clone https://github.com/author/node-name.git
cd node-name
..\..\..\python_embeded\python.exe -m pip install -r requirements.txt
```

---

## 🆘 Getting Help

If you're still stuck:

1. **Check logs**: `logs/install_errors_*.txt` has the full error
2. **Search GitHub Issues**: https://github.com/Feddakalkun/Fedda_hub-v9-0/issues
3. **Create an issue**: Include your installation summary and error log

---

## 📝 For Developers

### Log File Locations

All logs are in `logs/` directory:
- Main log: `install_log_[timestamp].txt`
- Error log: `install_errors_[timestamp].txt`
- Summary: `install_summary.txt` (overwritten each time)
- Progress: `install_progress.json` (for resume functionality)
- Pip logs: `pip_[time].log` (one per pip command)

### Adding Custom Logging

```powershell
Write-Log "Your message" "INFO"    # White text
Write-Log "Warning message" "WARNING"  # Yellow text
Write-Log "Error message" "ERROR"      # Red text
Write-Log "Success message" "SUCCESS"  # Green text

Write-Step "Step name" "STARTED"    # → Step name...
Write-Step "Step name" "COMPLETED"  # ✓ Step name (tracked)
Write-Step "Step name" "FAILED"     # ✗ Step name (tracked)
Write-Step "Step name" "SKIPPED"    # ○ Step name (skipped)
```

---

**Happy Installing! 🎉**
