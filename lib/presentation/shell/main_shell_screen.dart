import 'package:flutter/material.dart';

import '../../core/navigation/app_tab.dart';
import '../../features/discover/presentation/discover_screen.dart';
import '../../features/favourites/presentation/favourites_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/perfil/presentation/perfil_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _viewModel = ShellViewModel();
    _eventsCatalog = EventsCatalogViewModel()..initialize();
  }

  void _onTabSelected(AppTab tab) {
    _viewModel.selectTab(tab);
    if (tab == AppTab.favourites) {
      _favouritesKey.currentState?.reload();
    }
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
              HomeScreen(eventsCatalog: _eventsCatalog),
              DiscoverScreen(
                eventsCatalog: _eventsCatalog,
                isActive: isDiscoverActive,
              ),
              FavouritesScreen(key: _favouritesKey),
              const PerfilScreen(),
            ],
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentTab: _viewModel.currentTab,
            onTabSelected: _onTabSelected,
          ),
        );
      },
    );
  }
}
