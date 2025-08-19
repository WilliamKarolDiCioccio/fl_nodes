// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Node Editor Example';

  @override
  String get saveProjectDialogTitle => 'Save Project';

  @override
  String get unsavedChangesTitle => 'Unsaved Changes';

  @override
  String get unsavedChangesMsg =>
      'You have unsaved changes. Do you want to proceed without saving?';

  @override
  String get cancel => 'Cancel';

  @override
  String get proceed => 'Proceed';

  @override
  String get failedToLoadSampleProject =>
      'Failed to load sample project. Please check your internet connection.';

  @override
  String get searchNodesTooltip => 'Search Nodes by Name';

  @override
  String get toggleHierarchyTooltip => 'Toggle Hierarchy Panel';

  @override
  String get toggleSnapToGridTooltip => 'Toggle Snap to Grid';

  @override
  String get executeGraphTooltip => 'Execute Graph';

  @override
  String get touchCommandsTitle => 'Touch Commands:';

  @override
  String get touchTap => '- Tap: Select Node';

  @override
  String get touchDoubleTap => '- Double Tap: Clear Selection';

  @override
  String get touchLongPress => '- Long Press: Open Context Menu';

  @override
  String get touchDrag => '- Drag: Start Linking / Select Nodes';

  @override
  String get touchPinch => '- Pinch: Zoom In/Out';

  @override
  String get touchAdditionalGestures => 'Additional Gestures:';

  @override
  String get touchTwoFingerDrag => '- Two-Finger Drag: Pan';

  @override
  String get mouseCommandsTitle => 'Mouse Commands:';

  @override
  String get mouseLeftClick => '- Left Click: Select Node/Link';

  @override
  String get mouseRightClick => '- Right Click: Open Context Menu';

  @override
  String get mouseScroll => '- Scroll: Zoom In/Out';

  @override
  String get mouseMiddleClick => '- Middle Click: Pan';

  @override
  String get keyboardCommandsTitle => 'Keyboard Commands:';

  @override
  String keyboardSave(String comboKey) {
    return '- $comboKey + S: Save Project';
  }

  @override
  String keyboardOpen(String comboKey) {
    return '- $comboKey + O: Open Project';
  }

  @override
  String keyboardNew(String comboKey) {
    return '- $comboKey + Shift + N: New Project';
  }

  @override
  String keyboardCopy(String comboKey) {
    return '- $comboKey + C: Copy Node';
  }

  @override
  String keyboardPaste(String comboKey) {
    return '- $comboKey + V: Paste Node';
  }

  @override
  String keyboardCut(String comboKey) {
    return '- $comboKey + X: Cut Node';
  }

  @override
  String get keyboardDelete => '- Delete | Backspace: Remove Node';

  @override
  String keyboardUndo(String comboKey) {
    return '- $comboKey + Z: Undo';
  }

  @override
  String keyboardRedo(String comboKey) {
    return '- $comboKey + Y: Redo';
  }

  @override
  String get searching => 'Searching...';

  @override
  String get noResults => 'No results found';

  @override
  String get nextResult => 'Next Result';

  @override
  String get previousResult => 'Previous Result';

  @override
  String resultsCount(int count) {
    return '$count results';
  }

  @override
  String resultPosition(int current, int total) {
    return '$current di $total';
  }

  @override
  String get numericValueNodeName => 'Numeric Value';

  @override
  String get booleanValueNodeName => 'Boolean Value';

  @override
  String get stringValueNodeName => 'String Value';

  @override
  String get numericListValueNodeName => 'Numeric List Value';

  @override
  String get booleanListValueNodeName => 'Boolean List Value';

  @override
  String get stringListValueNodeName => 'String List Value';

  @override
  String valueNodeDescription(String type) {
    return 'Holds a constant $type value.';
  }

  @override
  String get completedPortName => 'Completed';

  @override
  String get valuePortName => 'Value';

  @override
  String get valueFieldName => 'Value';

  @override
  String get operatorNodeName => 'Operator';

  @override
  String get operatorNodeDescription =>
      'Applies a chosen operation to two numbers.';

  @override
  String get execPortName => 'Exec';

  @override
  String get resultPortName => 'Result';

  @override
  String get operationPortName => 'Operation';

  @override
  String get addFieldOption => 'Add';

  @override
  String get subtractFieldOption => 'Subtract';

  @override
  String get multiplyFieldOption => 'Multiply';

  @override
  String get divideFieldOption => 'Divide';

  @override
  String get randomNodeName => 'Random';

  @override
  String get randomNodeDescription =>
      'Outputs a random number between 0 and 1.';

  @override
  String get ifNodeName => 'If';

  @override
  String get ifNodeDescription => 'Executes a branch based on a condition.';

  @override
  String get conditionPortName => 'Condition';

  @override
  String get truePortName => 'True';

  @override
  String get falsePortName => 'False';

  @override
  String get comparatorNodeName => 'Comparator';

  @override
  String get comparatorNodeDescription =>
      'Compares two numbers based on a chosen comparator.';

  @override
  String get comparatorPortName => 'Comparator';

  @override
  String get equalFieldOption => '==';

  @override
  String get notEqualFieldOption => '!=';

  @override
  String get greaterFieldOption => '>';

  @override
  String get greaterEqualFieldOption => '>=';

  @override
  String get lessFieldOption => '<';

  @override
  String get lessEqualFieldOption => '<=';

  @override
  String get printNodeName => 'Print';

  @override
  String get printNodeDescription => 'Prints a value to the console.';

  @override
  String printNodeSnackbarMessage(String value) {
    return 'Value: $value';
  }

  @override
  String get roundNodeName => 'Round';

  @override
  String get roundNodeDescription =>
      'Rounds a number to a specified number of decimals.';

  @override
  String get roundedPortName => 'Rounded';

  @override
  String get decimalsFieldName => 'Decimals';

  @override
  String get forEachLoopNodeName => 'For Each Loop';

  @override
  String get forEachLoopNodeDescription =>
      'Executes a loop for each element in a list executing an operation.';

  @override
  String get listPortName => 'List';

  @override
  String get loopBodyPortName => 'Loop Body';

  @override
  String get listElementPortName => 'List Element';

  @override
  String get listIndexPortName => 'List Index';
}
