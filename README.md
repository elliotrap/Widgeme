# Widgeme

This project is a simple SwiftUI application showcasing two widgets. The first
widget counts down the days left in the year. A second "Habit Progress" widget
displays your positive habit completions for the current week. The app also
includes a small `HabitTracker` class which can store daily check‑ins using
CloudKit.

### Widget

The `DaysLeftWidget` displays the remaining days in the current year and
refreshes automatically every day. The `HabitProgressWidget` shows a single
habit with checkmarks for the last seven days so you can glance at your recent
streaks right from the home screen.

### Habit Tracking

`HabitTracker` provides a starting point for storing completed days in
CloudKit. You can now add custom habits and mark each one complete for the
current day. Each check-in is saved to CloudKit so your progress syncs across
devices.

This repository only contains the Swift source files. You may need to open the
`Widgeme.xcodeproj` in Xcode and add a widget extension target to build the
widget on a device or simulator.
