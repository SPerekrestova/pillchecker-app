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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(navigator)
        }
        .modelContainer(for: CheckRecord.self)
    }
}
