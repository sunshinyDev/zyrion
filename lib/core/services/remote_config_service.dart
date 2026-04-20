import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages Firebase Remote Config for dynamic server configuration.
/// This allows updating API URLs and feature flags without a new app release.
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  /// Initialize Remote Config with defaults and fetch latest values.
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Set default values — used when offline or before first fetch
    await _remoteConfig.setDefaults({
      'api_base_url': 'https://api.streamhub.com/v1',
      'stream_base_url': 'https://stream.streamhub.com',
      'enable_sports': true,
      'enable_kids': true,
      'enable_downloads': false,
      'maintenance_mode': false,
      'maintenance_message': '',
      'max_concurrent_streams': 2,
      'featured_banner_enabled': true,
      // Update system
      'latest_version': '1.0.0',
      'apk_url': '',
      'update_required': false,
      'update_message': 'Uma nova versão está disponível com melhorias e correções.',
    });

    // Fetch and activate
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (_) {
      // Use cached/default values if fetch fails
    }
  }

  String get apiBaseUrl => _remoteConfig.getString('api_base_url');
  String get streamBaseUrl => _remoteConfig.getString('stream_base_url');
  bool get enableSports => _remoteConfig.getBool('enable_sports');
  bool get enableKids => _remoteConfig.getBool('enable_kids');
  bool get enableDownloads => _remoteConfig.getBool('enable_downloads');
  bool get maintenanceMode => _remoteConfig.getBool('maintenance_mode');
  String get maintenanceMessage =>
      _remoteConfig.getString('maintenance_message');
  int get maxConcurrentStreams =>
      _remoteConfig.getInt('max_concurrent_streams');
  bool get featuredBannerEnabled =>
      _remoteConfig.getBool('featured_banner_enabled');

  // ── Update system ─────────────────────────────────────────────
  String get latestVersion => _remoteConfig.getString('latest_version');
  String get apkUrl => _remoteConfig.getString('apk_url');
  bool get updateRequired => _remoteConfig.getBool('update_required');
  String get updateMessage => _remoteConfig.getString('update_message');
}

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});

final remoteConfigInitProvider = FutureProvider<void>((ref) async {
  final service = ref.read(remoteConfigServiceProvider);
  await service.initialize();
});
