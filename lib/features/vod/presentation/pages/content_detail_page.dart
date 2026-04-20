import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/content_model.dart';
import '../../../../core/theme/app_theme.dart';

class ContentDetailPage extends StatelessWidget {
  final String contentId;
  final Map<String, dynamic>? extra;

  const ContentDetailPage({
    super.key,
    required this.contentId,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final title = extra?['title'] ?? 'Conteúdo';
    final backdropUrl = extra?['backdropUrl'] as String?;
    final posterUrl = extra?['posterUrl'] as String?;
    final description = extra?['description'] as String?;
    final rating = (extra?['rating'] as num?)?.toDouble();
    final year = extra?['year'] as int?;
    final duration = extra?['duration'] as String?;
    final genres = List<String>.from(extra?['genres'] ?? []);
    final streamUrl = extra?['streamUrl'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Backdrop header
          SliverAppBar(
            expandedHeight: 260,
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
                  if (backdropUrl != null)
                    CachedNetworkImage(
                      imageUrl: backdropUrl,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: AppColors.card),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, AppColors.background],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.4, 1.0],
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
                  // Poster + info row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (posterUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: posterUrl,
                            width: 100,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (rating != null)
                                  _InfoChip(
                                    icon: Icons.star_rounded,
                                    label: rating.toStringAsFixed(1),
                                    color: const Color(0xFFFFB300),
                                  ),
                                if (year != null)
                                  _InfoChip(label: year.toString()),
                                if (duration != null)
                                  _InfoChip(label: duration),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (genres.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                children: genres
                                    .map((g) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            g,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Play button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/player', extra: {
                        'title': title,
                        'url': streamUrl ?? '',
                        'isLive': false,
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white),
                      label: const Text(
                        'Assistir agora',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Add to list button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.surfaceVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded,
                          color: AppColors.textSecondary),
                      label: const Text(
                        'Adicionar à lista',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (description != null) ...[
                    const Text(
                      'Sinopse',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const _InfoChip({required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color ?? AppColors.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color ?? AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
