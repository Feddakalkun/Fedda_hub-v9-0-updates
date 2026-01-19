import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET() {
    try {
        // Get API config from database or return defaults
        const config = await prisma.appConfig.findUnique({
            where: { id: 'global' },
            select: {
                comfyuiUrl: true,
                ollamaUrl: true,
            }
        });

        let ollamaUrl = config?.ollamaUrl || process.env.OLLAMA_URL || 'http://localhost:11434';
        // Auto-fix DB having old port
        if (ollamaUrl.includes('11435')) {
            ollamaUrl = 'http://localhost:11434';
        }

        return NextResponse.json({
            comfyuiUrl: config?.comfyuiUrl || process.env.COMFYUI_URL || 'http://localhost:8188',
            ollamaUrl: ollamaUrl,
        });
    } catch (error) {
        console.error('[API Settings] Error loading:', error);
        return NextResponse.json({
            comfyuiUrl: process.env.COMFYUI_URL || 'http://localhost:8188',
            ollamaUrl: process.env.OLLAMA_URL || 'http://localhost:11434',
        });
    }
}

export async function POST(req: NextRequest) {
    try {
        const { comfyuiUrl, ollamaUrl } = await req.json();

        // Upsert to database
        await prisma.appConfig.upsert({
            where: { id: 'global' },
            update: {
                comfyuiUrl,
                ollamaUrl,
                updatedAt: new Date(),
            },
            create: {
                id: 'global',
                comfyuiUrl,
                ollamaUrl,
            }
        });

        console.log('[API Settings] Saved successfully');
        return NextResponse.json({ success: true });
    } catch (error: any) {
        console.error('[API Settings] Error saving:', error);
        return NextResponse.json({ error: error.message }, { status: 500 });
    }
}
