import Foundation

struct OnboardingPromptOptionModel: Equatable, Sendable {
    var id: String { prompt }
    let label: String
    let prompt: String

    nonisolated init(label: String, prompt: String) {
        self.label = label
        self.prompt = prompt
    }

    static let samples: [OnboardingPromptOptionModel] = [
        OnboardingPromptOptionModel(label: "ASK", prompt: "How should I structure the memory model for this workflow?"),
        OnboardingPromptOptionModel(label: "WRITE", prompt: "Draft a concise interface view for the secure pairing step."),
        OnboardingPromptOptionModel(label: "EXPLORE", prompt: "Compare state actions for queued prompts and reasoning controls."),
    ]
}
