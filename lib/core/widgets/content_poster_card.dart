import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/content_model.dart';
import '../theme/app_theme.dart';

class ContentPosterCard extends StatefulWidget {
  final ContentModel content;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool showTitle;
  final bool showRating;

  const ContentPosterCard({
    super.key,
    required this.content,
    this.onTap,
    this.width = 120,
    this.height = 180,
    this.showTitle = true,
    this.showRating = false,
  });

  @override
  State<ContentPosterCard> createState() => _ContentPosterCardState();
}

class _ContentPosterCardState extends State<ContentPosterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) {
        _hoverController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: widget.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary
                        .withOpacity(0.3 * _glowAnim.value),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  SizedBox(
                    width: widget.width,
                    height: widget.height,
                    child: widget.content.posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.content.posterUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                _buildShimmer(),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: widget.height * 0.4,
                      decoration: const BoxDecoration(
                        gradient: AppColors.posterOverlay,
                      ),
                    ),
                  ),
                  // Badges
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Row(
                      children: [
                        if (widget.content.isLive)
                          _Badge(
                            label: 'AO VIVO',
                            color: AppColors.live,
                          ),
                        if (widget.content.isNew && !widget.content.isLive)
                          _Badge(
                            label: 'NOVO',
                            color: AppColors.accent,
                          ),
                      ],
                    ),
                  ),
                  // Rating badge
                  if (widget.showRating && widget.content.rating != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB300),
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              widget.content.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Title
            if (widget.showTitle) ...[
              const SizedBox(height: 8),
              Text(
                widget.content.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.content.year != null)
                Text(
                  widget.content.year.toString(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.card,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: AppColors.surfaceVariant,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppColors.surfaceVariant,
      child: const Icon(
        Icons.movie_outlined,
        color: AppColors.textMuted,
        size: 32,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
