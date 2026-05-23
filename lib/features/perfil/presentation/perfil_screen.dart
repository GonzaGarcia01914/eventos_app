import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perfil',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Text(
                    'Perfil',
                    style: TextStyle(color: AppColors.onSurfaceMuted),
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
