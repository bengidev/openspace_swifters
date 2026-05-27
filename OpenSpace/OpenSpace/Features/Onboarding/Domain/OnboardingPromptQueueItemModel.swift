import Foundation

struct OnboardingPromptQueueItemModel: Equatable, Sendable {
    enum Status: String, Equatable, Sendable {
        case running = "RUNNING"
        case next = "NEXT"
        case queued = "QUEUED"
        case ready = "READY"
    }

    var id: String { title }
    let title: String
    let detail: String
    let status: Status

    nonisolated init(title: String, detail: String, status: Status) {
        self.title = title
        self.detail = detail
        self.status = status
    }

    static let samples: [OnboardingPromptQueueItemModel] = [
        OnboardingPromptQueueItemModel(title: "Map onboarding state", detail: "Engine already owns current page", status: .running),
        OnboardingPromptQueueItemModel(title: "Generate interface cards", detail: "No vertical scroll, compact content", status: .next),
        OnboardingPromptQueueItemModel(title: "Persist completion", detail: "Storage writes local progress", status: .queued),
        OnboardingPromptQueueItemModel(title: "Review model budget", detail: "Reasoning slider updates the run", status: .ready),
    ]
}
