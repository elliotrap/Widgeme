//
//  ContentView.swift
//  Widgeme
//
//  Created by Elliot Rapp on 6/11/25.
//

import SwiftUI
import CloudKit

struct ContentView: View {
    @StateObject private var tracker = HabitTracker()

    var body: some View {
        TabView {
            NavigationView {
                HabitListView(tracker: tracker)
            }
            .tabItem {
                Label("Habits", systemImage: "checkmark.circle")
            }

            NavigationView {
                StatsView(tracker: tracker)
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
        }
    }
}

#Preview {
    ContentView()
}
