import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/iptv_provider.dart';
import '../../../../core/services/xtream_service.dart';
import '../../../../core/theme/app_theme.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(liveStreamsProvider(null));
    final moviesAsync = ref.watch(vodStreamsProvider(null));
    final seriesAsync = ref.watch(seriesListProvider(null));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            title: _AppBarTitle(),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded,
                    color: AppColors.textPrimary),
                onPressed: () => context.push('/search'),
              ),
              GestureDetector(
                onTap: () => context.go('/account'),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Live TV ──────────────────────────────────────
                _SectionTitle(
                  title: 'TV ao Vivo',
                  onSeeAll: () => context.go('/live-tv'),
                ),
                const SizedBox(height: 10),
                liveAsync.when(
                  loading: () => _HorizontalShimmer(height: 80),
                  error: (_, __) => const _ErrorRow(),
                  data: (streams) => _LiveRow(streams: streams.take(20).toList()),
                ),
                const SizedBox(height: 24),

                // ── Filmes ───────────────────────────────────────
                _SectionTitle(
                  title: 'Filmes',
                  onSeeAll: () => context.go('/vod'),
                ),
                const SizedBox(height: 10),
                moviesAsync.when(
                  loading: () => _HorizontalShimmer(height: 180),
                  error: (_, __) => const _ErrorRow(),
                  data: (streams) =>
                      _PosterRow(streams: streams.take(20).toList(), isVod: true),
                ),
                const SizedBox(height: 24),

                // ── Séries ───────────────────────────────────────
                _SectionTitle(
                  title: 'Séries',
                  onSeeAll: () => context.go('/vod'),
                ),
                const SizedBox(height: 10),
                seriesAsync.when(
                  loading: () => _HorizontalShimmer(height: 180),
                  error: (_, __) => const _ErrorRow(),
                  data: (series) =>
                      _SeriesRow(series: series.take(20).toList()),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────
class _AppBarTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF2A0A5E), Color(0xFF050510)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Center(
            child: Text('👽', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (b) => AppColors.neonGradient.createShader(b),
          child: const Text(
            'ZYRION PLAY',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionTitle({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text('Ver tudo',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ── Live row ──────────────────────────────────────────────────────────────────
class _LiveRow extends ConsumerWidget {
  final List<XtreamStream> streams;
  const _LiveRow({required this.streams});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(xtreamServiceProvider);
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: streams.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final ch = streams[i];
          return GestureDetector(
            onTap: () {
              if (svc == null) return;
              context.push('/player', extra: {
                'title': ch.name,
                'url': svc.liveUrl(ch.streamId),
                'isLive': true,
              });
            },
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.live.withOpacity(0.3)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: ch.icon != null && ch.icon!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ch.icon!,
                            width: 60,
                            height: 40,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => Text(
                              ch.name,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Text(ch.name,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 10),
                            textAlign: TextAlign.center),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.live,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Poster row (VOD) ──────────────────────────────────────────────────────────
class _PosterRow extends ConsumerWidget {
  final List<XtreamStream> streams;
  final bool isVod;
  const _PosterRow({required this.streams, required this.isVod});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(xtreamServiceProvider);
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: streams.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final s = streams[i];
          return GestureDetector(
            onTap: () {
              if (svc == null) return;
              final ext = s.containerExtension ?? 'ts';
              context.push('/player', extra: {
                'title': s.name,
                'url': svc.vodUrl(s.streamId, ext),
                'isLive': false,
              });
            },
            child: SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: s.icon != null && s.icon!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: s.icon!,
                              fit: BoxFit.cover,
                              width: 110,
                              errorWidget: (_, __, ___) =>
                                  _PlaceholderBox(s.name),
                            )
                          : _PlaceholderBox(s.name),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(s.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Series row ────────────────────────────────────────────────────────────────
class _SeriesRow extends StatelessWidget {
  final List<XtreamSeries> series;
  const _SeriesRow({required this.series});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: series.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final s = series[i];
          return GestureDetector(
            onTap: () => context.push('/series-detail/${s.seriesId}', extra: {
              'title': s.name,
              'cover': s.cover,
              'plot': s.plot,
              'genre': s.genre,
              'rating': s.rating,
            }),
            child: SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: s.cover != null && s.cover!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: s.cover!,
                              fit: BoxFit.cover,
                              width: 110,
                              errorWidget: (_, __, ___) =>
                                  _PlaceholderBox(s.name),
                            )
                          : _PlaceholderBox(s.name),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(s.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _PlaceholderBox extends StatelessWidget {
  final String name;
  const _PlaceholderBox(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(name,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class _HorizontalShimmer extends StatelessWidget {
  final double height;
  const _HorizontalShimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: height < 100 ? 100 : 110,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 60,
      child: Center(
        child: Text('Erro ao carregar',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ),
    );
  }
}
