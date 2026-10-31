package com.fileorganizer.file_organizer

import android.content.Intent
import android.net.Uri
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.fileorganizer/app_chooser"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openWithChooser") {
                val filePath = call.argument<String>("filePath")
                val customMimeType = call.argument<String>("mimeType")
                val chooserTitle = call.argument<String>("title") ?: "Open file with"

                if (filePath == null) {
                    result.error("INVALID_PATH", "File path cannot be null", null)
                    return@setMethodCallHandler
                }

                val file = File(filePath)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
                    return@setMethodCallHandler
                }

                try {
                    val uri: Uri = FileProvider.getUriForFile(
                        context,
                        "${context.packageName}.fileprovider",
                        file
                    )

                    val extension = file.extension.lowercase()
                    var mimeType = customMimeType

                    // Enforce accurate MIME type determination for PDF and media files
                    if (extension == "pdf" || file.name.lowercase().endsWith(".pdf")) {
                        mimeType = "application/pdf"
                    } else if (mimeType.isNullOrEmpty() || mimeType == "*/*" || mimeType == "application/octet-stream" || !mimeType.contains("/") || mimeType == "file") {
                        if (extension.isNotEmpty()) {
                            val mapType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
                            if (!mapType.isNullOrEmpty()) {
                                mimeType = mapType
                            }
                        }
                    }

                    if (mimeType.isNullOrEmpty() || !mimeType.contains("/")) {
                        mimeType = "*/*"
                    }

                    val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, mimeType)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }

                    val chooser = Intent.createChooser(viewIntent, chooserTitle).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }

                    startActivity(chooser)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.localizedMessage ?: "Failed to open chooser", null)
                }
            } else if (call.method == "shareFileWithChooser") {
                val filePath = call.argument<String>("filePath")
                val chooserTitle = call.argument<String>("title") ?: "Save to Google Drive / Share"
                val customMimeType = call.argument<String>("mimeType") ?: "application/zip"

                if (filePath == null) {
                    result.error("INVALID_PATH", "File path cannot be null", null)
                    return@setMethodCallHandler
                }

                val file = File(filePath)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
                    return@setMethodCallHandler
                }

                try {
                    val uri: Uri = FileProvider.getUriForFile(
                        context,
                        "${context.packageName}.fileprovider",
                        file
                    )

                    val shareIntent = Intent(Intent.ACTION_SEND).apply {
                        type = customMimeType
                        putExtra(Intent.EXTRA_STREAM, uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }

                    val chooser = Intent.createChooser(shareIntent, chooserTitle).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }

                    startActivity(chooser)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.localizedMessage ?: "Failed to open share chooser", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
