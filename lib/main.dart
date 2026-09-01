import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/emergency_screen.dart';
import 'widgets/confirm_alert_overlay.dart';
import 'widgets/language_sheet.dart';

void main() {
  runApp(const ITantraApp());
}

class ITantraApp extends StatelessWidget {
  const ITantraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'iTantra',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: barlow, useMaterial3: true),
        home: const RootShell(),
      ),
    );
  }
}

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tk = app.themeMode == AppThemeMode.dark ? ThemeTokens.dark : ThemeTokens.light;

    return Scaffold(
      backgroundColor: tk.bg,
      body: Listener(
        onPointerDown: (_) => app.registerGlobalTap(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildScreen(app.screen)),
              if (app.confirming) const Positioned.fill(child: ConfirmAlertOverlay()),
              if (app.sheet == Sheet.lang) const Positioned.fill(child: LanguageSheet()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(Screen screen) {
    switch (screen) {
      case Screen.home:
        return const HomeScreen();
      case Screen.pairing:
        return const PairingScreen();
      case Screen.settings:
        return const SettingsScreen();
      case Screen.emergency:
        return const EmergencyScreen();
    }
  }
}
