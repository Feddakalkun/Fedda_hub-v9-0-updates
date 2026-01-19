"""Test script to check which critical packages are installed."""

packages_to_test = [
    'cv2',
    'accelerate', 
    'transformers',
    'diffusers',
    'insightface',
    'omegaconf',
    'safetensors',
    'huggingface_hub',
    'onnxruntime',
    'numba',
    'imageio',
    'moviepy',
    'rembg',
    'librosa',
    'soundfile',
    'matplotlib',
    'scipy',
    'sklearn',
    'timm',
]

missing = []
installed = []

for package in packages_to_test:
    try:
        __import__(package)
        installed.append(package)
    except ImportError:
        missing.append(package)

print("\n=== INSTALLED PACKAGES ===")
for pkg in installed:
    print(f"OK: {pkg}")

print("\n=== MISSING PACKAGES ===")
if missing:
    for pkg in missing:
        print(f"MISSING: {pkg}")
else:
    print("All packages installed!")

print(f"\n=== SUMMARY ===")
print(f"Installed: {len(installed)}/{len(packages_to_test)}")
print(f"Missing: {len(missing)}/{len(packages_to_test)}")
