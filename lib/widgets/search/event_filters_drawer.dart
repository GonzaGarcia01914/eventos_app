import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/event_search_filters.dart';
import '../../domain/entities/event_type.dart';

class EventFiltersDrawer extends StatelessWidget {
  const EventFiltersDrawer({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.onApply,
    required this.onClear,
    required this.onClose,
  });

  final EventSearchFilters filters;
  final ValueChanged<EventSearchFilters> onFiltersChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Material(
      color: AppColors.surface,
      elevation: 16,
      child: SafeArea(
        left: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: AppColors.onSurface),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.surfaceElevated),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  const _SectionTitle('Tipo de evento'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TypeChip(
                        label: 'Todos',
                        selected: filters.eventType == null,
                        onTap: () => onFiltersChanged(
                          filters.copyWith(clearEventType: true),
                        ),
                      ),
                      for (final type in EventType.filterable)
                        _TypeChip(
                          label: type.label,
                          selected: filters.eventType == type,
                          onTap: () => onFiltersChanged(
                            filters.copyWith(eventType: type),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Rango de fechas'),
                  const SizedBox(height: 10),
                  _DateField(
                    label: 'Desde',
                    value: filters.startDateFrom,
                    dateFormat: dateFormat,
                    onPick: (date) => onFiltersChanged(
                      filters.copyWith(startDateFrom: date),
                    ),
                    onClear: () => onFiltersChanged(
                      filters.copyWith(clearStartDateFrom: true),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DateField(
                    label: 'Hasta',
                    value: filters.startDateTo,
                    dateFormat: dateFormat,
                    onPick: (date) => onFiltersChanged(
                      filters.copyWith(startDateTo: date),
                    ),
                    onClear: () => onFiltersChanged(
                      filters.copyWith(clearStartDateTo: true),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Precio'),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Solo eventos gratis',
                      style: TextStyle(color: AppColors.onSurface),
                    ),
                    value: filters.onlyFree,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                    thumbColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? AppColors.primary
                          : AppColors.onSurfaceMuted,
                    ),
                    onChanged: (value) => onFiltersChanged(
                      filters.copyWith(
                        onlyFree: value,
                        clearMinPrice: value,
                        clearMaxPrice: value,
                      ),
                    ),
                  ),
                  if (!filters.onlyFree) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₲ ${_formatPrice(filters.minPrice ?? EventSearchFilters.defaultMinPrice)}',
                          style: const TextStyle(color: AppColors.onSurfaceMuted),
                        ),
                        Text(
                          '₲ ${_formatPrice(filters.maxPrice ?? EventSearchFilters.defaultMaxPrice)}',
                          style: const TextStyle(color: AppColors.onSurfaceMuted),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(
                        (filters.minPrice ?? EventSearchFilters.defaultMinPrice)
                            .toDouble(),
                        (filters.maxPrice ?? EventSearchFilters.defaultMaxPrice)
                            .toDouble(),
                      ),
                      min: EventSearchFilters.defaultMinPrice.toDouble(),
                      max: EventSearchFilters.defaultMaxPrice.toDouble(),
                      divisions: 25,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.surfaceElevated,
                      labels: RangeLabels(
                        '₲ ${_formatPrice(filters.minPrice ?? EventSearchFilters.defaultMinPrice)}',
                        '₲ ${_formatPrice(filters.maxPrice ?? EventSearchFilters.defaultMaxPrice)}',
                      ),
                      onChanged: (values) => onFiltersChanged(
                        filters.copyWith(
                          minPrice: values.start.round(),
                          maxPrice: values.end.round(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onClear,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        side: const BorderSide(color: AppColors.surfaceElevated),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: onApply,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Aplicar filtros'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.25),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.onSurfaceMuted,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.surfaceElevated,
      ),
      backgroundColor: AppColors.surfaceElevated,
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.dateFormat,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final DateFormat dateFormat;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primary,
                  surface: AppColors.surface,
                  onSurface: AppColors.onSurface,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value == null ? label : dateFormat.format(value!),
                style: TextStyle(
                  color: value == null
                      ? AppColors.onSurfaceMuted
                      : AppColors.onSurface,
                ),
              ),
            ),
            if (value != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.onSurfaceMuted,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
