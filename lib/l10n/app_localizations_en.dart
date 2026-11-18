// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Badalaty';

  @override
  String get home => 'Home';

  @override
  String get history => 'History';

  @override
  String get assignments => 'Assignments';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get shared => 'Shared transportation';

  @override
  String get travel => 'Personal travel';

  @override
  String get ride => 'Internal transportation';

  @override
  String get today => 'Today';

  @override
  String get month => 'This month';

  @override
  String get owner => 'Your entitlement';

  @override
  String get count => 'Entries';

  @override
  String get recent => 'Recent entries';

  @override
  String get activeTrip => 'Active assignment';

  @override
  String get none => 'None';

  @override
  String get empty => 'No records yet';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get saveMore => 'Save and add another';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get copy => 'Copy';

  @override
  String get date => 'Date';

  @override
  String get client => 'Client';

  @override
  String get assignment => 'Assignment';

  @override
  String get location => 'Location';

  @override
  String get notes => 'Notes';

  @override
  String get base => 'Base allowance';

  @override
  String get amount => 'Amount';

  @override
  String get people => 'Participants';

  @override
  String get multiplier => 'Multiplier';

  @override
  String get total => 'Total amount';

  @override
  String get meals => 'Meals';

  @override
  String get lodging => 'Accommodation';

  @override
  String get provider => 'Ride provider';

  @override
  String get other => 'Other';

  @override
  String get name => 'Name';

  @override
  String get employeeId => 'Employee ID';

  @override
  String get colleagues => 'Colleagues';

  @override
  String get clients => 'Clients';

  @override
  String get teams => 'Saved teams';

  @override
  String get profile => 'Owner profile';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get archived => 'Archived';

  @override
  String get addClient => 'New client';

  @override
  String get addColleague => 'New colleague';

  @override
  String get missingFields => 'Review the required fields and amounts.';

  @override
  String get duplicate =>
      'A similar entry already exists. Save this entry too?';

  @override
  String get discard => 'Discard unsaved changes?';

  @override
  String get deleteEntry => 'Delete this entry?';

  @override
  String get error => 'Could not complete this action.';

  @override
  String get start => 'Start date';

  @override
  String get end => 'End date';

  @override
  String get destination => 'Destination';

  @override
  String get planned => 'Planned';

  @override
  String get active => 'Active';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get status => 'Status';

  @override
  String get overlap => 'Dates overlap with another assignment. Continue?';

  @override
  String get recorded => 'Recorded';

  @override
  String get missing => 'Missing';

  @override
  String get leave => 'Leave';

  @override
  String get holiday => 'Holiday';

  @override
  String get weekend => 'Weekend';

  @override
  String get noAllowance => 'No allowance';

  @override
  String get future => 'Future';

  @override
  String get search => 'Search';

  @override
  String get all => 'All';

  @override
  String get calendar => 'Calendar';

  @override
  String get clear => 'Clear';

  @override
  String get language => 'Language';

  @override
  String get system => 'Follow system';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get rates => 'Default travel rates';

  @override
  String get percentage => 'Accommodation percentage';

  @override
  String get rounding =>
      'Accommodation is rounded to the nearest pound, with halves rounded up.';

  @override
  String get reminders => 'Reminders';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get workweek => 'Working days';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore backup';

  @override
  String get restoreWarning => 'Replace the current data with this backup?';

  @override
  String get restored => 'Backup restored';

  @override
  String get export => 'Export Excel';

  @override
  String get exportLanguage => 'Workbook language';

  @override
  String get dailySheet => 'Daily Entries';

  @override
  String get distributionSheet => 'Transport Distribution';

  @override
  String get travelSheet => 'Travel Allowances';

  @override
  String get rideSheet => 'Internal Transportation';

  @override
  String get employeeSheet => 'Employee Summary';

  @override
  String get periodSheet => 'Period Summary';

  @override
  String get teamTotal => 'Shared team allowance';

  @override
  String get ownerShared => 'Owner’s shared share';

  @override
  String get category => 'Category';

  @override
  String get egp => 'EGP';

  @override
  String get recordTravel => 'Record travel today';

  @override
  String get addEntry => 'Add entry';

  @override
  String get reminderBody => 'Review today’s allowance entries.';

  @override
  String get travelReminder => 'Today’s travel allowance is missing.';

  @override
  String get share => 'Share';

  @override
  String get appUpdates => 'App updates';

  @override
  String get checkingForUpdates => 'Checking GitHub for updates…';

  @override
  String installedVersion(String version) {
    return 'Installed version $version';
  }

  @override
  String updateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String get noUpdateAvailable => 'You have the latest version.';

  @override
  String get updateUnsupported => 'This update channel provides ARM64 builds.';

  @override
  String get updateCheckFailed =>
      'Could not check for updates. Check your internet connection and try again.';

  @override
  String get updateInstallFailed =>
      'The update could not be verified or opened. Try downloading it again.';

  @override
  String get updateInstallPermission =>
      'Allow installation from Badalaty in Android settings, then return and tap Install update.';

  @override
  String get downloadUpdate => 'Download & install';

  @override
  String get installUpdate => 'Install update';

  @override
  String get retryUpdate => 'Try again';

  @override
  String get preferencesSection => 'App preferences';

  @override
  String get allowanceSettingsSection => 'Allowance setup';

  @override
  String get dataSettingsSection => 'Data and app';

  @override
  String get directoryTitle => 'Clients, colleagues and teams';

  @override
  String get tripDetailsTitle => 'Assignment details';

  @override
  String get newAssignmentTitle => 'Add assignment';
}
