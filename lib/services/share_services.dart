import 'package:flutter/services.dart';

class ShareService {
  static const MethodChannel _channel = MethodChannel(
    "com.singhtarun.stuvio/share",
  );

  static Future<void> shareFile(String filePath) async {
    await _channel.invokeMethod("shareFile", {"filePath": filePath});
  }
}
