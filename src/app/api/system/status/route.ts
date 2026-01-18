import { NextResponse } from 'next/server';

export async function GET() {
    // Simulate a check (always ready for now)
    // In the future this will actually ping ComfyUI and Ollama
    return NextResponse.json({
        status: 'ready',
        comfyui: 'connected',
        ollama: 'connected'
    });
}
