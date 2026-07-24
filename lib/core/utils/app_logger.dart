import 'package:flutter/foundation.dart';

/// AppLogger provides formatted, noticeable console logging for StudyVault.
class AppLogger {
  AppLogger._();

  /// Log Database Operations (Isar queries, mutations, etc.)
  static void db(String operation, [String? details]) {
    debugPrint('==================================================');
    debugPrint('📦 [STUDYVAULT DB] 👉 $operation');
    if (details != null && details.isNotEmpty) {
      debugPrint('   ↳ Details: $details');
    }
    debugPrint('==================================================');
  }

  /// Log Click Events & User Interactions
  static void click(String targetName, [String? actionDetails]) {
    debugPrint('--------------------------------------------------');
    debugPrint('🎯 [USER ACTION CLICK] 👆 Target: $targetName');
    if (actionDetails != null && actionDetails.isNotEmpty) {
      debugPrint('   ↳ Task: $actionDetails');
    }
    debugPrint('--------------------------------------------------');
  }

  /// Log High Level Tasks / System Actions
  static void action(String tag, String message) {
    debugPrint('⚡ [ACTION: $tag] $message');
  }

  /// Log Navigation & Flow events
  static void nav(String from, String to) {
    debugPrint('🚀 [NAVIGATING] 🧭 $from ➔ $to');
  }

  /// Log General Information
  static void info(String tag, String message) {
    debugPrint('💡 [$tag] $message');
  }

  /// Log Errors
  static void error(String tag, Object error, [StackTrace? stackTrace]) {
    debugPrint('❌ [$tag ERROR] $error');
    if (stackTrace != null) {
      debugPrint('$stackTrace');
    }
  }
}
