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
    @State private var showAddSheet = false
    @State private var editingHabit: PositiveHabit?
    @State private var editedName = ""
    @State private var showCloudAlert = false

    var body: some View {
        TabView {
            // MARK: – Habits Tab
            NavigationView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("\(Date().daysLeftInYear()) days left in the year")
                        .font(.title2.weight(.semibold))

                    HStack {
                        Spacer()
                        Button {
                            showAddSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    List {
                        ForEach(tracker.habits, id: \.id) { habit in
                            HabitRowView(habit: habit, tracker: tracker)
                                .padding(.vertical, 4)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        tracker.deleteHabit(habit)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        editingHabit = habit
                                        editedName = habit.name
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                        .onMove { indices, newOffset in
                            tracker.habits.move(fromOffsets: indices, toOffset: newOffset)
                        }
                    }
                    .listStyle(.plain)
                }
                .padding()
                .navigationTitle("Positive Habits")
                .toolbar {
                    EditButton()
                }
                .onAppear {
                    tracker.checkAccountStatus { status in
                        if status == .available {
                            tracker.fetchHabits { _ in
                                tracker.fetchAllRecords { _ in }
                            }
                        } else {
                            showCloudAlert = true
                        }
                    }
                }
            }
            .tabItem {
                Label("Habits", systemImage: "checkmark.circle")
            }

            // MARK: – Stats Tab
            NavigationView {
                StatsView(tracker: tracker)
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
        }
        // Edit sheet
        .sheet(item: $editingHabit) { habit in
            NavigationView {
                VStack(spacing: 16) {
                    TextField("Habit Name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                    Spacer()
                }
                .navigationTitle("Edit Habit")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { editingHabit = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let habitToEdit = editingHabit {
                                tracker.updateHabit(habitToEdit, name: editedName)
                            }
                            editingHabit = nil
                        }
                        .disabled(editedName.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        // Add habit sheet
        .sheet(isPresented: $showAddSheet) {
            AddHabitView(tracker: tracker)
        }
        // iCloud alert
        .alert("iCloud Unavailable", isPresented: $showCloudAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Sign in to iCloud to sync habits across devices.")
        }
    }
}

#Preview {
    ContentView()
}
