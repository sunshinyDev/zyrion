import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/profile.dart';
import '../../../../core/providers/iptv_provider.dart';
import '../../../../core/providers/profile_provider.dart';
import '../../../../core/services/xtream_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/async_value_ext.dart';

class MoviesPage extends ConsumerStatefulWidget {
  const MoviesPage({super.key});

  @override
  ConsumerState<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends ConsumerState<MoviesPage> {
  XtreamCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _selectedCategory == null
            ? const Text('Filmes')
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
          : _MoviesGrid(category: _selectedCategory!),
    );
  }

  String _clean(String name) => name
      .replaceAll(RegExp(r'[♦️⭐✔️⚽️⚔]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

// ── Categories grid ───────────────────────────────────────────────────────────
class _CategoriesView extends ConsumerWidget {
  final ValueChanged<XtreamCategory> onSelect;
  const _CategoriesView({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(vodCategoriesProvider);

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
              onPressed: () => ref.invalidate(vodCategoriesProvider),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (cats) => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: cats.length,
        itemBuilder: (context, i) => _CategoryCard(
          category: cats[i],
          onTap: () => onSelect(cats[i]),
        ),
      ),
    );
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
              child: const Icon(Icons.movie_rounded,
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

// ── Movies grid for a specific category ──────────────────────────────────────
class _MoviesGrid extends ConsumerWidget {
  final XtreamCategory category;
  const _MoviesGrid({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamsAsync = ref.watch(vodStreamsProvider(category.id));
    final historyAsync = ref.watch(watchHistoryProvider('movie'));

    return streamsAsync.whenReady(
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
                  ref.invalidate(vodStreamsProvider(category.id)),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (streams) {
        if (streams.isEmpty) {
          return const Center(
            child: Text('Nenhum filme nesta categoria.',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }
        final recentMovies = historyAsync.valueOrNull ?? [];
        return CustomScrollView(
          slivers: [
            if (recentMovies.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Text('Assistidos recentemente',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12),
                    itemCount: recentMovies.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final item = recentMovies[i];
                      return GestureDetector(
                        onTap: () => context.push('/player',
                            extra: {
                              'title': item.title,
                              'url': item.url,
                              'isLive': false,
                            }),
                        child: SizedBox(
                          width: 90,
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  child: item.icon != null &&
                                          item.icon!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: item.icon!,
                                          fit: BoxFit.cover,
                                          width: 90,
                                          errorWidget: (_, __,
                                                  ___) =>
                                              Container(
                                                  color: AppColors
                                                      .card),
                                        )
                                      : Container(
                                          color: AppColors.card),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(item.title,
                                  style: const TextStyle(
                                      color:
                                          AppColors.textMuted,
                                      fontSize: 10),
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: 8)),
            ],
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) =>
                      _MovieCard(stream: streams[i]),
                  childCount: streams.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Movie card ────────────────────────────────────────────────────────────────
class _MovieCard extends ConsumerWidget {
  final XtreamStream stream;
  const _MovieCard({required this.stream});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(xtreamServiceProvider);
    final profile = ref.read(activeProfileProvider);

    return GestureDetector(
      onTap: () {
        if (svc == null) return;
        final ext = stream.containerExtension ?? 'ts';
        final url = svc.vodUrl(stream.streamId, ext);
        // Save to history
        if (profile != null) {
          final profileSvc = ref.read(profileServiceProvider);
          profileSvc?.addToHistory(
            profile.id,
            WatchItem(
              id: 'movie_${stream.streamId}',
              title: stream.name,
              type: 'movie',
              icon: stream.icon,
              url: url,
              ext: ext,
              watchedAt: DateTime.now(),
            ),
          );
        }
        context.push('/player', extra: {
          'title': stream.name,
          'url': url,
          'isLive': false,
        });
      },
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
                              stream.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 36,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black54],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.play_circle_outline_rounded,
                            color: Colors.white70, size: 22),
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
                fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (stream.year != null && stream.year!.isNotEmpty)
            Text(stream.year!,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10)),
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
