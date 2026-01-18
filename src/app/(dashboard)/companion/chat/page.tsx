export default function CompanionChat() {
    return (
        <div className="flex flex-col h-full">
            <h1 className="text-2xl font-bold mb-4 px-2">Companion Chat</h1>
            <div className="flex-1 bg-card rounded-xl border border-border p-6 shadow-sm flex flex-col justify-between">
                <div className="flex-1 flex items-center justify-center">
                    <p className="text-muted-foreground">Ollama Integration Pending...</p>
                </div>
                <div className="mt-4 flex gap-2">
                    <input className="flex-1 bg-secondary p-3 rounded-lg text-sm" placeholder="Type a message..." disabled />
                    <button className="bg-primary text-primary-foreground px-4 py-2 rounded-lg text-sm font-medium opacity-50 cursor-not-allowed">Send</button>
                </div>
            </div>
        </div>
    );
}
