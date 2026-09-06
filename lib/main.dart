import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/emergency_screen.dart';
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
        theme: ThemeData(fontFamily: appFont, useMaterial3: true, scaffoldBackgroundColor: AppColors.bg),
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: app.tab.index,
                children: const [HomeScreen(), DevicesScreen(), SettingsScreen()],
              ),
            ),
            if (app.showEmergency) const Positioned.fill(child: EmergencyScreen()),
            if (app.showLangSheet) const Positioned.fill(child: LanguageSheet()),
          ],
        ),
      ),
      bottomNavigationBar: app.showEmergency
          ? null
          : _BottomNav(app: app),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final AppState app;
  const _BottomNav({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border(0.08)))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(icon: Icons.chat_bubble_outline, label: 'Talk', active: app.tab == AppTab.home, onTap: () => app.setTab(AppTab.home)),
            _NavItem(icon: Icons.bluetooth, label: 'Devices', active: app.tab == AppTab.devices, onTap: () => app.setTab(AppTab.devices)),
            _NavItem(icon: Icons.settings_outlined, label: 'Settings', active: app.tab == AppTab.settings, onTap: () => app.setTab(AppTab.settings)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textSecondary(0.55);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(fontFamily: appFont, fontSize: 11, color: color, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}
