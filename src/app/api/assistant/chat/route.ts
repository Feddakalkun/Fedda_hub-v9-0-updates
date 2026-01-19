import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const maxDuration = 60;

export async function POST(request: NextRequest) {
    try {
        const { message, sessionId, userId = 'default' } = await request.json();

        if (!message) {
            return NextResponse.json({ error: 'Message is required' }, { status: 400 });
        }

        // Get or create session
        let session;
        if (sessionId) {
            session = await prisma.conversationSession.findUnique({
                where: { id: sessionId },
                include: {
                    messages: {
                        orderBy: { createdAt: 'asc' },
                        take: 50 // Last 50 messages for context
                    }
                }
            });
        }

        if (!session) {
            session = await prisma.conversationSession.create({
                data: {
                    userId,
                    title: message.substring(0, 50) + (message.length > 50 ? '...' : '')
                },
                include: { messages: true }
            });
        }

        // Save user message
        await prisma.conversationMessage.create({
            data: {
                sessionId: session.id,
                role: 'user',
                content: message
            }
        });

        // Build conversation history for Ollama
        const conversationHistory = session.messages.map(msg => ({
            role: msg.role,
            content: msg.content
        }));

        // Add current message
        conversationHistory.push({
            role: 'user',
            content: message
        });

        // Build system prompt with context awareness
        const systemPrompt = session.context
            ? `You are an expert AI assistant helping with: ${session.context}\n\nRemember the conversation history and stay focused on the task. Be concise and helpful.`
            : 'You are a helpful AI assistant with perfect memory of our conversation. Stay focused on the user\'s goals and provide clear, actionable answers.';

        // Call Ollama
        const OLLAMA_URL = process.env.OLLAMA_URL || 'http://127.0.0.1:11434';
        const ollamaRes = await fetch(`${OLLAMA_URL}/api/chat`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                model: 'qwen2.5:32b', // Using Qwen for better instruction following
                messages: [
                    { role: 'system', content: systemPrompt },
                    ...conversationHistory
                ],
                stream: false,
                options: {
                    temperature: 0.7,
                    num_ctx: 8192 // Large context window for memory
                }
            })
        });

        if (!ollamaRes.ok) {
            throw new Error(`Ollama error: ${ollamaRes.statusText}`);
        }

        const ollamaData = await ollamaRes.json();
        const assistantMessage = ollamaData.message.content;

        // Save assistant response
        await prisma.conversationMessage.create({
            data: {
                sessionId: session.id,
                role: 'assistant',
                content: assistantMessage
            }
        });

        // Update session timestamp
        await prisma.conversationSession.update({
            where: { id: session.id },
            data: { lastMessageAt: new Date() }
        });

        return NextResponse.json({
            success: true,
            message: assistantMessage,
            sessionId: session.id
        });

    } catch (error: any) {
        console.error('[Assistant] Error:', error);
        return NextResponse.json({
            success: false,
            error: error.message
        }, { status: 500 });
    }
}

// GET endpoint to retrieve conversation history
export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const sessionId = searchParams.get('sessionId');
        const userId = searchParams.get('userId') || 'default';

        if (sessionId) {
            // Get specific session
            const session = await prisma.conversationSession.findUnique({
                where: { id: sessionId },
                include: {
                    messages: {
                        orderBy: { createdAt: 'asc' }
                    }
                }
            });

            return NextResponse.json({ session });
        }

        // Get all sessions for user
        const sessions = await prisma.conversationSession.findMany({
            where: { userId },
            orderBy: { lastMessageAt: 'desc' },
            take: 20,
            include: {
                messages: {
                    take: 1,
                    orderBy: { createdAt: 'desc' }
                }
            }
        });

        return NextResponse.json({ sessions });

    } catch (error: any) {
        console.error('[Assistant] GET Error:', error);
        return NextResponse.json({ error: error.message }, { status: 500 });
    }
}
