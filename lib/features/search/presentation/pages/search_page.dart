import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/iptv_provider.dart';
import '../../../../core/services/xtream_service.dart';
import '../../../../core/theme/app_theme.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Buscar canais, filmes, séries...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: AppColors.textMuted),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
      ),
      body: _query.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_rounded,
                      color: AppColors.textMuted, size: 64),
                  SizedBox(height: 12),
                  Text('Digite para buscar',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 15)),
                ],
              ),
            )
          : _SearchResults(query: _query),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;
  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(liveStreamsProvider(null));
    final vodAsync = ref.watch(vodStreamsProvider(null));
    final seriesAsync = ref.watch(seriesListProvider(null));
    final svc = ref.read(xtreamServiceProvider);

    final q = query.toLowerCase();

    // Combine results
    final liveResults = liveAsync.valueOrNull
            ?.where((s) => s.name.toLowerCase().contains(q))
            .toList() ??
        [];
    final vodResults = vodAsync.valueOrNull
            ?.where((s) => s.name.toLowerCase().contains(q))
            .toList() ??
        [];
    final seriesResults = seriesAsync.valueOrNull
            ?.where((s) => s.name.toLowerCase().contains(q))
            .toList() ??
        [];

    final isLoading = liveAsync.isLoading ||
        vodAsync.isLoading ||
        seriesAsync.isLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (liveResults.isEmpty && vodResults.isEmpty && seriesResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('Nenhum resultado para "$query"',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (liveResults.isNotEmpty) ...[
          _ResultHeader('TV ao Vivo (${liveResults.length})'),
          ...liveResults.take(10).map((s) => _StreamTile(
                name: s.name,
                icon: s.icon,
                subtitle: 'Ao Vivo',
                onTap: () {
                  if (svc == null) return;
                  context.push('/player', extra: {
                    'title': s.name,
                    'url': svc.liveUrl(s.streamId),
                    'isLive': true,
                  });
                },
              )),
        ],
        if (vodResults.isNotEmpty) ...[
          _ResultHeader('Filmes (${vodResults.length})'),
          ...vodResults.take(10).map((s) => _StreamTile(
                name: s.name,
                icon: s.icon,
                subtitle: s.rating > 0
                    ? '⭐ ${s.rating.toStringAsFixed(1)}'
                    : 'Filme',
                onTap: () {
                  if (svc == null) return;
                  final ext = s.containerExtension ?? 'ts';
                  context.push('/player', extra: {
                    'title': s.name,
                    'url': svc.vodUrl(s.streamId, ext),
                    'isLive': false,
                  });
                },
              )),
        ],
        if (seriesResults.isNotEmpty) ...[
          _ResultHeader('Séries (${seriesResults.length})'),
          ...seriesResults.take(10).map((s) => _StreamTile(
                name: s.name,
                icon: s.cover,
                subtitle: s.genre ?? 'Série',
                onTap: () => context.push('/series-detail/${s.seriesId}', extra: {
                  'title': s.name,
                  'cover': s.cover,
                  'plot': s.plot,
                  'genre': s.genre,
                  'rating': s.rating,
                }),
              )),
        ],
      ],
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final String title;
  const _ResultHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StreamTile extends StatelessWidget {
  final String name;
  final String? icon;
  final String subtitle;
  final VoidCallback onTap;

  const _StreamTile({
    required this.name,
    required this.icon,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: icon != null && icon!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: icon!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _IconPlaceholder(),
              )
            : _IconPlaceholder(),
      ),
      title: Text(name,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 12)),
      trailing: const Icon(Icons.play_circle_outline_rounded,
          color: AppColors.primary),
      onTap: onTap,
    );
  }
}

class _IconPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.card,
      child: const Icon(Icons.movie_rounded,
          color: AppColors.textMuted, size: 20),
    );
  }
}
