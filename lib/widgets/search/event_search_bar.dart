import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class EventSearchBar extends StatelessWidget {
  const EventSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
    this.hasActiveFilters = false,
    this.showClear = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.surface,
            elevation: 6,
            shadowColor: AppColors.navBarShadow,
            borderRadius: BorderRadius.circular(20),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: AppColors.onSurface, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Buscar eventos...',
                hintStyle: const TextStyle(color: AppColors.onSurfaceMuted),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.onSurfaceMuted,
                ),
                suffixIcon: showClear
                    ? IconButton(
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.onSurfaceMuted,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _FilterButton(
          onTap: onFilterTap,
          hasActiveFilters: hasActiveFilters,
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.onTap,
    required this.hasActiveFilters,
  });

  final VoidCallback onTap;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: hasActiveFilters
          ? AppColors.primary.withValues(alpha: 0.25)
          : AppColors.surface,
      elevation: 6,
      shadowColor: AppColors.navBarShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: hasActiveFilters
            ? const BorderSide(color: AppColors.primary, width: 1.2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                color: hasActiveFilters ? AppColors.primary : AppColors.onSurface,
              ),
              if (hasActiveFilters)
                const Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
