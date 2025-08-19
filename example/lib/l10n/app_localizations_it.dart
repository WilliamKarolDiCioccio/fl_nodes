// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Esempio Editor Nodi';

  @override
  String get saveProjectDialogTitle => 'Salva Progetto';

  @override
  String get unsavedChangesTitle => 'Modifiche Non Salvate';

  @override
  String get unsavedChangesMsg =>
      'Hai modifiche non salvate. Vuoi procedere senza salvare?';

  @override
  String get cancel => 'Annulla';

  @override
  String get proceed => 'Procedi';

  @override
  String get failedToLoadSampleProject =>
      'Impossibile caricare il progetto di esempio. Controlla la tua connessione internet.';

  @override
  String get searchNodesTooltip => 'Cerca Nodi per Nome';

  @override
  String get toggleHierarchyTooltip => 'Attiva/Disattiva Pannello Gerarchia';

  @override
  String get toggleSnapToGridTooltip =>
      'Attiva/Disattiva Aggancio alla Griglia';

  @override
  String get executeGraphTooltip => 'Esegui Grafico';

  @override
  String get touchCommandsTitle => 'Comandi Touch:';

  @override
  String get touchTap => '- Tocco: Seleziona Nodo';

  @override
  String get touchDoubleTap => '- Doppio Tocco: Cancella Selezione';

  @override
  String get touchLongPress => '- Pressione Prolungata: Apri Menu Contestuale';

  @override
  String get touchDrag => '- Trascina: Inizia Collegamento / Seleziona Nodi';

  @override
  String get touchPinch => '- Pizzica: Zoom Avanti/Indietro';

  @override
  String get touchAdditionalGestures => 'Gesti Aggiuntivi:';

  @override
  String get touchTwoFingerDrag => '- Trascinamento Due Dita: Panoramica';

  @override
  String get mouseCommandsTitle => 'Comandi Mouse:';

  @override
  String get mouseLeftClick => '- Click Sinistro: Seleziona Nodo/Collegamento';

  @override
  String get mouseRightClick => '- Click Destro: Apri Menu Contestuale';

  @override
  String get mouseScroll => '- Scroll: Zoom Avanti/Indietro';

  @override
  String get mouseMiddleClick => '- Click Centrale: Panoramica';

  @override
  String get keyboardCommandsTitle => 'Comandi Tastiera:';

  @override
  String keyboardSave(String comboKey) {
    return '- $comboKey + S: Salva Progetto';
  }

  @override
  String keyboardOpen(String comboKey) {
    return '- $comboKey + O: Apri Progetto';
  }

  @override
  String keyboardNew(String comboKey) {
    return '- $comboKey + Shift + N: Nuovo Progetto';
  }

  @override
  String keyboardCopy(String comboKey) {
    return '- $comboKey + C: Copia Nodo';
  }

  @override
  String keyboardPaste(String comboKey) {
    return '- $comboKey + V: Incolla Nodo';
  }

  @override
  String keyboardCut(String comboKey) {
    return '- $comboKey + X: Taglia Nodo';
  }

  @override
  String get keyboardDelete => '- Canc | Backspace: Rimuovi Nodo';

  @override
  String keyboardUndo(String comboKey) {
    return '- $comboKey + Z: Annulla';
  }

  @override
  String keyboardRedo(String comboKey) {
    return '- $comboKey + Y: Ripeti';
  }

  @override
  String get searching => 'Ricerca in corso...';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String get nextResult => 'Risultato Successivo';

  @override
  String get previousResult => 'Risultato Precedente';

  @override
  String resultsCount(int count) {
    return '$count risultati';
  }

  @override
  String resultPosition(int current, int total) {
    return '$current di $total';
  }

  @override
  String get numericValueNodeName => 'Valore Numerico';

  @override
  String get booleanValueNodeName => 'Valore Booleano';

  @override
  String get stringValueNodeName => 'Valore Stringa';

  @override
  String get numericListValueNodeName => 'Lista Valori Numerici';

  @override
  String get booleanListValueNodeName => 'Lista Valori Booleani';

  @override
  String get stringListValueNodeName => 'Lista Valori Stringa';

  @override
  String valueNodeDescription(String type) {
    return 'Contiene un valore che può essere utilizzato in altri nodi.';
  }

  @override
  String get completedPortName => 'Completato';

  @override
  String get valuePortName => 'Valore';

  @override
  String get valueFieldName => 'Valore';

  @override
  String get operatorNodeName => 'Operatore';

  @override
  String get operatorNodeDescription =>
      'Applica un\'operazione scelta a due numeri.';

  @override
  String get execPortName => 'Esegui';

  @override
  String get resultPortName => 'Risultato';

  @override
  String get operationPortName => 'Operazione';

  @override
  String get addFieldOption => 'Somma';

  @override
  String get subtractFieldOption => 'Sottrai';

  @override
  String get multiplyFieldOption => 'Moltiplica';

  @override
  String get divideFieldOption => 'Dividi';

  @override
  String get randomNodeName => 'Casuale';

  @override
  String get randomNodeDescription =>
      'Restituisce un numero casuale tra 0 e 1.';

  @override
  String get ifNodeName => 'Se';

  @override
  String get ifNodeDescription => 'Esegue un ramo in base a una condizione.';

  @override
  String get conditionPortName => 'Condizione';

  @override
  String get truePortName => 'Vero';

  @override
  String get falsePortName => 'Falso';

  @override
  String get comparatorNodeName => 'Comparatore';

  @override
  String get comparatorNodeDescription =>
      'Confronta due numeri in base a un comparatore scelto.';

  @override
  String get comparatorPortName => 'Comparatore';

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
  String get printNodeName => 'Stampa';

  @override
  String get printNodeDescription => 'Stampa un valore nella console.';

  @override
  String printNodeSnackbarMessage(String value) {
    return 'Valore: $value';
  }

  @override
  String get roundNodeName => 'Arrotonda';

  @override
  String get roundNodeDescription =>
      'Arrotonda un numero a un numero specificato di decimali.';

  @override
  String get roundedPortName => 'Arrotondato';

  @override
  String get decimalsFieldName => 'Decimali';

  @override
  String get forEachLoopNodeName => 'Per Ogni Ciclo';

  @override
  String get forEachLoopNodeDescription =>
      'Esegue un ciclo per ogni elemento di una lista eseguendo un\'operazione.';

  @override
  String get listPortName => 'Lista';

  @override
  String get loopBodyPortName => 'Corpo del Ciclo';

  @override
  String get listElementPortName => 'Elemento Lista';

  @override
  String get listIndexPortName => 'Indice Lista';
}
