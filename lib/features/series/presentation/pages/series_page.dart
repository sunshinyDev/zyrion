import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/iptv_provider.dart';
import '../../../../core/providers/profile_provider.dart';
import '../../../../core/services/xtream_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/async_value_ext.dart';

class SeriesPage extends ConsumerStatefulWidget {
  const SeriesPage({super.key});

  @override
  ConsumerState<SeriesPage> createState() => _SeriesPageState();
}

class _SeriesPageState extends ConsumerState<SeriesPage> {
  XtreamCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _selectedCategory == null
            ? const Text('Séries')
            : Text(_clean(_selectedCategory!.name)),
        leading: _selectedCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    setState(() => _selectedCategory = null),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: _selectedCategory == null
          ? _CategoriesView(
              onSelect: (cat) =>
                  setState(() => _selectedCategory = cat),
            )
          : _SeriesGrid(category: _selectedCategory!),
    );
  }

  String _clean(String name) => name
      .replaceAll(RegExp(r'[♦️⭐✔️⚽️⚔]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

// ── Categories view with recent history on top ────────────────────────────────
class _CategoriesView extends ConsumerWidget {
  final ValueChanged<XtreamCategory> onSelect;
  const _CategoriesView({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(seriesCategoriesProvider);
    final historyAsync = ref.watch(watchHistoryProvider('series'));
    final recentItems = historyAsync.valueOrNull ?? [];

    return categoriesAsync.whenReady(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('Erro ao carregar categorias\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(seriesCategoriesProvider),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (cats) => CustomScrollView(
        slivers: [
          // ── Recently watched series ──────────────────────────
          if (recentItems.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Text(
                  'Continuar assistindo',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: recentItems.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final item = recentItems[i];
                    return GestureDetector(
                      onTap: () => context.push('/player', extra: {
                        'title': item.title,
                        'url': item.url,
                        'isLive': false,
                      }),
                      child: SizedBox(
                        width: 90,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(8),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    item.icon != null &&
                                            item.icon!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: item.icon!,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __,
                                                    ___) =>
                                                Container(
                                                    color: AppColors
                                                        .card),
                                          )
                                        : Container(
                                            color: AppColors.card,
                                            child: const Icon(
                                                Icons.tv_rounded,
                                                color: AppColors
                                                    .textMuted,
                                                size: 24)),
                                    // Play overlay
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 28,
                                        decoration:
                                            const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Colors.black54
                                            ],
                                            begin:
                                                Alignment.topCenter,
                                            end: Alignment
                                                .bottomCenter,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons
                                                .play_circle_outline_rounded,
                                            color: Colors.white70,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.title,
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatDate(item.watchedAt),
                              style: const TextStyle(
                                  color: AppColors.textDisabled,
                                  fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  'Categorias',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],

          // ── Categories grid ──────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _CategoryCard(
                  category: cats[i],
                  onTap: () => onSelect(cats[i]),
                ),
                childCount: cats.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }
}

class _CategoryCard extends StatelessWidget {
  final XtreamCategory category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

  String get _clean => category.name
      .replaceAll(RegExp(r'[♦️⭐✔️⚽️⚔]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tv_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _clean,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Series grid for a specific category ──────────────────────────────────────
class _SeriesGrid extends ConsumerWidget {
  final XtreamCategory category;
  const _SeriesGrid({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesListProvider(category.id));

    return seriesAsync.whenReady(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('Erro ao carregar\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.invalidate(seriesListProvider(category.id)),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (series) {
        if (series.isEmpty) {
          return const Center(
            child: Text('Nenhuma série nesta categoria.',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.58,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
          ),
          itemCount: series.length,
          itemBuilder: (context, i) =>
              _SeriesCard(series: series[i]),
        );
      },
    );
  }
}

// ── Series card ───────────────────────────────────────────────────────────────
class _SeriesCard extends StatelessWidget {
  final XtreamSeries series;
  const _SeriesCard({required this.series});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push('/series-detail/${series.seriesId}', extra: {
        'title': series.name,
        'cover': series.cover,
        'plot': series.plot,
        'genre': series.genre,
        'rating': series.rating,
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  series.cover != null && series.cover!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: series.cover!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _Placeholder(series.name),
                        )
                      : _Placeholder(series.name),
                  if (series.rating > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFB300), size: 10),
                            const SizedBox(width: 2),
                            Text(
                              series.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            series.name,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String name;
  const _Placeholder(this.name);

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
