# Requirements traceability

| Workflow | Implementation | Automated coverage |
| --- | --- | --- |
| Whole-EGP shared allowance, travel and internal rides | `lib/allowances`, persisted through `lib/data/store.dart` | `calculation_test.dart`, `store_and_workbook_test.dart` |
| Owner profile, client/employee directory and teams | `lib/settings` | Historical employee archive and ID checks in `store_and_workbook_test.dart` |
| Assignment lifecycle, recorded and missing days | `lib/assignments`, `lib/history` | Seven-day Hurghada scenario in `store_and_workbook_test.dart` |
| Independent EN/AR localized screens and reports | `lib/l10n`, `lib/reports` | Language/direction and workbook coverage |
| Audit, migration and backup restore | `lib/data/store.dart`, `lib/backup` | SQLite migration and failed-restore rollback |
| Android widgets and reminders | Android app resources and Kotlin code, with `lib/widgets/platform.dart` providing committed summaries | Device verification checklist in the implementation plan |
