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
        VStack(spacing: 16) {
            Text("\(Date().daysLeftInYear()) days left in the year")
                .font(.headline)

            Button("Mark Today Complete") {
                tracker.mark(date: Date(), completed: true)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
