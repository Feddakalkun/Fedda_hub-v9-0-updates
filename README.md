# Fedda Hub - AI Content Studio

**Modern web application for AI content generation with Next.js + ComfyUI**

---

## 🚀 Quick Start

### Installation
```bash
# 1. Clone repository
git clone https://github.com/Feddakalkun/Fedda_hub-v9-0.git
cd Fedda_hub-v9-0

# 2. Run installer (Windows only)
install.bat

# 3. Wait 20-40 minutes for installation

# 4. Start all services
run.bat
```

**Services will be available at:**
- 🎨 Fedda Hub Dashboard: http://localhost:3000
- 🖼️ ComfyUI Engine: http://localhost:8188

---

## 📁 Repository Structure

```
Fedda_hub-v9-0/
├── fedda-hub/              # Next.js web application
│   ├── src/                # Source code
│   ├── prisma/             # Database schema
│   └── package.json
│
├── installer/              # Portable installation package
│   ├── scripts/            # Installation scripts
│   ├── config/             # Configuration files
│   ├── assets/             # Workflows & styles
│   └── *.bat               # Installer entry points
│
├── docs/                   # Documentation
│
├── install.bat             # Main installer (calls installer/install.bat)
├── run.bat                 # Start all services
└── update.bat              # Update components
```

---

## 💻 Development

### Web App Development
```bash
cd fedda-hub
npm install
npm run dev
```

### Installer Development
See `installer/README.md` for details on the portable installation system.

---

## 📚 Documentation

- **Installation Guide:** `docs/INSTALLATION.md`
- **Development Guide:** `docs/DEVELOPMENT.md`
- **VM Testing:** `docs/VM_TESTING.md`

---

## 🔧 System Requirements

**Minimum:**
- Windows 10/11 (64-bit)
- 16 GB RAM
- 20 GB free disk space

**Recommended:**
- NVIDIA GPU (RTX 3060+ with 8GB+ VRAM)
- 32 GB RAM
- 50 GB+ free disk space

---

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines.

---

## 📄 License

[Add license information]

---

## 🔗 Links

- GitHub: https://github.com/Feddakalkun/Fedda_hub-v9-0
- Documentation: [Add docs link]
- Support: [Add support link]
