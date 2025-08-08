enum FlCallbackType {
  success,
  error,
  warning,
  info,
}

typedef FlCallback = void Function(FlCallbackType type, String message);
