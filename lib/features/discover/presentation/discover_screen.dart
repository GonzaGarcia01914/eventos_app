import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/event.dart';
import '../../../presentation/events/events_catalog_view_model.dart';
import '../../../widgets/discover/story_event_overlay.dart';
import '../../../widgets/discover/story_media_view.dart';
import '../../../widgets/discover/story_progress_bar.dart';
import 'discover_view_model.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.eventsCatalog,
    required this.isActive,
    this.onEventInfoTap,
  });

  final EventsCatalogViewModel eventsCatalog;
  final bool isActive;
  final void Function(Event event)? onEventInfoTap;

  @override
  State<DiscoverScreen> createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen> {
  static const double _navBarClearance = 88;

  late final DiscoverViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DiscoverViewModel(eventsCatalog: widget.eventsCatalog);
    _viewModel.setActive(widget.isActive);
  }

  @override
  void didUpdateWidget(DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _viewModel.setActive(widget.isActive);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const ColoredBox(
            color: AppColors.background,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!_viewModel.hasEvents) {
          return ColoredBox(
            color: AppColors.background,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    _viewModel.error ??
                        'No hay eventos para mostrar.\nAjusta los filtros en Inicio o espera a que carguen.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.onSurfaceMuted,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final events = _viewModel.events;
        final topPadding = MediaQuery.paddingOf(context).top;
        final bottomPadding = MediaQuery.paddingOf(context).bottom;

        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _viewModel.pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                onPageChanged: _viewModel.onPageChanged,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final isCurrent = index == _viewModel.currentIndex;

                  return StoryMediaView(
                    key: ValueKey(event.id),
                    event: event,
                    isActive: widget.isActive && isCurrent,
                  );
                },
              ),
              StoryEventOverlay(
                event: events[_viewModel.currentIndex],
                bottomInset: _navBarClearance + bottomPadding,
                onInfoTap: () =>
                    widget.onEventInfoTap?.call(events[_viewModel.currentIndex]),
              ),
              Positioned(
                top: topPadding + 8,
                left: 12,
                right: 12,
                child: StoryProgressBar(
                  segmentCount: events.length,
                  currentIndex: _viewModel.currentIndex,
                  currentProgress: _viewModel.segmentProgress,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _viewModel.goToPrevious,
                    ),
                  ),
                  const Expanded(
                    flex: 2,
                    child: IgnorePointer(child: SizedBox()),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _viewModel.goToNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
