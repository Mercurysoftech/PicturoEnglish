import 'package:uuid/uuid.dart';

class CallKitSession {
  static String? _uuid;

  /// Tracks whether app is in foreground (CRITICAL FOR iOS)
  static bool isAppInForeground = true;

  static String start() {
    _uuid = const Uuid().v4();
    return _uuid!;
  }

  static String? get uuid => _uuid;

  static bool get hasActive => _uuid != null;

  static void clear() {
    _uuid = null;
  }
}
