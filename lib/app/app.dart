import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../presentation/shell/main_shell_screen.dart';

class EventosApp extends StatelessWidget {
  const EventosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eventos',
      theme: AppTheme.dark,
      home: const MainShellScreen(),
    );
  }
}
