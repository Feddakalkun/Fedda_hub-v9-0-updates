export default function StudioPage() {
    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
                <div className="text-sm text-muted-foreground">
                    Welcome back, Creator.
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {/* Quick Actions */}
                <div className="p-6 rounded-xl border bg-card shadow-sm hover:shadow-md transition-shadow">
                    <h3 className="font-semibold mb-2">Image Gen</h3>
                    <p className="text-sm text-muted-foreground mb-4">Create new visuals using Stable Diffusion.</p>
                    <button className="text-primary text-sm font-medium">Open Lab &rarr;</button>
                </div>

                <div className="p-6 rounded-xl border bg-card shadow-sm hover:shadow-md transition-shadow">
                    <h3 className="font-semibold mb-2">Chat with Partner</h3>
                    <p className="text-sm text-muted-foreground mb-4">Resume conversation with your AI companion.</p>
                    <button className="text-primary text-sm font-medium">Open Phone &rarr;</button>
                </div>

                <div className="p-6 rounded-xl border bg-card shadow-sm hover:shadow-md transition-shadow">
                    <h3 className="font-semibold mb-2">System Health</h3>
                    <p className="text-sm text-muted-foreground mb-4">All systems operational.</p>
                    <div className="h-2 bg-secondary rounded-full overflow-hidden">
                        <div className="h-full w-3/4 bg-emerald-500 rounded-full" />
                    </div>
                </div>
            </div>

        </div>
    );
}
