import 'package:flutter/foundation.dart';

/// Build-time configuration. No secrets belong here: private AI credentials
/// live only on the server.
class AppConfig {
  const AppConfig._();

  /// Draft (unreviewed) exercise and nutrition content is shown only in
  /// debug/profile builds, or when explicitly enabled with
  /// --dart-define=ALLOW_DRAFT_CONTENT=true. Release builds hide it.
  static const bool allowDraftContent = bool.fromEnvironment(
    'ALLOW_DRAFT_CONTENT',
    defaultValue: !kReleaseMode,
  );

  /// Public base URL of the AI explanation backend (Phase 5). Empty = unset.
  static const String aiBackendUrl = String.fromEnvironment('AI_BACKEND_URL');
}
