import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/event.dart';

class EventDetailDrawer extends StatelessWidget {
  const EventDetailDrawer({
    super.key,
    required this.event,
    required this.isFavorite,
    required this.isTogglingFavorite,
    required this.onClose,
    required this.onFavoriteToggle,
    this.bottomInset = 0,
  });

  final Event event;
  final bool isFavorite;
  final bool isTogglingFavorite;
  final VoidCallback onClose;
  final VoidCallback onFavoriteToggle;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat("EEEE d MMM · HH:mm", 'es').format(event.startAt);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Material(
        color: AppColors.surface,
        elevation: 12,
        shadowColor: AppColors.navBarShadow,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                _EventImage(imageUrl: event.imageUrl),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                        iconColor: isFavorite ? AppColors.primary : AppColors.onSurface,
                        onPressed: isTogglingFavorite ? null : onFavoriteToggle,
                        isLoading: isTogglingFavorite,
                      ),
                      const SizedBox(width: 8),
                      _CircleIconButton(
                        icon: Icons.close_rounded,
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PriceChip(label: event.priceLabel),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: event.location,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.calendar_month_rounded,
                    label: dateLabel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const height = 180.0;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        height: height,
        color: AppColors.surfaceElevated,
        child: const Center(
          child: Icon(
            Icons.event_rounded,
            size: 48,
            color: AppColors.onSurfaceMuted,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        color: AppColors.surfaceElevated,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.onSurfaceMuted),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height,
          color: AppColors.surfaceElevated,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.onSurfaceMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor = AppColors.onSurface,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color iconColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }
}
