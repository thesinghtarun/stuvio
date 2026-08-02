import 'package:flutter/services.dart';

class DragShareService {
  DragShareService._();

  static const MethodChannel _channel = MethodChannel(
    "com.singhtarun.stuvio/drag_share",
  );

  static Future<bool> startDrag({
    required String filePath,
    required String title,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>("startDrag", {
        "filePath": filePath,
        "title": title,
      });

      return result ?? false;
    } catch (e) {
      print("Drag error: $e");
      return false;
    }
  }
}
