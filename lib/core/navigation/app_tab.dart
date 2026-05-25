import 'package:flutter/material.dart';

/// Pestañas principales de la app.
enum AppTab {
  home(Icons.home_rounded, 'Inicio'),
  discover(Icons.explore_rounded, 'Discover'),
  favourites(Icons.favorite_rounded, 'Favoritos'),
  perfil(Icons.add_circle_rounded, 'Subir'),
  admin(Icons.admin_panel_settings_rounded, 'Admin');

  const AppTab(this.icon, this.label);

  final IconData icon;
  final String label;

  static const List<AppTab> valuesOrdered = [
    AppTab.home,
    AppTab.discover,
    AppTab.favourites,
    AppTab.perfil,
    AppTab.admin,
  ];
}
