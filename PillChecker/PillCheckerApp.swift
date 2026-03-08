//
//  PillCheckerApp.swift
//  PillChecker
//
//  Created by Svetlana Perekrestova on 3.03.26.
//

import SwiftUI
import SwiftData

@main
struct PillCheckerApp: App {
    @State private var navigator = AppNavigator()
    @State private var hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    .environment(navigator)
            } else {
                OnboardingView(isComplete: $hasSeenOnboarding)
            }
        }
        .modelContainer(for: CheckRecord.self)
    }
}
