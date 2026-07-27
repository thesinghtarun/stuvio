import 'package:flutter/foundation.dart';

/// A global refresh tick. Increment this after any note/assignment is saved
/// so that HomeProvider and SearchProvider reload automatically.
///
/// Usage:
///   appRefreshTick.value++;
final ValueNotifier<int> appRefreshTick = ValueNotifier<int>(0);
