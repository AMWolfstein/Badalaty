# Architecture

Flutter owns financial calculation, localization and navigation. SQLite via Drift stores local calendar dates as ISO dates and audit timestamps in UTC. Totals are derived from committed entries and persisted allocation snapshots. Android receives display data through a method channel and opens prefilled Flutter routes through native actions.

An iOS WidgetKit extension can consume the same display contract through an App Group. The iOS runner can build independently of Android widgets.
