import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../presentation/events/events_catalog_view_model.dart';
import '../../../widgets/events/event_detail_drawer.dart';
import '../../../widgets/search/event_filters_drawer.dart';
import '../../../widgets/search/event_search_bar.dart';
import 'home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.eventsCatalog,
    required this.isAdminUnlocked,
  });

  final EventsCatalogViewModel eventsCatalog;
  final bool isAdminUnlocked;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const LatLng _initialPosition = LatLng(-25.2637, -57.5759);
  static const double _navBarClearance = 88;

  late final HomeViewModel _viewModel;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(eventsCatalog: widget.eventsCatalog)..initialize();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.eventsCatalog;

    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, catalog]),
      builder: (context, _) {
        if (_viewModel.isLoadingStyle) {
          return const ColoredBox(
            color: AppColors.background,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final topPadding = MediaQuery.paddingOf(context).top + 12;

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _initialPosition,
                zoom: 13,
              ),
              style: _viewModel.mapStyle,
              markers: _viewModel.markers,
              mapType: MapType.normal,
              onCameraMove: (position) =>
                  _viewModel.updateCameraZoom(position.zoom),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
            ),
            Positioned(
              top: topPadding,
              left: 16,
              right: 16,
              child: EventSearchBar(
                controller: _searchController,
                onChanged: catalog.updateSearchQuery,
                onFilterTap: catalog.openFilterDrawer,
                hasActiveFilters: catalog.hasActiveFilters,
                showClear: catalog.searchQuery.isNotEmpty,
              ),
            ),
            if (catalog.isLoadingEvents)
              Positioned(
                top: topPadding + 64,
                left: 0,
                right: 0,
                child: const Center(
                  child: _StatusChip(
                    icon: Icons.refresh_rounded,
                    label: 'Cargando eventos...',
                  ),
                ),
              ),
            if (catalog.eventsError != null && !catalog.isLoadingEvents)
              Positioned(
                top: topPadding + 64,
                left: 16,
                right: 16,
                child: _StatusChip(
                  icon: Icons.error_outline_rounded,
                  label: _shortError(catalog.eventsError!),
                  isError: true,
                ),
              ),
            if (catalog.isFilterDrawerOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: catalog.closeFilterDrawer,
                  child: Container(color: Colors.black54),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: MediaQuery.sizeOf(context).width * 0.88,
                child: EventFiltersDrawer(
                  filters: catalog.draftFilters,
                  onFiltersChanged: catalog.updateDraftFilters,
                  onApply: catalog.applyDraftFilters,
                  onClear: catalog.clearDraftFilters,
                  onClose: catalog.closeFilterDrawer,
                ),
              ),
            ],
            if (_viewModel.hasSelectedEvent) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: _viewModel.clearSelectedEvent,
                  child: Container(color: Colors.black54),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: EventDetailDrawer(
                  event: _viewModel.selectedEvent!,
                  isFavorite: _viewModel.isSelectedFavorite,
                  isTogglingFavorite: _viewModel.isTogglingFavorite,
                  onClose: _viewModel.clearSelectedEvent,
                  onFavoriteToggle: _viewModel.toggleSelectedFavorite,
                  onDelete: widget.isAdminUnlocked
                      ? () => _deleteSelectedEvent(context)
                      : null,
                  bottomInset: _navBarClearance,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _shortError(String error) {
    if (error.length <= 120) return error;
    return '${error.substring(0, 117)}...';
  }

  Future<void> _deleteSelectedEvent(BuildContext context) async {
    final event = _viewModel.selectedEvent;
    if (event == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Eliminar evento',
          style: TextStyle(color: AppColors.onSurface),
        ),
        content: Text(
          'Eliminar "${event.title}" de forma permanente?',
          style: const TextStyle(color: AppColors.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final deleted = await _viewModel.deleteSelectedEvent();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(deleted ? 'Evento eliminado' : 'No se pudo eliminar'),
        backgroundColor: deleted ? Colors.green.shade600 : Colors.red.shade600,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    this.isError = false,
  });

  final IconData icon;
  final String label;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isError ? Colors.redAccent : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isError ? Colors.redAccent : AppColors.onSurface,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
