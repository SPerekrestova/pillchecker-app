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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: CheckRecord.self)
    }
}
