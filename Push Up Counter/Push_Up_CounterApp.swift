//
//  Push_Up_CounterApp.swift
//  Push Up Counter
//
//  Created by Fenuku kekeli on 2/1/26.
//

import SwiftUI
import StoreKit
@main
struct Push_Up_CounterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = PushUpViewModel()

    @State private var hasCompletedOnboarding =
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(viewModel)
                    .preferredColorScheme(.dark)
                    .onAppear {
                        viewModel.requestNotificationPermission()
                        scheduleFiveMinuteRatingPrompt()
                    }
            } else {
                OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
            }
        }
    }

    private func scheduleFiveMinuteRatingPrompt() {
        let hasAskedForRating =
            UserDefaults.standard.bool(forKey: "hasAskedForRating")

        guard !hasAskedForRating else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 300) { // 5 minutes
            RatingManager.requestReviewIfAppropriate()
            UserDefaults.standard.set(true, forKey: "hasAskedForRating")
        }
    }
}
enum RatingManager {

    static func requestReviewIfAppropriate() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }

        SKStoreReviewController.requestReview(in: scene)
    }
}
