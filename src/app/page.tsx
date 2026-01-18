'use client';

import Link from 'next/link';
import { useState, useEffect } from 'react';
import { cn } from '@/lib/utils';

export default function LandingPage() {
  const [systemReady, setSystemReady] = useState(false);
  const [statusMessage, setStatusMessage] = useState('Initializing System...');

  useEffect(() => {
    let attempts = 0;
    const maxAttempts = 60; // 1 minute max wait

    const checkSystem = async () => {
      try {
        // Check our new internal API
        const res = await fetch('/api/system/status');

        if (res.ok) {
          setSystemReady(true);
          setStatusMessage('System Operational');
          return;
        }
      } catch (e) {
        console.log('System check failed:', e);
      }

      attempts++;
      if (attempts < maxAttempts) {
        setStatusMessage(`Connecting to Neural Core... (${attempts}s)`);
        // Simulate boot delay for "authenticity"
        setTimeout(checkSystem, 1000);
      } else {
        setStatusMessage('System Offline - Manual Override Available');
      }
    };

    // Artificial delay effectively acts as a loading screen
    setTimeout(checkSystem, 2500);
  }, []);

  return (
    <main className="relative w-screen h-screen overflow-hidden bg-black text-white flex flex-col items-center justify-center">

      {/* Background Video */}
      <video
        key={systemReady ? 'ready' : 'loading'}
        autoPlay
        loop
        muted
        playsInline
        className="absolute top-0 left-0 w-full h-full object-cover opacity-60 pointer-events-none grayscale-[100%] contrast-125 transition-opacity duration-1000"
      >
        <source src={systemReady ? '/done-loading.mp4' : '/bg.mp4'} type="video/mp4" />
      </video>

      {/* Gradient Overlay */}
      <div className="absolute inset-0 bg-[radial-gradient(circle,rgba(0,0,0,0.2)_0%,rgba(0,0,0,0.8)_100%)] z-10" />

      {/* Content */}
      <div className="relative z-20 flex flex-col items-center gap-8 text-center">

        {/* Logo / Header */}
        <div className="flex flex-col items-center">
          <h1 className="text-6xl md:text-8xl font-extrabold tracking-[0.15em] uppercase text-transparent bg-clip-text bg-gradient-to-b from-white to-neutral-400 drop-shadow-2xl">
            FEDDA HUB
          </h1>
          <h2 className="text-xl md:text-2xl font-light tracking-[0.5em] text-neutral-500 uppercase -mt-2">
            Advanced Workstation
          </h2>
        </div>

        {/* Status Indicator */}
        {!systemReady && (
          <div className="flex flex-col items-center gap-4">
            <div className="relative">
              <div className="w-10 h-10 border-4 border-white/20 border-t-white rounded-full animate-spin" />
            </div>
            <p className="text-xs tracking-[0.2em] text-neutral-400 uppercase animate-pulse">
              {statusMessage}
            </p>
          </div>
        )}

        {/* Actions */}
        <div className="mt-16 flex flex-col items-center gap-4">
          {systemReady ? (
            <Link href="/studio">
              <button
                className="group relative px-20 py-5 bg-transparent border-2 border-white text-white text-sm font-medium tracking-[0.3em] uppercase transition-all duration-300 hover:bg-white hover:text-black hover:shadow-[0_0_60px_rgba(255,255,255,0.3)]"
              >
                <span className="relative z-10">Enter Studio</span>
              </button>
            </Link>
          ) : (
            <button
              disabled
              className="px-20 py-5 bg-transparent border-2 border-neutral-800 text-neutral-600 text-sm font-medium tracking-[0.3em] uppercase cursor-not-allowed opacity-50"
            >
              Loading...
            </button>
          )}

          {/* Developer Bypass */}
          <Link href="/studio" className={cn(
            "mt-8 text-[10px] tracking-widest text-neutral-700 hover:text-neutral-500 transition-colors uppercase",
            systemReady && "hidden"
          )}>
            [ Developer Override ]
          </Link>
        </div>

      </div>
    </main>
  );
}
