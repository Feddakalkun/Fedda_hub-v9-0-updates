'use client';

import { Bell, Search, Settings } from "lucide-react";
import { cn } from "@/lib/utils";

interface TopNavProps {
    className?: string;
    activeTab: 'creative' | 'companion';
    onTabChange: (tab: 'creative' | 'companion') => void;
}

export function TopNav({ className, activeTab, onTabChange }: TopNavProps) {
    return (
        <header className={cn("h-16 border-b border-border bg-background/50 backdrop-blur-md px-6 flex items-center justify-between", className)}>

            {/* Tab Switcher - The Core Navigation */}
            <div className="flex bg-secondary/50 p-1 rounded-lg">
                <button
                    onClick={() => onTabChange('creative')}
                    className={cn(
                        "px-4 py-1.5 text-sm font-medium rounded-md transition-all",
                        activeTab === 'creative'
                            ? "bg-background shadow-sm text-foreground"
                            : "text-muted-foreground hover:text-foreground"
                    )}
                >
                    Creative Studio
                </button>
                <button
                    onClick={() => onTabChange('companion')}
                    className={cn(
                        "px-4 py-1.5 text-sm font-medium rounded-md transition-all",
                        activeTab === 'companion'
                            ? "bg-background shadow-sm text-foreground"
                            : "text-muted-foreground hover:text-foreground"
                    )}
                >
                    Companion
                </button>
            </div>

            {/* Right Actions */}
            <div className="flex items-center gap-4">
                <div className="relative">
                    <Search className="w-4 h-4 text-muted-foreground absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                        placeholder="Search..."
                        className="pl-9 pr-4 py-1.5 bg-secondary/30 rounded-full text-sm border-none focus:ring-1 focus:ring-primary outline-none w-64"
                    />
                </div>

                <button className="p-2 hover:bg-secondary/80 rounded-full transition-colors relative">
                    <Bell className="w-5 h-5 text-muted-foreground" />
                    <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full" />
                </button>

                <button className="p-2 hover:bg-secondary/80 rounded-full transition-colors">
                    <Settings className="w-5 h-5 text-muted-foreground" />
                </button>

                <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-indigo-500 to-purple-500 border border-white/10" />
            </div>

        </header>
    );
}
