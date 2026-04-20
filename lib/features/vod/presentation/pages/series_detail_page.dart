import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/profile.dart';
import '../../../../core/providers/iptv_provider.dart';
import '../../../../core/providers/profile_provider.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../../core/services/xtream_service.dart';
import '../../../../core/theme/app_theme.dart';

// ── TMDB provider for series ──────────────────────────────────────────────────
final _tmdbSeriesProvider =
    FutureProvider.family<TmdbMedia?, String>((ref, title) async {
  return TmdbService.search(title, type: 'tv');
});

class SeriesDetailPage extends ConsumerStatefulWidget {
  final int seriesId;
  final Map<String, dynamic>? extra;

  const SeriesDetailPage({
    super.key,
    required this.seriesId,
    this.extra,
  });

  @override
  ConsumerState<SeriesDetailPage> createState() =>
      _SeriesDetailPageState();
}

class _SeriesDetailPageState
    extends ConsumerState<SeriesDetailPage> {
  String _selectedSeason = '1';

  @override
  Widget build(BuildContext context) {
    final title =
        widget.extra?['title']?.toString() ?? 'Série';
    final cover = widget.extra?['cover'] as String?;
    final plotFromIptv =
        widget.extra?['plot'] as String?;
    final genre = widget.extra?['genre'] as String?;
    final ratingFromIptv =
        (widget.extra?['rating'] as num?)?.toDouble() ?? 0;

    final episodesAsync =
        ref.watch(seriesEpisodesProvider(widget.seriesId));
    final tmdbAsync = ref.watch(_tmdbSeriesProvider(title));
    final svc = ref.read(xtreamServiceProvider);
    final profile = ref.read(activeProfileProvider);

    // Use TMDB data if available, fallback to IPTV data
    final tmdb = tmdbAsync.valueOrNull;
    final displayCover =
        tmdb?.backdropUrl ?? tmdb?.posterUrl ?? cover;
    final displayPlot =
        (tmdb?.overview?.isNotEmpty == true)
            ? tmdb!.overview!
            : plotFromIptv;
    final displayRating =
        tmdb?.voteAverage ?? ratingFromIptv;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (displayCover != null &&
                      displayCover.isNotEmpty)
                    CachedNetworkImage(
                        imageUrl: displayCover,
                        fit: BoxFit.cover)
                  else
                    Container(color: AppColors.card),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.background
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                  // TMDB badge
                  if (tmdb != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF01B4E4),
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TMDB',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (displayRating > 0) ...[
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFB300),
                            size: 16),
                        const SizedBox(width: 4),
                        Text(
                          displayRating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (genre != null &&
                          genre.isNotEmpty)
                        Expanded(
                          child: Text(genre,
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13),
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                  if (displayPlot != null &&
                      displayPlot.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(displayPlot,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5)),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          episodesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.textMuted, size: 48),
                    const SizedBox(height: 12),
                    Text('Erro: $e',
                        style: const TextStyle(
                            color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.invalidate(
                          seriesEpisodesProvider(
                              widget.seriesId)),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
            data: (seasons) {
              if (seasons.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                        'Nenhum episódio disponível.',
                        style: TextStyle(
                            color: AppColors.textMuted)),
                  ),
                );
              }

              final seasonKeys = seasons.keys.toList()
                ..sort((a, b) =>
                    (int.tryParse(a) ?? 0)
                        .compareTo(int.tryParse(b) ?? 0));

              if (!seasonKeys.contains(_selectedSeason)) {
                _selectedSeason = seasonKeys.first;
              }

              final episodes =
                  seasons[_selectedSeason] ?? [];

              return SliverList(
                delegate: SliverChildListDelegate([
                  if (seasonKeys.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16),
                      child: SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: seasonKeys.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final s = seasonKeys[i];
                            final sel =
                                s == _selectedSeason;
                            return GestureDetector(
                              onTap: () => setState(
                                  () => _selectedSeason = s),
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: sel
                                      ? AppColors
                                          .primaryGradient
                                      : null,
                                  color: sel
                                      ? null
                                      : AppColors
                                          .surfaceVariant,
                                  borderRadius:
                                      BorderRadius.circular(
                                          16),
                                ),
                                child: Text(
                                  'Temporada $s',
                                  style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: sel
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ...episodes.map((ep) => ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${ep.episode}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight:
                                      FontWeight.w700),
                            ),
                          ),
                        ),
                        title: Text(
                          ep.title,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                              Icons.play_circle_rounded,
                              color: AppColors.primary,
                              size: 32),
                          onPressed: () {
                            if (svc == null) return;
                            final url = svc.seriesUrl(
                                ep.id, ep.containerExtension);
                            // Save to history
                            _saveHistory(ref, profile,
                                ep.title, url,
                                ep.containerExtension);
                            context.push('/player', extra: {
                              'title': ep.title,
                              'url': url,
                              'isLive': false,
                            });
                          },
                        ),
                      )),
                  const SizedBox(height: 40),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  void _saveHistory(WidgetRef ref, AppProfile? profile,
      String epTitle, String url, String ext) {
    if (profile == null) return;
    final svc = ref.read(profileServiceProvider);
    if (svc == null) return;
    final seriesTitle =
        widget.extra?['title']?.toString() ?? 'Série';
    final item = WatchItem(
      id: 'series_${widget.seriesId}',
      title: '$seriesTitle — $epTitle',
      type: 'series',
      icon: widget.extra?['cover'] as String?,
      url: url,
      ext: ext,
      watchedAt: DateTime.now(),
    );
    svc.addToHistory(profile.id, item);
  }
}
