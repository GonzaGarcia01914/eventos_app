import 'package:flutter/material.dart';

import '../../core/navigation/app_tab.dart';
import '../../features/admin/presentation/admin_screen.dart';
import '../../features/discover/presentation/discover_screen.dart';
import '../../features/favourites/presentation/favourites_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/perfil/presentation/perfil_screen.dart';
import '../../domain/entities/event.dart';
import '../events/events_catalog_view_model.dart';
import '../../widgets/navigation/app_bottom_nav_bar.dart';
import 'shell_view_model.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late final ShellViewModel _viewModel;
  late final EventsCatalogViewModel _eventsCatalog;
  final _favouritesKey = GlobalKey<FavouritesScreenState>();
  final _homeKey = GlobalKey<HomeScreenState>();
  bool _isAdminUnlocked = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ShellViewModel();
    _eventsCatalog = EventsCatalogViewModel()..initialize();
  }

  void _onTabSelected(AppTab tab) {
    if (tab == AppTab.admin && !_isAdminUnlocked) return;
    _viewModel.selectTab(tab);
    if (tab == AppTab.favourites) {
      _favouritesKey.currentState?.reload();
    }
  }

  void _openEventFromDiscover(Event event) {
    _viewModel.selectTab(AppTab.home);
    _homeKey.currentState?.focusEvent(event);
  }

  void _unlockAdmin() {
    setState(() => _isAdminUnlocked = true);
    _viewModel.selectTab(AppTab.admin);
  }

  @override
  void dispose() {
    _eventsCatalog.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final isDiscoverActive = _viewModel.currentTab == AppTab.discover;

        return Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: _viewModel.currentIndex,
            children: [
              HomeScreen(
                key: _homeKey,
                eventsCatalog: _eventsCatalog,
                isAdminUnlocked: _isAdminUnlocked,
              ),
              DiscoverScreen(
                eventsCatalog: _eventsCatalog,
                isActive: isDiscoverActive,
                onEventInfoTap: _openEventFromDiscover,
              ),
              FavouritesScreen(key: _favouritesKey),
              PerfilScreen(onAdminUnlocked: _unlockAdmin),
              if (_isAdminUnlocked)
                AdminScreen(
                  onEventApproved: () =>
                      _eventsCatalog.refreshEvents(forceRefresh: true),
                  eventsCatalog: _eventsCatalog,
                )
              else
                const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentTab: _viewModel.currentTab,
            tabs: [
              for (final tab in AppTab.valuesOrdered)
                if (tab != AppTab.admin || _isAdminUnlocked) tab,
            ],
            onTabSelected: _onTabSelected,
          ),
        );
      },
    );
  }
}
