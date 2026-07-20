import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "INTERFAZ Y TEMAS",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildThemeButton(
              context,
              type: ThemeModeType.dark,
              color: const Color(0xff0d0e11),
              isSelected: themeProvider.currentTheme == ThemeModeType.dark,
              onTap: () => themeProvider.setTheme(ThemeModeType.dark),
            ),
            _buildThemeButton(
              context,
              type: ThemeModeType.light,
              color: const Color(0xffffffff),
              isSelected: themeProvider.currentTheme == ThemeModeType.light,
              onTap: () => themeProvider.setTheme(ThemeModeType.light),
            ),
            _buildThemeButton(
              context,
              type: ThemeModeType.sepia,
              color: const Color(0xfff4ecd8),
              isSelected: themeProvider.currentTheme == ThemeModeType.sepia,
              onTap: () => themeProvider.setTheme(ThemeModeType.sepia),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeButton(
    BuildContext context, {
    required ThemeModeType type,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xff9d4edd) : Colors.grey.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xff9d4edd).withOpacity(0.4), blurRadius: 8)]
              : [],
        ),
      ),
    );
  }
}
