import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/theme.dart';

class SoccerApp extends StatelessWidget {
  const SoccerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      darkTheme: appDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
