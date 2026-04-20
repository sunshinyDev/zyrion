import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/iptv_provider.dart';
import '../../../../core/providers/profile_provider.dart';
import '../../../../core/models/profile.dart';
import '../../../../core/services/epg_service.dart';
import '../../../../core/services/xtream_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/async_value_ext.dart';
// ── EPG provider ──────────────────────────────────────────────────────────────
final _epgProvider =
    FutureProvider.family<List<EpgEntry>, int>((ref, streamId) async {
  final p = ref.watch(iptvProviderDataProvider);
  if (p == null) return [];
  return EpgService(p).getEpg(streamId, limit: 8);
});

class LiveTvPage extends ConsumerStatefulWidget {
  const LiveTvPage({super.key});

  @override
  ConsumerState<LiveTvPage> createState() => _LiveTvPageState();
}

class _LiveTvPageState extends ConsumerState<LiveTvPage> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(liveCategoriesProvider);
    final streamsAsync =
        ref.watch(liveStreamsProvider(_selectedCategoryId));
    final historyAsync =
        ref.watch(watchHistoryProvider('live'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('TV ao Vivo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category chips
          categoriesAsync.whenReady(
            loading: () => const SizedBox(
              height: 44,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (cats) => SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cats.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final isAll = i == 0;
                  final cat = isAll ? null : cats[i - 1];
                  final selected = isAll
                      ? _selectedCategoryId == null
                      : _selectedCategoryId == cat!.id;
                  return GestureDetector(
                    onTap: () => setState(() =>
                        _selectedCategoryId =
                            isAll ? null : cat!.id),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? AppColors.primaryGradient
                            : null,
                        color: selected
                            ? null
                            : AppColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAll ? 'Todos' : _clean(cat!.name),
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textMuted,
                          fontSize: 13,
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
          ),
          const SizedBox(height: 8),

          // Channels grid
          Expanded(
            child: streamsAsync.whenReady(
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: AppColors.textMuted, size: 48),
                    const SizedBox(height: 12),
                    Text('Erro ao carregar canais\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.invalidate(
                          liveStreamsProvider(
                              _selectedCategoryId)),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (streams) {
                if (streams.isEmpty) {
                  return const Center(
                    child: Text('Nenhum canal encontrado.',
                        style: TextStyle(
                            color: AppColors.textMuted)),
                  );
                }

                // Recent channels section
                final recentItems =
                    historyAsync.valueOrNull ?? [];

                return CustomScrollView(
                  slivers: [
                    // Recently watched
                    if (recentItems.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              16, 8, 16, 8),
                          child: Text(
                            'Assistidos recentemente',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 72,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            itemCount: recentItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final item = recentItems[i];
                              return GestureDetector(
                                onTap: () =>
                                    context.push('/player',
                                        extra: {
                                      'title': item.title,
                                      'url': item.url,
                                      'isLive': true,
                                    }),
                                child: Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius:
                                        BorderRadius.circular(
                                            10),
                                    border: Border.all(
                                        color: AppColors
                                            .primary
                                            .withOpacity(0.3)),
                                  ),
                                  child: Center(
                                    child: item.icon != null &&
                                            item.icon!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: item.icon!,
                                            width: 60,
                                            height: 40,
                                            fit: BoxFit.contain,
                                            errorWidget: (_, __,
                                                    ___) =>
                                                Text(
                                                  item.title,
                                                  style: const TextStyle(
                                                      color: AppColors
                                                          .textMuted,
                                                      fontSize:
                                                          10),
                                                  textAlign:
                                                      TextAlign
                                                          .center,
                                                ),
                                          )
                                        : Text(
                                            item.title,
                                            style: const TextStyle(
                                                color: AppColors
                                                    .textMuted,
                                                fontSize: 10),
                                            textAlign:
                                                TextAlign.center,
                                          ),
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

                    // All channels grid
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.6,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) =>
                              _ChannelCard(stream: streams[i]),
                          childCount: streams.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _clean(String name) => name
      .replaceAll(RegExp(r'[♦️⭐✔️⚽️⚔]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

// ── Channel card ──────────────────────────────────────────────────────────────
class _ChannelCard extends ConsumerWidget {
  final XtreamStream stream;
  const _ChannelCard({required this.stream});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(xtreamServiceProvider);
    final profile = ref.read(activeProfileProvider);

    return GestureDetector(
      onTap: () {
        if (svc == null) return;
        final url = svc.liveUrl(stream.streamId);
        // Save to history
        _saveHistory(ref, profile, url);
        context.push('/player', extra: {
          'title': stream.name,
          'url': url,
          'isLive': true,
        });
      },
      onLongPress: () => _showEpg(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Stack(
          children: [
            Center(
              child: stream.icon != null &&
                      stream.icon!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: stream.icon!,
                      width: 80,
                      height: 50,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) =>
                          _ChannelTitle(stream.name),
                    )
                  : _ChannelTitle(stream.name),
            ),
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.live,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle,
                        color: Colors.white, size: 5),
                    SizedBox(width: 3),
                    Text('AO VIVO',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            // EPG hint
            Positioned(
              bottom: 6,
              left: 6,
              child: const Icon(Icons.info_outline_rounded,
                  color: AppColors.textMuted, size: 12),
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveHistory(
      WidgetRef ref, AppProfile? profile, String url) {
    if (profile == null) return;
    final svc = ref.read(
        profileServiceProvider); // from profile_provider
    if (svc == null) return;
    final item = WatchItem(
      id: 'live_${stream.streamId}',
      title: stream.name,
      type: 'live',
      icon: stream.icon,
      url: url,
      ext: 'ts',
      watchedAt: DateTime.now(),
    );
    svc.addToHistory(profile.id, item);
  }

  void _showEpg(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EpgSheet(stream: stream),
    );
  }
}

// ── EPG bottom sheet ──────────────────────────────────────────────────────────
class _EpgSheet extends ConsumerWidget {
  final XtreamStream stream;
  const _EpgSheet({required this.stream});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epgAsync = ref.watch(_epgProvider(stream.streamId));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (stream.icon != null && stream.icon!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: stream.icon!,
                  width: 40,
                  height: 28,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) =>
                      const SizedBox.shrink(),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stream.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.live,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('AO VIVO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Programação',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          epgAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'EPG não disponível para este canal.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Nenhuma programação disponível.',
                    style:
                        TextStyle(color: AppColors.textMuted),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.surfaceVariant,
                  ),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: e.isNow
                          ? Container(
                              width: 4,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.live,
                                borderRadius:
                                    BorderRadius.circular(2),
                              ),
                            )
                          : const SizedBox(width: 4),
                      title: Text(
                        e.title,
                        style: TextStyle(
                          color: e.isNow
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: e.isNow
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      subtitle: Text(
                        e.timeRange,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      trailing: e.isNow
                          ? Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.live
                                    .withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AGORA',
                                style: TextStyle(
                                  color: AppColors.live,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ChannelTitle extends StatelessWidget {
  final String name;
  const _ChannelTitle(this.name);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        name,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
