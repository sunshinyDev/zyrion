import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/iptv_provider.dart';
import '../../../../core/services/xtream_service.dart';
import '../../../../core/theme/app_theme.dart';

class VodPage extends ConsumerStatefulWidget {
  const VodPage({super.key});

  @override
  ConsumerState<VodPage> createState() => _VodPageState();
}

class _VodPageState extends ConsumerState<VodPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _movieCategoryId;
  String? _seriesCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('VOD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Filmes'),
            Tab(text: 'Séries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ContentTab(
            categoriesAsync: ref.watch(vodCategoriesProvider),
            streamsAsync: ref.watch(vodStreamsProvider(_movieCategoryId)),
            selectedCategoryId: _movieCategoryId,
            onCategoryChanged: (id) =>
                setState(() => _movieCategoryId = id),
            onTap: (stream) => _openVod(context, ref, stream),
          ),
          _SeriesTab(
            categoriesAsync: ref.watch(seriesCategoriesProvider),
            seriesAsync:
                ref.watch(seriesListProvider(_seriesCategoryId)),
            selectedCategoryId: _seriesCategoryId,
            onCategoryChanged: (id) =>
                setState(() => _seriesCategoryId = id),
          ),
        ],
      ),
    );
  }

  void _openVod(
      BuildContext context, WidgetRef ref, XtreamStream stream) {
    final svc = ref.read(xtreamServiceProvider);
    if (svc == null) return;
    final ext = stream.containerExtension ?? 'ts';
    context.push('/player', extra: {
      'title': stream.name,
      'url': svc.vodUrl(stream.streamId, ext),
      'isLive': false,
    });
  }
}

// ── Movies tab ────────────────────────────────────────────────────────────────
class _ContentTab extends StatelessWidget {
  final AsyncValue<List<XtreamCategory>> categoriesAsync;
  final AsyncValue<List<XtreamStream>> streamsAsync;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<XtreamStream> onTap;

  const _ContentTab({
    required this.categoriesAsync,
    required this.streamsAsync,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _CategoryBar(
          categoriesAsync: categoriesAsync,
          selectedId: selectedCategoryId,
          onChanged: onCategoryChanged,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: streamsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(message: e.toString()),
            data: (streams) {
              if (streams.isEmpty) {
                return const Center(
                  child: Text('Nenhum filme encontrado.',
                      style: TextStyle(color: AppColors.textMuted)),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                ),
                itemCount: streams.length,
                itemBuilder: (context, i) => _VodCard(
                  stream: streams[i],
                  onTap: () => onTap(streams[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Series tab ────────────────────────────────────────────────────────────────
class _SeriesTab extends ConsumerWidget {
  final AsyncValue<List<XtreamCategory>> categoriesAsync;
  final AsyncValue<List<XtreamSeries>> seriesAsync;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;

  const _SeriesTab({
    required this.categoriesAsync,
    required this.seriesAsync,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _CategoryBar(
          categoriesAsync: categoriesAsync,
          selectedId: selectedCategoryId,
          onChanged: onCategoryChanged,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: seriesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(message: e.toString()),
            data: (series) {
              if (series.isEmpty) {
                return const Center(
                  child: Text('Nenhuma série encontrada.',
                      style: TextStyle(color: AppColors.textMuted)),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                ),
                itemCount: series.length,
                itemBuilder: (context, i) => _SeriesCard(
                  series: series[i],
                  onTap: () => _openSeries(context, ref, series[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openSeries(
      BuildContext context, WidgetRef ref, XtreamSeries s) {
    context.push('/series-detail/${s.seriesId}', extra: {
      'title': s.name,
      'cover': s.cover,
      'plot': s.plot,
      'genre': s.genre,
      'rating': s.rating,
    });
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────
class _CategoryBar extends StatelessWidget {
  final AsyncValue<List<XtreamCategory>> categoriesAsync;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _CategoryBar({
    required this.categoriesAsync,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return categoriesAsync.when(
      loading: () => const SizedBox(height: 36),
      error: (_, __) => const SizedBox.shrink(),
      data: (cats) => SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: cats.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final isAll = i == 0;
            final cat = isAll ? null : cats[i - 1];
            final selected =
                isAll ? selectedId == null : selectedId == cat!.id;
            return GestureDetector(
              onTap: () => onChanged(isAll ? null : cat!.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient:
                      selected ? AppColors.primaryGradient : null,
                  color: selected ? null : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isAll
                      ? 'Todos'
                      : _clean(cat!.name),
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _clean(String name) => name
      .replaceAll(RegExp(r'[♦️⭐✔️⚽️⚔]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _VodCard extends StatelessWidget {
  final XtreamStream stream;
  final VoidCallback onTap;

  const _VodCard({required this.stream, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  stream.icon != null && stream.icon!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: stream.icon!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _Placeholder(stream.name),
                        )
                      : _Placeholder(stream.name),
                  if (stream.rating > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFB300), size: 10),
                            const SizedBox(width: 2),
                            Text(
                              stream.rating.toStringAsFixed(1),
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
            stream.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  final XtreamSeries series;
  final VoidCallback onTap;

  const _SeriesCard({required this.series, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: series.cover != null && series.cover!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: series.cover!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _Placeholder(series.name),
                    )
                  : _Placeholder(series.name),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            series.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
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
          padding: const EdgeInsets.all(8),
          child: Text(
            name,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('Erro ao carregar\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
