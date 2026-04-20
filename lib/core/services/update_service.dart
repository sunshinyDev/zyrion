import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final int currentBuild;
  final int latestBuild;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final bool forceUpdate;
  final String changelog;
  final bool hasUpdate;

  const UpdateInfo({
    required this.currentBuild,
    required this.latestBuild,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.forceUpdate,
    this.changelog = '',
    required this.hasUpdate,
  });
}

class UpdateService {
  static const _path = 'app_config/update';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;
      final currentVersion = info.version;

      final snap = await FirebaseDatabase.instance.ref(_path).get();
      if (!snap.exists || snap.value == null) return null;

      final data = Map<String, dynamic>.from(snap.value as Map);
      final latestBuild = (data['version_code'] as num?)?.toInt() ?? 0;
      final latestVersion = data['version_name']?.toString() ?? '';
      final downloadUrl = data['download_url']?.toString() ?? '';

      if (latestBuild == 0 || downloadUrl.isEmpty) return null;

      return UpdateInfo(
        currentBuild: currentBuild,
        latestBuild: latestBuild,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        forceUpdate: data['force_update'] == true,
        changelog: data['changelog']?.toString() ?? '',
        hasUpdate: latestBuild > currentBuild,
      );
    } catch (e) {
      debugPrint('[Update] Check failed: $e');
      return null;
    }
  }

  static Future<String?> downloadApk(
    String url, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final path = '${dir.path}/zyrion_update.apk';

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
      ));

      await dio.download(
        url,
        path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      return path;
    } catch (e) {
      debugPrint('[Update] Download failed: $e');
      return null;
    }
  }
}
