'use client';

import {
    Palette,
    Video,
    Mic,
    Workflow,
    Box,
    Database,
    MessageSquare,
    Sparkles,
    Camera,
    Heart,
    Users
} from "lucide-react";
import { cn } from "@/lib/utils";
import Link from "next/link";
import { usePathname } from "next/navigation";

interface SidebarProps {
    className?: string;
    activeTab: 'creative' | 'companion';
}

interface MenuItem {
    icon: React.ElementType;
    label: string;
    href: string;
}

export function Sidebar({ className, activeTab }: SidebarProps) {
    const pathname = usePathname();

    const creativeMenu: MenuItem[] = [
        { icon: Users, label: "Characters", href: "/studio/characters" },
        { icon: Palette, label: "Image Lab", href: "/studio/image" },
        { icon: Video, label: "Video Lab", href: "/studio/video" },
        { icon: Mic, label: "Audio Lab", href: "/studio/audio" },
        { icon: Workflow, label: "Workflows", href: "/studio/flows" },
        { icon: Box, label: "Nodes", href: "/studio/nodes" },
        { icon: Database, label: "Models", href: "/studio/models" },
    ];

    const companionMenu: MenuItem[] = [
        { icon: MessageSquare, label: "Chat", href: "/companion/chat" },
        { icon: Sparkles, label: "Skills", href: "/companion/skills" },
        { icon: Camera, label: "Selfie", href: "/companion/visuals" },
        { icon: Heart, label: "Memory", href: "/companion/memory" },
    ];

    const menu = activeTab === 'creative' ? creativeMenu : companionMenu;

    return (
        <aside className={cn("w-64 border-r border-border bg-card/50 backdrop-blur-sm flex flex-col", className)}>

            {/* Brand */}
            <div className="h-16 flex items-center px-6 border-b border-border/50">
                <span className="font-bold tracking-widest uppercase">
                    {activeTab === 'creative' ? 'STUDIO' : 'PHONE'}
                </span>
            </div>

            {/* Menu */}
            <nav className="flex-1 p-4 space-y-2">
                {menu.map((item) => {
                    const isActive = pathname.startsWith(item.href);
                    return (
                        <Link
                            key={item.href}
                            href={item.href}
                            className={cn(
                                "flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-colors",
                                isActive
                                    ? "bg-primary text-primary-foreground"
                                    : "text-muted-foreground hover:bg-secondary hover:text-foreground"
                            )}
                        >
                            <item.icon className="w-5 h-5" />
                            {item.label}
                        </Link>
                    );
                })}
            </nav>

            {/* Footer / Status */}
            <div className="p-4 border-t border-border/50">
                <div className="bg-secondary/30 rounded-lg p-3">
                    <p className="text-xs font-medium text-muted-foreground uppercase mb-2">System Status</p>
                    <div className="space-y-2">
                        <div className="flex items-center justify-between text-xs">
                            <span>ComfyUI</span>
                            <span className="text-emerald-500">Connected</span>
                        </div>
                        <div className="flex items-center justify-between text-xs">
                            <span>Ollama</span>
                            <span className="text-emerald-500">Connected</span>
                        </div>
                    </div>
                </div>
            </div>

        </aside>
    );
}
