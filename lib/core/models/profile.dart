class AppProfile {
  final String id;
  final String name;
  final String avatar; // emoji
  final DateTime createdAt;

  const AppProfile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.createdAt,
  });

  factory AppProfile.fromMap(String id, Map<dynamic, dynamic> m) =>
      AppProfile(
        id: id,
        name: m['name']?.toString() ?? 'Perfil',
        avatar: m['avatar']?.toString() ?? '👤',
        createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'avatar': avatar,
        'createdAt': createdAt.toIso8601String(),
      };
}

class WatchItem {
  final String id;
  final String title;
  final String type; // 'live' | 'movie' | 'series'
  final String? icon;
  final String url;
  final String ext;
  final DateTime watchedAt;
  final int progress; // seconds watched

  const WatchItem({
    required this.id,
    required this.title,
    required this.type,
    this.icon,
    required this.url,
    this.ext = 'ts',
    required this.watchedAt,
    this.progress = 0,
  });

  factory WatchItem.fromMap(Map<dynamic, dynamic> m) => WatchItem(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        type: m['type']?.toString() ?? 'movie',
        icon: m['icon']?.toString(),
        url: m['url']?.toString() ?? '',
        ext: m['ext']?.toString() ?? 'ts',
        watchedAt:
            DateTime.tryParse(m['watchedAt']?.toString() ?? '') ??
                DateTime.now(),
        progress: (m['progress'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'type': type,
        'icon': icon ?? '',
        'url': url,
        'ext': ext,
        'watchedAt': watchedAt.toIso8601String(),
        'progress': progress,
      };
}
