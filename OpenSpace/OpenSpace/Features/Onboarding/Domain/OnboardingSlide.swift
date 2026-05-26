import Foundation

struct OnboardingSlide: Equatable, Identifiable {
    let id: Int
    let title: String
    let body: String
    let systemImageName: String

    static let all: [OnboardingSlide] = [
        OnboardingSlide(
            id: 0,
            title: String(localized: "Meet Your Assistant"),
            body: String(localized: "OpenSpace includes an AI assistant that lives in the app, ready for conversation and actions when you need help."),
            systemImageName: "sparkles"
        ),
        OnboardingSlide(
            id: 1,
            title: String(localized: "Bring Your Own Key"),
            body: String(localized: "Connect to the model providers you configure. OpenSpace supports multiple provider configs and keeps keys in Keychain."),
            systemImageName: "key.horizontal.fill"
        ),
        OnboardingSlide(
            id: 2,
            title: String(localized: "Get Started"),
            body: String(localized: "You are ready to set up OpenSpace. Tap Get Started to finish onboarding and enter the app."),
            systemImageName: "checkmark.circle.fill"
        )
    ]
}
