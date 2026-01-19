import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

export const maxDuration = 300; // 5 minutes

export async function POST(request: NextRequest) {
    try {
        const { text, voiceId, voiceProvider } = await request.json();

        if (!text) {
            return NextResponse.json({ success: false, error: 'Text is required' }, { status: 400 });
        }

        const COMFYUI_URL = process.env.COMFYUI_URL || 'http://127.0.0.1:8188';

        // First, check if VibeVoice is available
        let vibeVoiceAvailable = false;
        try {
            const objectInfoRes = await fetch(`${COMFYUI_URL}/object_info`, { signal: AbortSignal.timeout(3000) });
            if (objectInfoRes.ok) {
                const objectInfo = await objectInfoRes.json();
                vibeVoiceAvailable = !!objectInfo.VibeVoiceSingleSpeakerNode;
            }
        } catch (e) {
            console.warn('[TTS] Could not check ComfyUI nodes:', e);
        }

        if (!vibeVoiceAvailable) {
            // FALLBACK: Return reference audio file directly
            console.log('[TTS] VibeVoice not available, using reference audio fallback');
            const voicesBaseDir = path.resolve(process.cwd(), '../assets/voices');
            const voiceDir = path.join(voicesBaseDir, voiceId || 'natasha');

            let audioPath = '';
            if (fs.existsSync(voiceDir)) {
                const files = fs.readdirSync(voiceDir);
                const audioFile = files.find(f => f.endsWith('.wav') || f.endsWith('.mp3') || f.endsWith('.flac'));
                if (audioFile) {
                    audioPath = path.join(voiceDir, audioFile);
                }
            }

            if (!audioPath) {
                // Ultimate fallback
                audioPath = path.join(voicesBaseDir, 'charlotte', 'charlotte.wav');
            }

            if (!fs.existsSync(audioPath)) {
                return NextResponse.json({
                    success: false,
                    error: 'TTS system unavailable - no reference audio found'
                }, { status: 503 });
            }

            const audioBuffer = fs.readFileSync(audioPath);
            return new NextResponse(audioBuffer, {
                headers: {
                    'Content-Type': 'audio/wav',
                    'Cache-Control': 'no-cache',
                    'Content-Length': audioBuffer.byteLength.toString()
                }
            });
        }

        // VibeVoice is available - use it
        console.log(`[TTS] Generating with VibeVoice for voice: ${voiceId}`);

        // 1. Resolve Reference Audio Path
        const voicesBaseDir = path.resolve(process.cwd(), '../assets/voices');
        const selectedVoiceDir = path.join(voicesBaseDir, voiceId || 'natasha');
        let refAudioPath = '';

        if (fs.existsSync(selectedVoiceDir)) {
            const files = fs.readdirSync(selectedVoiceDir);
            const audioFile = files.find(f => f.endsWith('.wav') || f.endsWith('.mp3') || f.endsWith('.flac'));
            if (audioFile) {
                refAudioPath = path.join(selectedVoiceDir, audioFile);
            }
        }

        if (!refAudioPath) {
            // Fallback to a default
            const defaultPath = path.join(voicesBaseDir, 'natasha', 'natasha.wav');
            if (fs.existsSync(defaultPath)) {
                refAudioPath = defaultPath;
            } else {
                console.warn("[TTS] Reference audio not found even in fallback. Using 'charlotte.wav' string literal.");
                refAudioPath = "charlotte.wav"; // ComfyUI Input folder fallback
            }
        }

        // 2. Define Workflow
        const workflow = {
            "3": {
                "class_type": "LoadAudio",
                "inputs": {
                    "audio": refAudioPath
                }
            },
            "4": {
                "class_type": "VibeVoiceSingleSpeakerNode",
                "inputs": {
                    "text": text,
                    "model": "VibeVoice-1.5B",
                    "attention_type": "auto",
                    "quantize_llm": "full precision",
                    "free_memory_after_generate": true,
                    "diffusion_steps": 20,
                    "seed": Math.floor(Math.random() * 1000000),
                    "cfg_scale": 1.3,
                    "use_sampling": false,
                    "voice_to_clone": [
                        "3",
                        0
                    ]
                }
            },
            "5": {
                "class_type": "SaveAudio",
                "inputs": {
                    "filename_prefix": "VibeVoice_API_",
                    "audio": [
                        "4",
                        0
                    ]
                }
            }
        };

        // 3. Send to ComfyUI
        console.log(`[TTS] Sending to ComfyUI at ${COMFYUI_URL}`);

        const promptRes = await fetch(`${COMFYUI_URL}/prompt`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ prompt: workflow })
        });

        if (!promptRes.ok) {
            const errorText = await promptRes.text();
            throw new Error(`ComfyUI prompt error: ${errorText}`);
        }

        const { prompt_id } = await promptRes.json();
        console.log(`[TTS] Queued in ComfyUI: ${prompt_id}`);

        // 4. Poll for output
        let audioUrl = '';
        const maxAttempts = 60;
        for (let i = 0; i < maxAttempts; i++) {
            await new Promise(r => setTimeout(r, 1000));
            const histRes = await fetch(`${COMFYUI_URL}/history/${prompt_id}`);
            if (histRes.ok) {
                const history = await histRes.json();
                if (history[prompt_id]) {
                    const outputs = history[prompt_id].outputs;
                    // SaveAudio outputs an 'audio' field
                    for (const nodeId in outputs) {
                        if (outputs[nodeId].audio) {
                            const audio = outputs[nodeId].audio[0];
                            audioUrl = `${COMFYUI_URL}/view?filename=${encodeURIComponent(audio.filename)}&subfolder=${encodeURIComponent(audio.subfolder)}&type=${audio.type}`;
                            break;
                        }
                    }
                    if (audioUrl) break;

                    // If status is finished but no audio, it might have failed
                    if (history[prompt_id].status?.status === 'error') {
                        throw new Error("ComfyUI execution error during TTS generation");
                    }
                }
            }
        }

        if (!audioUrl) {
            throw new Error("TTS Generation timed out or failed to produce audio output in ComfyUI");
        }

        // 5. Fetch binary audio and return it
        console.log(`[TTS] Fetching generated audio: ${audioUrl}`);
        const finalAudioRes = await fetch(audioUrl);
        if (!finalAudioRes.ok) throw new Error("Failed to fetch generated audio from ComfyUI");

        const audioBuffer = await finalAudioRes.arrayBuffer();

        return new NextResponse(audioBuffer, {
            headers: {
                'Content-Type': 'audio/wav',
                'Cache-Control': 'no-cache',
                'Content-Length': audioBuffer.byteLength.toString()
            }
        });

    } catch (error: any) {
        console.error('[TTS] Error:', error);
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
