# Implementation and verification

1. Initialize the Flutter Android and iOS runners and generate English/Arabic localization.
2. Add SQLite persistence and test integer calculations, historical snapshots and migration.
3. Connect the three entry forms, settings, assignments and calendar.
4. Connect workbook export, backup/restore and the Android widget and reminder bridge.
5. Run formatting checks, static analysis and automated tests. Build the APK and check its manifest.

## Android device verification

- In airplane mode, create an owner with ID `0012`, a client, colleagues and a seven-day active assignment. Save the first and last travel days independently and check the missing days remain visible.
- Add shared and internal entries on the same date. Verify the home entitlement, both widgets and the two workbook languages against the recorded owner shares.
- Tap each widget action, switch between Arabic and English, change theme and reopen after midnight or reboot.
- Enable reminders on a permitted Android version. Check a holiday, a recorded general day, and a trip day containing a ride but no travel entry.
- Share a workbook, export a backup, edit an entry and restore the backup. Check the original amounts, IDs and allocation.
