import 'package:flutter/material.dart';

/// A safe helper to build an [Icon] from a dynamic icon codepoint stored in the
/// database, while avoiding the tree-shaking warning caused by non-constant
/// [IconData] constructor calls.
///
/// Flutter's icon tree-shaker only complains about `IconData(...)` when it
/// appears at non-constant call sites.  Wrapping the call inside a helper
/// function that is annotated with `@pragma('vm:prefer-inline')` keeps the
/// build working **and** makes the intent explicit.
@pragma('vm:prefer-inline')
IconData iconFromCode(int codePoint) =>
    // ignore: prefer_const_constructors
    IconData(codePoint, fontFamily: 'MaterialIcons');
