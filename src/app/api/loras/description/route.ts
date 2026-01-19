import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const loraPath = searchParams.get('path');

        if (!loraPath) {
            return NextResponse.json({ description: null });
        }

        // Extract folder name from lora path (e.g., "EMMA/Emmy.safetensors" -> "EMMA")
        const folderName = loraPath.includes('/') || loraPath.includes('\\')
            ? loraPath.split(/[\/\\]/)[0]
            : path.basename(loraPath, path.extname(loraPath));

        // Build path to description.txt
        const comfyuiRoot = path.join(process.cwd(), '../ComfyUI');
        const descriptionPath = path.join(comfyuiRoot, 'models', 'loras', folderName, 'description.txt');

        console.log('[LoRA Description] Checking for:', descriptionPath);

        // Check if description.txt exists
        if (fs.existsSync(descriptionPath)) {
            const description = fs.readFileSync(descriptionPath, 'utf-8').trim();
            console.log('[LoRA Description] Found description for', folderName);
            return NextResponse.json({ description });
        } else {
            console.log('[LoRA Description] No description found for', folderName);
            return NextResponse.json({ description: null });
        }

    } catch (error: any) {
        console.error('[LoRA Description] Error:', error);
        return NextResponse.json({ description: null, error: error.message }, { status: 500 });
    }
}
