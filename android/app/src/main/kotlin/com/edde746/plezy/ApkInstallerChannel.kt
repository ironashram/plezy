package com.edde746.plezy

import android.app.Activity
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

internal class ApkInstallerChannel(private val activity: Activity) {
  companion object {
    private const val CHANNEL = "com.plezy/apk_installer"
    private const val APK_MIME = "application/vnd.android.package-archive"
  }

  fun attach(messenger: BinaryMessenger) {
    MethodChannel(messenger, CHANNEL).setMethodCallHandler(::onMethodCall)
  }

  private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    if (call.method != "install") {
      result.notImplemented()
      return
    }

    val filePath = call.argument<String>("filePath")
    if (filePath == null) {
      result.error("INVALID_ARGUMENT", "filePath is required", null)
      return
    }

    val file = File(filePath)
    if (!file.isFile) {
      result.error("NOT_FOUND", "No package at $filePath", null)
      return
    }

    try {
      // A file:// URI trips FileUriExposedException on API 24+, so the installer is handed a
      // content:// URI with a read grant instead.
      val uri = FileProvider.getUriForFile(activity, "${BuildConfig.APPLICATION_ID}.fileprovider", file)
      activity.startActivity(
        Intent(Intent.ACTION_VIEW).apply {
          setDataAndType(uri, APK_MIME)
          addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
          addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
      )
      result.success(true)
    } catch (error: Exception) {
      result.error("LAUNCH_FAILED", error.message ?: error.javaClass.simpleName, null)
    }
  }
}
