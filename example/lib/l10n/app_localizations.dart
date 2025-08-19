import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

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
    Locale('it')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Node Editor Example'**
  String get appTitle;

  /// No description provided for @saveProjectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Project'**
  String get saveProjectDialogTitle;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesMsg.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to proceed without saving?'**
  String get unsavedChangesMsg;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @failedToLoadSampleProject.
  ///
  /// In en, this message translates to:
  /// **'Failed to load sample project. Please check your internet connection.'**
  String get failedToLoadSampleProject;

  /// No description provided for @searchNodesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search Nodes by Name'**
  String get searchNodesTooltip;

  /// No description provided for @toggleHierarchyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle Hierarchy Panel'**
  String get toggleHierarchyTooltip;

  /// No description provided for @toggleSnapToGridTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle Snap to Grid'**
  String get toggleSnapToGridTooltip;

  /// No description provided for @executeGraphTooltip.
  ///
  /// In en, this message translates to:
  /// **'Execute Graph'**
  String get executeGraphTooltip;

  /// No description provided for @touchCommandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Touch Commands:'**
  String get touchCommandsTitle;

  /// No description provided for @touchTap.
  ///
  /// In en, this message translates to:
  /// **'- Tap: Select Node'**
  String get touchTap;

  /// No description provided for @touchDoubleTap.
  ///
  /// In en, this message translates to:
  /// **'- Double Tap: Clear Selection'**
  String get touchDoubleTap;

  /// No description provided for @touchLongPress.
  ///
  /// In en, this message translates to:
  /// **'- Long Press: Open Context Menu'**
  String get touchLongPress;

  /// No description provided for @touchDrag.
  ///
  /// In en, this message translates to:
  /// **'- Drag: Start Linking / Select Nodes'**
  String get touchDrag;

  /// No description provided for @touchPinch.
  ///
  /// In en, this message translates to:
  /// **'- Pinch: Zoom In/Out'**
  String get touchPinch;

  /// No description provided for @touchAdditionalGestures.
  ///
  /// In en, this message translates to:
  /// **'Additional Gestures:'**
  String get touchAdditionalGestures;

  /// No description provided for @touchTwoFingerDrag.
  ///
  /// In en, this message translates to:
  /// **'- Two-Finger Drag: Pan'**
  String get touchTwoFingerDrag;

  /// No description provided for @mouseCommandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mouse Commands:'**
  String get mouseCommandsTitle;

  /// No description provided for @mouseLeftClick.
  ///
  /// In en, this message translates to:
  /// **'- Left Click: Select Node/Link'**
  String get mouseLeftClick;

  /// No description provided for @mouseRightClick.
  ///
  /// In en, this message translates to:
  /// **'- Right Click: Open Context Menu'**
  String get mouseRightClick;

  /// No description provided for @mouseScroll.
  ///
  /// In en, this message translates to:
  /// **'- Scroll: Zoom In/Out'**
  String get mouseScroll;

  /// No description provided for @mouseMiddleClick.
  ///
  /// In en, this message translates to:
  /// **'- Middle Click: Pan'**
  String get mouseMiddleClick;

  /// No description provided for @keyboardCommandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Commands:'**
  String get keyboardCommandsTitle;

  /// No description provided for @keyboardSave.
  ///
  /// In en, this message translates to:
  /// **'- {comboKey} + S: Save Project'**
  String keyboardSave(String comboKey);

  /// No description provided for @keyboardOpen.
  ///
  /// In en, this message translates to:
  /// **'- {comboKey} + O: Open Project'**
  String keyboardOpen(String comboKey);

  /// No description provided for @keyboardNew.
  ///
  /// In en, this message translates to:
  /// **'- {comboKey} + Shift + N: New Project'**
  String keyboardNew(String comboKey);

  /// No description provided for @keyboardCopy.
  ///
  /// In en, this message translates to:
  /// **'- {comboKey} + C: Copy Node'**
  String keyboardCopy(String comboKey);

  /// No description provided for @keyboardPaste.
  ///
  /// In en, this message translates to:
  /// **'- {comboKey} + V: Paste Node'**
  String keyboardPaste(String comboKey);

  /// No description provided for @keyboardCut.
  ///
  /// In en, this message translates to:
  /// **'- {comboKey} + X: Cut Node'**
  String keyboardCut(String comboKey);

  /// No description provided for @keyboardDelete.
  ///
  /// In en, this message translates to:
  /// **'- Delete | Backspace: Remove Node'**
  String get keyboardDelete;

  /// No description provided for @keyboardUndo.
  ///
  /// In en, this message translates to:
  /// **'- {comboKey} + Z: Undo'**
  String keyboardUndo(String comboKey);

  /// No description provided for @keyboardRedo.
  ///
  /// In en, this message translates to:
  /// **'- {comboKey} + Y: Redo'**
  String keyboardRedo(String comboKey);

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @nextResult.
  ///
  /// In en, this message translates to:
  /// **'Next Result'**
  String get nextResult;

  /// No description provided for @previousResult.
  ///
  /// In en, this message translates to:
  /// **'Previous Result'**
  String get previousResult;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsCount(int count);

  /// No description provided for @resultPosition.
  ///
  /// In en, this message translates to:
  /// **'{current} di {total}'**
  String resultPosition(int current, int total);

  /// No description provided for @numericValueNodeName.
  ///
  /// In en, this message translates to:
  /// **'Numeric Value'**
  String get numericValueNodeName;

  /// No description provided for @booleanValueNodeName.
  ///
  /// In en, this message translates to:
  /// **'Boolean Value'**
  String get booleanValueNodeName;

  /// No description provided for @stringValueNodeName.
  ///
  /// In en, this message translates to:
  /// **'String Value'**
  String get stringValueNodeName;

  /// No description provided for @numericListValueNodeName.
  ///
  /// In en, this message translates to:
  /// **'Numeric List Value'**
  String get numericListValueNodeName;

  /// No description provided for @booleanListValueNodeName.
  ///
  /// In en, this message translates to:
  /// **'Boolean List Value'**
  String get booleanListValueNodeName;

  /// No description provided for @stringListValueNodeName.
  ///
  /// In en, this message translates to:
  /// **'String List Value'**
  String get stringListValueNodeName;

  /// No description provided for @valueNodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Holds a constant {type} value.'**
  String valueNodeDescription(String type);

  /// No description provided for @completedPortName.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedPortName;

  /// No description provided for @valuePortName.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valuePortName;

  /// No description provided for @valueFieldName.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueFieldName;

  /// No description provided for @operatorNodeName.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get operatorNodeName;

  /// No description provided for @operatorNodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Applies a chosen operation to two numbers.'**
  String get operatorNodeDescription;

  /// No description provided for @execPortName.
  ///
  /// In en, this message translates to:
  /// **'Exec'**
  String get execPortName;

  /// No description provided for @resultPortName.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultPortName;

  /// No description provided for @operationPortName.
  ///
  /// In en, this message translates to:
  /// **'Operation'**
  String get operationPortName;

  /// No description provided for @addFieldOption.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addFieldOption;

  /// No description provided for @subtractFieldOption.
  ///
  /// In en, this message translates to:
  /// **'Subtract'**
  String get subtractFieldOption;

  /// No description provided for @multiplyFieldOption.
  ///
  /// In en, this message translates to:
  /// **'Multiply'**
  String get multiplyFieldOption;

  /// No description provided for @divideFieldOption.
  ///
  /// In en, this message translates to:
  /// **'Divide'**
  String get divideFieldOption;

  /// No description provided for @randomNodeName.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get randomNodeName;

  /// No description provided for @randomNodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Outputs a random number between 0 and 1.'**
  String get randomNodeDescription;

  /// No description provided for @ifNodeName.
  ///
  /// In en, this message translates to:
  /// **'If'**
  String get ifNodeName;

  /// No description provided for @ifNodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Executes a branch based on a condition.'**
  String get ifNodeDescription;

  /// No description provided for @conditionPortName.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get conditionPortName;

  /// No description provided for @truePortName.
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get truePortName;

  /// No description provided for @falsePortName.
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get falsePortName;

  /// No description provided for @comparatorNodeName.
  ///
  /// In en, this message translates to:
  /// **'Comparator'**
  String get comparatorNodeName;

  /// No description provided for @comparatorNodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Compares two numbers based on a chosen comparator.'**
  String get comparatorNodeDescription;

  /// No description provided for @comparatorPortName.
  ///
  /// In en, this message translates to:
  /// **'Comparator'**
  String get comparatorPortName;

  /// No description provided for @equalFieldOption.
  ///
  /// In en, this message translates to:
  /// **'=='**
  String get equalFieldOption;

  /// No description provided for @notEqualFieldOption.
  ///
  /// In en, this message translates to:
  /// **'!='**
  String get notEqualFieldOption;

  /// No description provided for @greaterFieldOption.
  ///
  /// In en, this message translates to:
  /// **'>'**
  String get greaterFieldOption;

  /// No description provided for @greaterEqualFieldOption.
  ///
  /// In en, this message translates to:
  /// **'>='**
  String get greaterEqualFieldOption;

  /// No description provided for @lessFieldOption.
  ///
  /// In en, this message translates to:
  /// **'<'**
  String get lessFieldOption;

  /// No description provided for @lessEqualFieldOption.
  ///
  /// In en, this message translates to:
  /// **'<='**
  String get lessEqualFieldOption;

  /// No description provided for @printNodeName.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printNodeName;

  /// No description provided for @printNodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Prints a value to the console.'**
  String get printNodeDescription;

  /// No description provided for @printNodeSnackbarMessage.
  ///
  /// In en, this message translates to:
  /// **'Value: {value}'**
  String printNodeSnackbarMessage(String value);

  /// No description provided for @roundNodeName.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get roundNodeName;

  /// No description provided for @roundNodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Rounds a number to a specified number of decimals.'**
  String get roundNodeDescription;

  /// No description provided for @roundedPortName.
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get roundedPortName;

  /// No description provided for @decimalsFieldName.
  ///
  /// In en, this message translates to:
  /// **'Decimals'**
  String get decimalsFieldName;

  /// No description provided for @forEachLoopNodeName.
  ///
  /// In en, this message translates to:
  /// **'For Each Loop'**
  String get forEachLoopNodeName;

  /// No description provided for @forEachLoopNodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Executes a loop for each element in a list executing an operation.'**
  String get forEachLoopNodeDescription;

  /// No description provided for @listPortName.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listPortName;

  /// No description provided for @loopBodyPortName.
  ///
  /// In en, this message translates to:
  /// **'Loop Body'**
  String get loopBodyPortName;

  /// No description provided for @listElementPortName.
  ///
  /// In en, this message translates to:
  /// **'List Element'**
  String get listElementPortName;

  /// No description provided for @listIndexPortName.
  ///
  /// In en, this message translates to:
  /// **'List Index'**
  String get listIndexPortName;
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
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
