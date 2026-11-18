import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Badalaty'**
  String get title;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @assignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignments;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @shared.
  ///
  /// In en, this message translates to:
  /// **'Shared transportation'**
  String get shared;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Personal travel'**
  String get travel;

  /// No description provided for @ride.
  ///
  /// In en, this message translates to:
  /// **'Internal transportation'**
  String get ride;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get month;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Your entitlement'**
  String get owner;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get count;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent entries'**
  String get recent;

  /// No description provided for @activeTrip.
  ///
  /// In en, this message translates to:
  /// **'Active assignment'**
  String get activeTrip;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get empty;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveMore.
  ///
  /// In en, this message translates to:
  /// **'Save and add another'**
  String get saveMore;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @assignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get assignment;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @base.
  ///
  /// In en, this message translates to:
  /// **'Base allowance'**
  String get base;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get people;

  /// No description provided for @multiplier.
  ///
  /// In en, this message translates to:
  /// **'Multiplier'**
  String get multiplier;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get total;

  /// No description provided for @meals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get meals;

  /// No description provided for @lodging.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get lodging;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Ride provider'**
  String get provider;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeId;

  /// No description provided for @colleagues.
  ///
  /// In en, this message translates to:
  /// **'Colleagues'**
  String get colleagues;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @teams.
  ///
  /// In en, this message translates to:
  /// **'Saved teams'**
  String get teams;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Owner profile'**
  String get profile;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @addClient.
  ///
  /// In en, this message translates to:
  /// **'New client'**
  String get addClient;

  /// No description provided for @addColleague.
  ///
  /// In en, this message translates to:
  /// **'New colleague'**
  String get addColleague;

  /// No description provided for @missingFields.
  ///
  /// In en, this message translates to:
  /// **'Review the required fields and amounts.'**
  String get missingFields;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'A similar entry already exists. Save this entry too?'**
  String get duplicate;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get discard;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteEntry;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Could not complete this action.'**
  String get error;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get end;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planned;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @overlap.
  ///
  /// In en, this message translates to:
  /// **'Dates overlap with another assignment. Continue?'**
  String get overlap;

  /// No description provided for @recorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get recorded;

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missing;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @holiday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get holiday;

  /// No description provided for @weekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get weekend;

  /// No description provided for @noAllowance.
  ///
  /// In en, this message translates to:
  /// **'No allowance'**
  String get noAllowance;

  /// No description provided for @future.
  ///
  /// In en, this message translates to:
  /// **'Future'**
  String get future;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get system;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @rates.
  ///
  /// In en, this message translates to:
  /// **'Default travel rates'**
  String get rates;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Accommodation percentage'**
  String get percentage;

  /// No description provided for @rounding.
  ///
  /// In en, this message translates to:
  /// **'Accommodation is rounded to the nearest pound, with halves rounded up.'**
  String get rounding;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @workweek.
  ///
  /// In en, this message translates to:
  /// **'Working days'**
  String get workweek;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restore;

  /// No description provided for @restoreWarning.
  ///
  /// In en, this message translates to:
  /// **'Replace the current data with this backup?'**
  String get restoreWarning;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored'**
  String get restored;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get export;

  /// No description provided for @exportLanguage.
  ///
  /// In en, this message translates to:
  /// **'Workbook language'**
  String get exportLanguage;

  /// No description provided for @dailySheet.
  ///
  /// In en, this message translates to:
  /// **'Daily Entries'**
  String get dailySheet;

  /// No description provided for @distributionSheet.
  ///
  /// In en, this message translates to:
  /// **'Transport Distribution'**
  String get distributionSheet;

  /// No description provided for @travelSheet.
  ///
  /// In en, this message translates to:
  /// **'Travel Allowances'**
  String get travelSheet;

  /// No description provided for @rideSheet.
  ///
  /// In en, this message translates to:
  /// **'Internal Transportation'**
  String get rideSheet;

  /// No description provided for @employeeSheet.
  ///
  /// In en, this message translates to:
  /// **'Employee Summary'**
  String get employeeSheet;

  /// No description provided for @periodSheet.
  ///
  /// In en, this message translates to:
  /// **'Period Summary'**
  String get periodSheet;

  /// No description provided for @teamTotal.
  ///
  /// In en, this message translates to:
  /// **'Shared team allowance'**
  String get teamTotal;

  /// No description provided for @ownerShared.
  ///
  /// In en, this message translates to:
  /// **'Owner’s shared share'**
  String get ownerShared;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @egp.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get egp;

  /// No description provided for @recordTravel.
  ///
  /// In en, this message translates to:
  /// **'Record travel today'**
  String get recordTravel;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addEntry;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Review today’s allowance entries.'**
  String get reminderBody;

  /// No description provided for @travelReminder.
  ///
  /// In en, this message translates to:
  /// **'Today’s travel allowance is missing.'**
  String get travelReminder;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @appUpdates.
  ///
  /// In en, this message translates to:
  /// **'App updates'**
  String get appUpdates;

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking GitHub for updates…'**
  String get checkingForUpdates;

  /// No description provided for @installedVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed version {version}'**
  String installedVersion(String version);

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateAvailable(String version);

  /// No description provided for @noUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'You have the latest version.'**
  String get noUpdateAvailable;

  /// No description provided for @updateUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This update channel provides ARM64 builds.'**
  String get updateUnsupported;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates. Check your internet connection and try again.'**
  String get updateCheckFailed;

  /// No description provided for @updateInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'The update could not be verified or opened. Try downloading it again.'**
  String get updateInstallFailed;

  /// No description provided for @updateInstallPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow installation from Badalaty in Android settings, then return and tap Install update.'**
  String get updateInstallPermission;

  /// No description provided for @downloadUpdate.
  ///
  /// In en, this message translates to:
  /// **'Download & install'**
  String get downloadUpdate;

  /// No description provided for @installUpdate.
  ///
  /// In en, this message translates to:
  /// **'Install update'**
  String get installUpdate;

  /// No description provided for @retryUpdate.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryUpdate;

  /// No description provided for @preferencesSection.
  ///
  /// In en, this message translates to:
  /// **'App preferences'**
  String get preferencesSection;

  /// No description provided for @allowanceSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Allowance setup'**
  String get allowanceSettingsSection;

  /// No description provided for @dataSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Data and app'**
  String get dataSettingsSection;

  /// No description provided for @directoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clients, colleagues and teams'**
  String get directoryTitle;

  /// No description provided for @tripDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignment details'**
  String get tripDetailsTitle;

  /// No description provided for @newAssignmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add assignment'**
  String get newAssignmentTitle;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toDate;

  /// No description provided for @allClients.
  ///
  /// In en, this message translates to:
  /// **'All clients'**
  String get allClients;

  /// No description provided for @allAssignments.
  ///
  /// In en, this message translates to:
  /// **'All assignments'**
  String get allAssignments;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get allCategories;

  /// No description provided for @periodAllowance.
  ///
  /// In en, this message translates to:
  /// **'Total allowance for the period'**
  String get periodAllowance;

  /// No description provided for @allowanceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown by allowance type'**
  String get allowanceBreakdown;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get exportReport;

  /// No description provided for @chooseAllowanceType.
  ///
  /// In en, this message translates to:
  /// **'Choose an allowance type'**
  String get chooseAllowanceType;

  /// No description provided for @sharedDescription.
  ///
  /// In en, this message translates to:
  /// **'Travel share based on the number of colleagues'**
  String get sharedDescription;

  /// No description provided for @travelDescription.
  ///
  /// In en, this message translates to:
  /// **'Meals and accommodation during an assignment'**
  String get travelDescription;

  /// No description provided for @rideDescription.
  ///
  /// In en, this message translates to:
  /// **'Ride services and other local transport costs'**
  String get rideDescription;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @seeAllowanceTypes.
  ///
  /// In en, this message translates to:
  /// **'See types'**
  String get seeAllowanceTypes;

  /// No description provided for @office.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get office;

  /// No description provided for @recordType.
  ///
  /// In en, this message translates to:
  /// **'Record type'**
  String get recordType;

  /// No description provided for @addAllowance.
  ///
  /// In en, this message translates to:
  /// **'Add allowance'**
  String get addAllowance;

  /// No description provided for @allowanceOption.
  ///
  /// In en, this message translates to:
  /// **'Allowance'**
  String get allowanceOption;

  /// No description provided for @allowanceOptionDescription.
  ///
  /// In en, this message translates to:
  /// **'Shared transport, travel or internal transport'**
  String get allowanceOptionDescription;

  /// No description provided for @leaveRecordDescription.
  ///
  /// In en, this message translates to:
  /// **'Record a day off'**
  String get leaveRecordDescription;

  /// No description provided for @officeRecordDescription.
  ///
  /// In en, this message translates to:
  /// **'Record a day at the office'**
  String get officeRecordDescription;

  /// No description provided for @recordLeave.
  ///
  /// In en, this message translates to:
  /// **'Record leave'**
  String get recordLeave;

  /// No description provided for @recordOffice.
  ///
  /// In en, this message translates to:
  /// **'Record an office day'**
  String get recordOffice;

  /// No description provided for @recordValue.
  ///
  /// In en, this message translates to:
  /// **'Record value'**
  String get recordValue;

  /// No description provided for @saveRecordLabel.
  ///
  /// In en, this message translates to:
  /// **'Save record'**
  String get saveRecordLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
