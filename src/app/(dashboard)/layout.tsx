'use client';

import { useState } from 'react';
import { Sidebar } from '@/components/layout/sidebar';
import { TopNav } from '@/components/layout/top-nav';

export default function DashboardLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    const [activeTab, setActiveTab] = useState<'creative' | 'companion'>('creative');

    return (
        <div className="h-screen w-screen bg-background flex flex-col overflow-hidden">

            {/* Main Content Area (Sidebar + Page) */}
            <div className="flex flex-1 overflow-hidden">

                {/* Sidebar (Left) */}
                <Sidebar activeTab={activeTab} />

                {/* Right Side (TopNav + Page Content) */}
                <div className="flex-1 flex flex-col min-w-0">

                    <TopNav activeTab={activeTab} onTabChange={setActiveTab} />

                    <main className="flex-1 overflow-auto p-6 relative">
                        {/* 
                NOTE: Ideally, switching tabs would handle routing here. 
                For now we just keep the children rendered, but in reality 
                clicking the sidebar links will navigate.
                
                We might need to sync the activeTab initial state with the pathname.
             */}
                        {children}
                    </main>

                </div>
            </div>

        </div>
    );
}
