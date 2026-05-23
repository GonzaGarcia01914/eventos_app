import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/entities/event.dart';
import '../../../presentation/events/events_catalog_view_model.dart';

class DiscoverViewModel extends ChangeNotifier {
  DiscoverViewModel({required EventsCatalogViewModel eventsCatalog})
      : _eventsCatalog = eventsCatalog {
    _eventsCatalog.addListener(_onCatalogChanged);
  }

  static const storyDuration = Duration(seconds: 7);
  static const tickInterval = Duration(milliseconds: 50);

  final EventsCatalogViewModel _eventsCatalog;

  final PageController pageController = PageController();

  int _currentIndex = 0;
  double _segmentProgress = 0;
  bool _isActive = false;
  Timer? _timer;

  int get currentIndex => _currentIndex;
  double get segmentProgress => _segmentProgress;
  List<Event> get events => _eventsCatalog.visibleEvents;
  bool get isLoading => _eventsCatalog.isLoadingEvents;
  String? get error => _eventsCatalog.eventsError;
  bool get hasEvents => events.isNotEmpty;

  void setActive(bool active) {
    if (_isActive == active) return;
    _isActive = active;
    if (active) {
      _startTimer();
    } else {
      _pauseTimer();
    }
    notifyListeners();
  }

  void _onCatalogChanged() {
    _currentIndex = 0;
    _segmentProgress = 0;
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
    if (_isActive && hasEvents) {
      _startTimer();
    } else {
      _pauseTimer();
    }
    notifyListeners();
  }

  void _startTimer() {
    _pauseTimer();
    if (!hasEvents || !_isActive) return;

    _timer = Timer.periodic(tickInterval, (_) {
      _segmentProgress +=
          tickInterval.inMilliseconds / storyDuration.inMilliseconds;
      if (_segmentProgress >= 1) {
        goToNext();
      } else {
        notifyListeners();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _resetSegment() {
    _segmentProgress = 0;
  }

  void goToNext() {
    if (events.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % events.length;
    _animateToIndex(nextIndex);
  }

  void goToPrevious() {
    if (events.isEmpty) return;
    final previousIndex =
        _currentIndex == 0 ? events.length - 1 : _currentIndex - 1;
    _animateToIndex(previousIndex);
  }

  void onPageChanged(int index) {
    _currentIndex = index;
    _resetSegment();
    if (_isActive) _startTimer();
    notifyListeners();
  }

  void _animateToIndex(int index) {
    _currentIndex = index;
    _resetSegment();
    if (pageController.hasClients) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
    if (_isActive) _startTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _pauseTimer();
    _eventsCatalog.removeListener(_onCatalogChanged);
    pageController.dispose();
    super.dispose();
  }
}
