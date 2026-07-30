package com.singhtarun.stuvio

import android.content.Intent
import android.net.Uri
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.singhtarun.stuvio/open_file"

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openFile") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    try {
                        val file = File(filePath)
                        if (file.exists()) {
                            val uri: Uri = FileProvider.getUriForFile(
                                this,
                                "${applicationContext.packageName}.fileprovider",
                                file
                            )

                            // Detect MIME type from extension, fallback to application/pdf
                            val extension = MimeTypeMap.getFileExtensionFromUrl(filePath)
                            val mimeType = if (extension != null) {
                                MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.lowercase())
                                    ?: "application/pdf"
                            } else {
                                "application/pdf"
                            }

                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, mimeType)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }

                            // Try to start the activity directly; catch ActivityNotFoundException
                            try {
                                startActivity(intent)
                                result.success(true)
                            } catch (e: android.content.ActivityNotFoundException) {
                                // Fallback: try with generic binary type
                                try {
                                    val fallbackIntent = Intent(Intent.ACTION_VIEW).apply {
                                        setDataAndType(uri, "*/*")
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    startActivity(fallbackIntent)
                                    result.success(true)
                                } catch (e2: android.content.ActivityNotFoundException) {
                                    result.error("NO_APP", "No application found to open this file type", null)
                                }
                            }
                        } else {
                            result.error("FILE_NOT_FOUND", "File does not exist at path: $filePath", null)
                        }
                    } catch (e: Exception) {
                        result.error("OPEN_ERROR", e.localizedMessage, null)
                    }
                } else {
                    result.error("INVALID_PATH", "Path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
