import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class IptvUserInfo {
  final String status;       // "Active" | "Expired" | "Banned"
  final DateTime? expDate;
  final bool isTrial;
  final int maxConnections;

  const IptvUserInfo({
    required this.status,
    this.expDate,
    this.isTrial = false,
    this.maxConnections = 1,
  });

  bool get isActive => status == 'Active';
  bool get isExpired => expDate != null && DateTime.now().isAfter(expDate!);

  /// Days remaining until expiration (negative = already expired)
  int get daysRemaining {
    if (expDate == null) return 9999;
    return expDate!.difference(DateTime.now()).inDays;
  }

  /// Hours remaining (used when < 2 days left)
  int get hoursRemaining {
    if (expDate == null) return 9999;
    return expDate!.difference(DateTime.now()).inHours;
  }

  bool get expiresWithin7Days =>
      daysRemaining >= 0 && daysRemaining <= 7;
  bool get expiresWithin2Days =>
      daysRemaining >= 0 && daysRemaining <= 2;

  factory IptvUserInfo.fromJson(Map<String, dynamic> j) {
    DateTime? exp;
    final raw = j['exp_date'];
    if (raw != null && raw.toString().isNotEmpty) {
      final ts = int.tryParse(raw.toString());
      if (ts != null && ts > 0) {
        exp = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      }
    }
    return IptvUserInfo(
      status: j['status']?.toString() ?? 'Unknown',
      expDate: exp,
      isTrial: j['is_trial']?.toString() == '1',
      maxConnections:
          int.tryParse(j['max_connections']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'exp_date': expDate?.millisecondsSinceEpoch != null
            ? (expDate!.millisecondsSinceEpoch ~/ 1000).toString()
            : null,
        'is_trial': isTrial ? '1' : '0',
        'max_connections': maxConnections.toString(),
      };
}

class IptvProvider {
  final String workingHost;
  final String username;
  final String password;
  final String providerCode;
  final IptvUserInfo? userInfo;

  const IptvProvider({
    required this.workingHost,
    required this.username,
    required this.password,
    required this.providerCode,
    this.userInfo,
  });

  IptvProvider copyWith({IptvUserInfo? userInfo}) => IptvProvider(
        workingHost: workingHost,
        username: username,
        password: password,
        providerCode: providerCode,
        userInfo: userInfo ?? this.userInfo,
      );

  String get baseUrl => workingHost;

  String liveStreamUrl(String streamId) =>
      '$workingHost/live/$username/$password/$streamId.ts';

  String vodStreamUrl(String streamId, String ext) =>
      '$workingHost/movie/$username/$password/$streamId.$ext';

  String seriesStreamUrl(String streamId, String ext) =>
      '$workingHost/series/$username/$password/$streamId.$ext';

  // ── Secure storage ────────────────────────────────────────────────
  static const _key = 'iptv_provider_v3';
  static const _storage = FlutterSecureStorage();

  Future<void> save() async {
    await _storage.write(
      key: _key,
      value: jsonEncode({
        'workingHost': workingHost,
        'username': username,
        'password': password,
        'providerCode': providerCode,
        'userInfo': userInfo?.toJson(),
      }),
    );
  }

  static Future<IptvProvider?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      IptvUserInfo? info;
      if (m['userInfo'] != null) {
        info = IptvUserInfo.fromJson(
            m['userInfo'] as Map<String, dynamic>);
      }
      return IptvProvider(
        workingHost: m['workingHost'] ?? '',
        username: m['username'] ?? '',
        password: m['password'] ?? '',
        providerCode: m['providerCode'] ?? '',
        userInfo: info,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: 'iptv_provider_v2');
    await _storage.delete(key: 'iptv_provider');
  }
}
