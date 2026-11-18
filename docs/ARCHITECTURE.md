# Architecture

Flutter owns financial calculations, localization and navigation. Riverpod loads committed records through Drift. SQLite stores local calendar dates as ISO dates and records audit timestamps in UTC. Calculations persist whole-EGP snapshots in the same transaction as their audit entries. Reports derive totals from committed snapshots and reconcile shared distributions before writing the workbook.

The Android bridge publishes calculated daily summaries to private preferences. Native AppWidgets format and render the current summary and open Flutter routes. Android schedules local refreshes and reminders with AlarmManager. An iOS WidgetKit extension can use the same data contract through an App Group, with SwiftUI for presentation.

Backups contain a versioned logical snapshot of records and audit data. Integrity checks run before a restore, and SQLite rolls back replacement if a write fails.
