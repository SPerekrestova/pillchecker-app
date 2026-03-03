//
//  ContentView.swift
//  PillChecker
//
//  Created by Svetlana Perekrestova on 3.03.26.
//

import SwiftUI

struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HistoryView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .drugInput:
                        Text("Drug Input — Coming Soon")
                    case .scan(let slot):
                        Text("Scan Slot \(slot) — Coming Soon")
                    case .search(let slot):
                        Text("Search Slot \(slot) — Coming Soon")
                    case .results(let drugA, let drugB):
                        Text("Results: \(drugA) + \(drugB) — Coming Soon")
                    case .checkDetail(let id):
                        Text("Detail \(id) — Coming Soon")
                    }
                }
        }
    }
}
