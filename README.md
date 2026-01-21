# Fedda Hub - AI Content Studio

**Modern web application for AI content generation with Next.js + ComfyUI**

---

## 🚀 Quick Start

### For End Users (Install Everything)

```bash
# 1. Download and extract the repository
# 2. Navigate to installer folder
cd installer

# 3. Run the installer
install.bat

# 4. Wait 20-40 minutes

# 5. Start services
run.bat
```

**Services will start on:**
- 🎨 Fedda Hub: http://localhost:3000
- 🖼️ ComfyUI: http://localhost:8188

---

### For Developers (Web App Only)

```bash
# 1. Clone repository
git clone https://github.com/Feddakalkun/Fedda_hub-v9-0.git
cd Fedda_hub-v9-0

# 2. Install dependencies
npm install

# 3. Setup database
npx prisma generate
npx prisma db push

# 4. Run dev server
npm run dev
```

Open http://localhost:3000

---

## 📁 Repository Structure

```
Fedda_hub-v9-0/
├── src/                    # Next.js application source
│   ├── app/                # App router pages & API routes
│   ├── components/         # React components
│   └── lib/                # Utilities & helpers
│
├── prisma/                 # Database schema & migrations
│
├── public/                 # Static assets
│
├── installer/              # Portable Windows installer
│   ├── scripts/
│   │   ├── core/           # Installation scripts
│   │   ├── testing/        # GPU detection & tests
│   │   └── helpers/        # Python utilities
│   ├── config/             # ComfyUI node configuration
│   ├── assets/             # Workflows & styles
│   ├── install.bat         # Main installer
│   ├── run.bat             # Start all services
│   └── update.bat          # Update components
│
├── package.json
├── tsconfig.json
└── README.md
```

---

## 💻 Development

### Web App Development
```bash
npm run dev          # Start dev server
npm run build        # Build for production
npm run lint         # Run linter
```

### Database
```bash
npx prisma studio    # Open database GUI
npx prisma generate  # Generate Prisma client
npx prisma db push   # Push schema changes
```

---

## 🔧 System Requirements

### For End Users (Full Installation)
**Minimum:**
- Windows 10/11 (64-bit)
- 16 GB RAM
- 20 GB free disk space

**Recommended:**
- NVIDIA GPU (RTX 3060+ with 8GB+ VRAM)
- 32 GB RAM
- 50 GB+ free disk space

### For Developers (Web App Only)
- Node.js 20+
- Any OS (Windows/Mac/Linux)

---

## 📚 Documentation

The portable installer includes:
- GPU auto-detection (NVIDIA/AMD/CPU)
- Automatic dependency installation
- Pre-configured ComfyUI with custom nodes
- Voice synthesis (VoxCPM)
- Local AI chat (Ollama)

See `installer/README.md` for details.

### 🔧 Installation Troubleshooting

The installer creates **detailed logs** in the `logs/` folder:
- `install_summary.txt` - Quick overview of what succeeded/failed
- `install_log_[timestamp].txt` - Full installation log
- `install_errors_[timestamp].txt` - Errors only

**Having issues?** See the comprehensive guide:
👉 **[installer/INSTALLATION_LOGS_GUIDE.md](installer/INSTALLATION_LOGS_GUIDE.md)**

Common issues covered:
- GPU detection problems
- Xformers/SageAttention installation failures
- Package conflicts
- Custom node errors

---

## 🤝 Contributing

Contributions welcome! This is a monorepo containing:
- Web application (root)
- Portable installer (`installer/`)

---

## 📄 License

[Add license information]

---

## 🔗 Links

- **GitHub:** https://github.com/Feddakalkun/Fedda_hub-v9-0
- **Issues:** https://github.com/Feddakalkun/Fedda_hub-v9-0/issues
