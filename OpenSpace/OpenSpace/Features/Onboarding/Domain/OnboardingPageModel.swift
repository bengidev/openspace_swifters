import Foundation

struct OnboardingPageModel: Equatable, Sendable {
    let id: String
    let type: OnboardingPageType
    let indexLabel: String
    let eyebrow: String
    let headline: String
    let body: String
    let metric: String
    let command: String
    let shaderIntensity: Double
    let highlights: [OnboardingFeatureHighlightModel]

    nonisolated init(
        id: String,
        type: OnboardingPageType,
        indexLabel: String,
        eyebrow: String,
        headline: String,
        body: String,
        metric: String,
        command: String,
        shaderIntensity: Double,
        highlights: [OnboardingFeatureHighlightModel]
    ) {
        self.id = id
        self.type = type
        self.indexLabel = indexLabel
        self.eyebrow = eyebrow
        self.headline = headline
        self.body = body
        self.metric = metric
        self.command = command
        self.shaderIntensity = shaderIntensity
        self.highlights = highlights
    }

    nonisolated static let all: [OnboardingPageModel] = [
        OnboardingPageModel(
            id: "encrypted-pairing",
            type: .encryptedPairing,
            indexLabel: "SEC-01",
            eyebrow: "Encrypted pairing",
            headline: "End-to-end encrypted pairing and chats",
            body: "Pair trusted devices, keep local workspace context private, and open AI chats without leaking the conversation boundary.",
            metric: "E2E CHANNEL",
            command: "pair --device workspace --mode sealed",
            shaderIntensity: 0.78,
            highlights: [
                OnboardingFeatureHighlightModel(title: "Local memory", detail: "Persists offline", symbol: "externaldrive.badge.checkmark"),
                OnboardingFeatureHighlightModel(title: "Secure session", detail: "Rotates keys", symbol: "lock.shield"),
            ]
        ),
        OnboardingPageModel(
            id: "idea-studio",
            type: .ideaStudio,
            indexLabel: "AI-02",
            eyebrow: "Model workspace",
            headline: "Ask questions, write, and explore ideas with AI models",
            body: "OpenSpace turns prompts into a focused working surface for drafting, refactoring, research, and interface decisions.",
            metric: "MODEL STUDIO",
            command: "ask --model adaptive --context project",
            shaderIntensity: 0.55,
            highlights: [
                OnboardingFeatureHighlightModel(title: "Design canvas", detail: "Native cards", symbol: "square.stack.3d.up"),
                OnboardingFeatureHighlightModel(title: "AI assistance", detail: "Structured sessions", symbol: "sparkles"),
            ]
        ),
        OnboardingPageModel(
            id: "prompt-queue",
            type: .promptQueue,
            indexLabel: "RUN-03",
            eyebrow: "Queue control",
            headline: "Queue follow-up prompts while a turn is still running",
            body: "Keep momentum by lining up the next question, test request, or implementation step before the current model turn finishes.",
            metric: "LIVE QUEUE",
            command: "queue append --while-running follow-up",
            shaderIntensity: 0.66,
            highlights: [
                OnboardingFeatureHighlightModel(title: "State engine", detail: "Explicit actions", symbol: "point.3.connected.trianglepath.dotted"),
                OnboardingFeatureHighlightModel(title: "Run steering", detail: "Visible follow-ups", symbol: "arrow.triangle.branch"),
            ]
        ),
        OnboardingPageModel(
            id: "reasoning-controls",
            type: .reasoningControl,
            indexLabel: "THK-04",
            eyebrow: "Reasoning dial",
            headline: "Reasoning controls to tune how much thinking AI model uses",
            body: "Choose faster answers, balanced planning, or deeper reasoning before the AI model commits compute to the task.",
            metric: "THINK BUDGET",
            command: "model set reasoning --level balanced",
            shaderIntensity: 0.82,
            highlights: [
                OnboardingFeatureHighlightModel(title: "Model controls", detail: "Adjust thinking", symbol: "slider.horizontal.3"),
                OnboardingFeatureHighlightModel(title: "Human steering", detail: "User-set compute", symbol: "person.crop.circle.badge.checkmark"),
            ]
        ),
        OnboardingPageModel(
            id: "workspace-ready",
            type: .workspaceReady,
            indexLabel: "RDY-05",
            eyebrow: "Workspace ready",
            headline: "OpenSpace",
            body: "Your AI-native command center. Deploy specialized agents to handle code, review, test, and ship — all within your existing workflow without context switching.",
            metric: "WORKSPACE",
            command: "openspace enter --mode production",
            shaderIntensity: 0.45,
            highlights: [
                OnboardingFeatureHighlightModel(title: "Agents", detail: "Specialized runners", symbol: "cpu"),
                OnboardingFeatureHighlightModel(title: "Prompts", detail: "Structured input", symbol: "text.bubble"),
                OnboardingFeatureHighlightModel(title: "Models", detail: "Adaptive compute", symbol: "cube"),
                OnboardingFeatureHighlightModel(title: "Review", detail: "Iterative feedback", symbol: "checkmark.shield"),
                OnboardingFeatureHighlightModel(title: "Ship", detail: "Deploy ready", symbol: "paperplane.fill"),
            ]
        ),
    ]
}
