import 'package:flutter/material.dart';

import '../prep_store.dart';
import 'app_theme.dart';
import 'dashboard_shell.dart';

class CatPrepApp extends StatelessWidget {
  const CatPrepApp({required this.store, super.key});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CAT 2026 Dashboard',
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: DashboardShell(store: store),
        );
      },
    );
  }
}
