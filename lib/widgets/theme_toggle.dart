import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/services/theme_service.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        return IconButton(
          icon: Icon(
            ThemeService().isDarkMode ? Icons.light_mode : Icons.dark_mode,
          ),
          onPressed: () {
            ThemeService().toggleTheme();
          },
          tooltip: ThemeService().isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        );
      },
    );
  }
}
