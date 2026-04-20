import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/iptv_provider.dart';
import '../../../../core/services/espn_service.dart';
import '../../../../core/theme/app_theme.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _selectedLeagueProvider =
    StateProvider<EspnLeague>((ref) => kEspnLeagues.first);

final _scoreboardProvider =
    FutureProvider.family<List<EspnEvent>, String>((ref, leagueId) async {
  final league =
      kEspnLeagues.firstWhere((l) => l.id == leagueId);
  return EspnService.getScoreboard(league);
});

// ── Page ──────────────────────────────────────────────────────────────────────

class SportsPage extends ConsumerWidget {
  const SportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLeague = ref.watch(_selectedLeagueProvider);
    final eventsAsync =
        ref.watch(_scoreboardProvider(selectedLeague.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Esportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          // League selector
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              itemCount: kEspnLeagues.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final league = kEspnLeagues[i];
                final selected =
                    league.id == selectedLeague.id;
                return GestureDetector(
                  onTap: () => ref
                      .read(_selectedLeagueProvider.notifier)
                      .state = league,
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(league.emoji,
                            style: const TextStyle(
                                fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          league.name,
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Events list
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: AppColors.textMuted,
                        size: 48),
                    const SizedBox(height: 12),
                    Text('Erro ao carregar\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.invalidate(
                          _scoreboardProvider(
                              selectedLeague.id)),
                      child:
                          const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(selectedLeague.emoji,
                            style: const TextStyle(
                                fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum jogo hoje em\n${selectedLeague.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                // Separate live, upcoming, finished
                final live = events
                    .where((e) => e.isLive)
                    .toList();
                final pre = events
                    .where((e) => e.isPre)
                    .toList();
                final post = events
                    .where((e) => e.isPost)
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (live.isNotEmpty) ...[
                      _SectionLabel(
                          '🔴 Ao Vivo (${live.length})'),
                      ...live.map((e) =>
                          _EventCard(event: e, ref: ref)),
                      const SizedBox(height: 8),
                    ],
                    if (pre.isNotEmpty) ...[
                      _SectionLabel(
                          '🕐 Em Breve (${pre.length})'),
                      ...pre.map((e) =>
                          _EventCard(event: e, ref: ref)),
                      const SizedBox(height: 8),
                    ],
                    if (post.isNotEmpty) ...[
                      _SectionLabel(
                          '✅ Encerrados (${post.length})'),
                      ...post.map((e) =>
                          _EventCard(event: e, ref: ref)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
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

class _EventCard extends ConsumerWidget {
  final EspnEvent event;
  final WidgetRef ref;

  const _EventCard({required this.event, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = event.homeTeam;
    final away = event.awayTeam;
    final svc = ref.read(xtreamServiceProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: event.isLive
              ? AppColors.live.withOpacity(0.4)
              : AppColors.surfaceVariant,
          width: event.isLive ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // League + status row
            Row(
              children: [
                Text(
                  event.leagueName,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                _StatusBadge(event: event),
              ],
            ),
            const SizedBox(height: 12),

            // Teams row
            Row(
              children: [
                // Away team
                Expanded(
                  child: _TeamWidget(
                    name: away?.name ?? '',
                    logo: away?.logo,
                    score: away?.score ?? '',
                    winner: away?.winner,
                    align: CrossAxisAlignment.start,
                  ),
                ),

                // VS / Score
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12),
                  child: event.isPost || event.isLive
                      ? Text(
                          '${away?.score ?? '0'} – ${home?.score ?? '0'}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : Column(
                          children: [
                            const Text('VS',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w700,
                                )),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(event.date),
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),

                // Home team
                Expanded(
                  child: _TeamWidget(
                    name: home?.name ?? '',
                    logo: home?.logo,
                    score: home?.score ?? '',
                    winner: home?.winner,
                    align: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),

            // Venue
            if (event.venue != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.textMuted, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    event.venue!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final EspnEvent event;
  const _StatusBadge({required this.event});

  @override
  Widget build(BuildContext context) {
    if (event.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.live,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle,
                color: Colors.white, size: 6),
            const SizedBox(width: 4),
            Text(
              event.statusDetail,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: event.isPost
            ? AppColors.surfaceVariant
            : AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        event.statusDetail,
        style: TextStyle(
          color: event.isPost
              ? AppColors.textMuted
              : AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TeamWidget extends StatelessWidget {
  final String name;
  final String? logo;
  final String score;
  final bool? winner;
  final CrossAxisAlignment align;

  const _TeamWidget({
    required this.name,
    required this.logo,
    required this.score,
    required this.align,
    this.winner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        if (logo != null && logo!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: logo!,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => const Icon(
              Icons.sports_soccer_rounded,
              color: AppColors.textMuted,
              size: 32,
            ),
          )
        else
          const Icon(Icons.sports_soccer_rounded,
              color: AppColors.textMuted, size: 32),
        const SizedBox(height: 6),
        Text(
          name,
          style: TextStyle(
            color: winner == true
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: winner == true
                ? FontWeight.w700
                : FontWeight.w400,
          ),
          textAlign: align == CrossAxisAlignment.start
              ? TextAlign.left
              : TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
