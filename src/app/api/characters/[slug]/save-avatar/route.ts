import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function POST(request: NextRequest, { params }: { params: Promise<{ slug: string }> }) {
    try {
        const { slug } = await params;
        const { promptId } = await request.json();

        console.log(`[Save Avatar] Fetching history for prompt: ${promptId}`);

        // Fetch result from ComfyUI history
        const historyRes = await fetch(`http://localhost:8188/history/${promptId}`);
        const historyData = await historyRes.json();

        console.log(`[Save Avatar] History data:`, Object.keys(historyData));

        const history = historyData[promptId];
        if (!history || !history.outputs) {
            console.error(`[Save Avatar] No history or outputs found for ${promptId}`);
            return NextResponse.json({ error: 'No outputs found' }, { status: 404 });
        }

        console.log(`[Save Avatar] Output nodes:`, Object.keys(history.outputs));

        // Find the SaveImage node output
        let imageUrl: string | null = null;
        for (const nodeId in history.outputs) {
            const nodeOutput = history.outputs[nodeId];
            if (nodeOutput.images && nodeOutput.images.length > 0) {
                const img = nodeOutput.images[0];
                // Construct URL to the image
                imageUrl = `/api/comfyui/view?filename=${img.filename}&subfolder=${img.subfolder || ''}&type=${img.type || 'output'}`;
                console.log(`[Save Avatar] Found image in node ${nodeId}: ${imageUrl}`);
                break;
            }
        }

        if (!imageUrl) {
            console.error(`[Save Avatar] No image found in any output node`);
            return NextResponse.json({ error: 'No image in outputs' }, { status: 404 });
        }

        console.log(`[Save Avatar] Saving avatar URL: ${imageUrl}`);

        // Update character with new avatar
        const character = await prisma.character.update({
            where: { slug },
            data: { avatarUrl: imageUrl }
        });

        console.log(`[Save Avatar] Success! Avatar saved for ${slug}`);

        return NextResponse.json({
            success: true,
            avatarUrl: imageUrl,
            character
        });

    } catch (error: any) {
        console.error('Save avatar error:', error);
        return NextResponse.json({ error: error.message }, { status: 500 });
    }
}
