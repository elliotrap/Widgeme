# Widgeme

This project is a simple SwiftUI application showcasing a widget that tells you
how many days are left in the year. The app also includes a very small
`HabitTracker` class which can store daily check‑ins using CloudKit.

### Widget

The widget (`DaysLeftWidget`) displays the remaining days in the current year.
It refreshes automatically every day.

### Habit Tracking

`HabitTracker` provides a starting point for storing completed days in
CloudKit. Each time the **Mark Today Complete** button is tapped the day is
recorded.

This repository only contains the Swift source files. You may need to open the
`Widgeme.xcodeproj` in Xcode and add a widget extension target to build the
widget on a device or simulator.

### Entitlements

The app requires a `Widgeme.entitlements` file to enable CloudKit. The sample file in this repository uses a placeholder container identifier (`iCloud.com.example.widgeme`). Update it to match your own iCloud container before building.
