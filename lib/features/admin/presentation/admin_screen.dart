import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/event.dart';
import 'admin_view_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.onEventApproved});

  final Future<void> Function() onEventApproved;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final AdminViewModel _viewModel;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _viewModel = AdminViewModel();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel.loadPendingEvents();
    _viewModel.loadPublishedEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Gestión de Eventos',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () {
                          _viewModel.loadPendingEvents();
                          _viewModel.loadPublishedEvents();
                        },
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Por Aprobar'),
                    Tab(text: 'Publicados'),
                  ],
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.onSurfaceMuted,
                  indicatorColor: AppColors.primary,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingEventsTab(),
                      _buildPublishedEventsTab(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPendingEventsTab() {
    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_viewModel.isPendingEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: AppColors.onSurfaceMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay eventos pendientes',
              style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _viewModel.pendingEvents.length,
      itemBuilder: (context, index) {
        final event = _viewModel.pendingEvents[index];
        return _EventCard(
          event: event,
          onTap: () => _showEventDetail(event),
          onApprove: () => _approveEvent(event),
          onReject: () => _rejectEvent(event),
          isPending: true,
        );
      },
    );
  }

  Widget _buildPublishedEventsTab() {
    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: _viewModel.searchPublishedEvents,
            style: const TextStyle(color: AppColors.onSurface, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, descripción o ubicación...',
              hintStyle: const TextStyle(color: AppColors.onSurfaceMuted),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.onSurfaceMuted,
              ),
              filled: true,
              fillColor: const Color(0xFF171A1D),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.surfaceElevated),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.surfaceElevated),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _viewModel.isPublishedEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 64,
                        color: AppColors.onSurfaceMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _viewModel.searchQuery.isEmpty
                            ? 'No hay eventos publicados'
                            : 'No se encontraron eventos',
                        style: const TextStyle(
                          color: AppColors.onSurfaceMuted,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _viewModel.publishedEvents.length,
                  itemBuilder: (context, index) {
                    final event = _viewModel.publishedEvents[index];
                    return _EventCard(
                      event: event,
                      onTap: () => _showEventDetail(event),
                      onApprove: null,
                      onReject: () => _deletePublishedEvent(event),
                      isPending: false,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _approveEvent(Event event) async {
    final eventId = int.tryParse(event.id);
    if (eventId == null) return;

    final approved = await _viewModel.approveEvent(eventId);
    if (approved) {
      await widget.onEventApproved();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved ? 'Evento aprobado' : 'Error al aprobar evento',
          ),
          backgroundColor: approved
              ? Colors.green.shade600
              : Colors.red.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _rejectEvent(Event event) async {
    final eventId = int.tryParse(event.id);
    if (eventId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Descartar evento',
          style: TextStyle(color: AppColors.onSurface),
        ),
        content: Text(
          '¿Estás seguro de que quieres descartar "${event.title}"?',
          style: const TextStyle(color: AppColors.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      await _viewModel.rejectEvent(eventId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Evento descartado'),
          backgroundColor: Colors.orange.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deletePublishedEvent(Event event) async {
    final eventId = int.tryParse(event.id);
    if (eventId == null) {
      _logUI("❌ Error: El ID del evento no es válido: ${event.id}");
      return;
    }

    _logUI("Usuario inicia eliminación del evento: ${event.title} (ID: $eventId)");

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Eliminar evento',
          style: TextStyle(color: AppColors.onSurface),
        ),
        content: Text(
          '¿Eliminar permanentemente "${event.title}"?',
          style: const TextStyle(color: AppColors.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _logUI("  - Usuario canceló la eliminación");
              Navigator.pop(context, false);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _logUI("  - Usuario confirmó la eliminación");
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) {
      _logUI("  - Operación cancelada por el usuario");
      return;
    }

    _logUI("Enviando solicitud de eliminación al ViewModel...");
    final deleted = await _viewModel.deleteEvent(eventId);

    if (!mounted) return;

    if (deleted) {
      _logUI("✅ Evento eliminado exitosamente de la UI");
    } else {
      _logUI("❌ Error: El ViewModel reportó fallo en eliminación");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(deleted ? 'Evento eliminado' : 'No se pudo eliminar'),
        backgroundColor: deleted ? Colors.green.shade600 : Colors.red.shade600,
      ),
    );
  }

  void _logUI(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1];
    print("[ADMIN UI] [$timestamp] $message");
  }

  void _showEventDetail(Event event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _EventDetailSheet(
        event: event,
        onDelete: () async {
          Navigator.pop(context);
          await _deletePublishedEvent(event);
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    required this.isPending,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback onReject;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        event.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.surfaceElevated,
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_rounded,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.onSurfaceMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.priceLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: onApprove,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Aprobar'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: onReject,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Descartar'),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: onReject,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Eliminar'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDetailSheet extends StatelessWidget {
  const _EventDetailSheet({required this.event, required this.onDelete});

  final Event event;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Detalle del evento',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.onSurface,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _DetailImage(imageUrl: event.imageUrl),
            ),
            const SizedBox(height: 16),
            Text(
              event.title,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.location_on_rounded, text: event.location),
            const SizedBox(height: 16),
            const Text(
              'Descripcion',
              style: TextStyle(
                color: AppColors.onSurfaceMuted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description.trim().isEmpty
                  ? 'Sin descripcion'
                  : event.description,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 16,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Eliminar evento'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const height = 220.0;
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        height: height,
        color: AppColors.surfaceElevated,
        child: const Center(
          child: Icon(
            Icons.image_rounded,
            color: AppColors.onSurfaceMuted,
            size: 44,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        color: AppColors.surfaceElevated,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_rounded,
            color: AppColors.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.onSurfaceMuted,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
