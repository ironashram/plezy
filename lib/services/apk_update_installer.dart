import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads a release APK and hands it to the system package installer.
///
/// The installer always asks the user to confirm, and on API 26+ the app also
/// needs the per-source "install unknown apps" grant, so this never installs
/// silently.
class ApkUpdateInstaller {
  static const _channel = MethodChannel('com.plezy/apk_installer');

  /// Streams [url] into the cache directory the FileProvider serves, then opens
  /// the installer. [onProgress] reports 0..1, or null while the length is
  /// unknown.
  static Future<void> downloadAndInstall(String url, {void Function(double? progress)? onProgress}) async {
    final uri = Uri.parse(url);
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', uri));
      if (response.statusCode != 200) {
        throw HttpException('Update download failed with ${response.statusCode}', uri: uri);
      }

      final file = File('${(await getTemporaryDirectory()).path}/plezy-update.apk');
      final sink = file.openWrite();
      final total = response.contentLength;
      var received = 0;
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(total == null || total == 0 ? null : received / total);
        }
      } finally {
        await sink.close();
      }

      await _channel.invokeMethod<bool>('install', {'filePath': file.path});
    } finally {
      client.close();
    }
  }
}
