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
            body: String(localized: slide1Body),
            systemImageName: "sparkles"
        ),
        OnboardingSlide(
            id: 1,
            title: String(localized: "Bring Your Own Key"),
            body: String(localized: slide2Body),
            systemImageName: "key.horizontal.fill"
        ),
        OnboardingSlide(
            id: 2,
            title: String(localized: "Get Started"),
            body: String(localized: slide3Body),
            systemImageName: "checkmark.circle.fill"
        )
    ]
}

private let slide1Body: String.LocalizationValue =
    "OpenSpace includes an AI assistant that lives in the app, ready for conversation and actions when you need help."
private let slide2Body: String.LocalizationValue =
    "Connect to the model providers you configure. OpenSpace supports multiple provider configs and keeps keys in Keychain."
private let slide3Body: String.LocalizationValue =
    "You are ready to set up OpenSpace. Tap Get Started to finish onboarding and enter the app."
