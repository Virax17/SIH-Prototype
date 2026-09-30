import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'services/bluetooth_manager.dart';
import 'services/volume_ptt_service.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/broadcast_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/emergency_screen.dart';
import 'widgets/language_sheet.dart';

const _onboardingDoneKey = 'itantra.onboarding.done';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool onboardingDone;
  try {
    final prefs = await SharedPreferences.getInstance();
    onboardingDone = prefs.getBool(_onboardingDoneKey) ?? false;
  } catch (_) {
    onboardingDone = true;
  }
  runApp(ITantraApp(onboardingDone: onboardingDone));
}

class ITantraApp extends StatelessWidget {
  final bool onboardingDone;
  const ITantraApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState(onboardingDone: onboardingDone)),
        ChangeNotifierProvider(create: (_) => BluetoothManager()..init()),
      ],
      child: MaterialApp(
        title: 'iTantra',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: appFont, useMaterial3: true, scaffoldBackgroundColor: AppColors.bg),
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final done = context.watch<AppState>().onboardingDone;
    return done ? const RootShell() : const OnboardingScreen();
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      VolumePttService.init(
        onComboPressed: app.startRecording,
        onComboReleased: app.stopRecording,
      );
      unawaited(Permission.microphone.request());
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    app.attachBluetooth(context.watch<BluetoothManager>());

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: app.tab.index,
                children: const [HomeScreen(), BroadcastScreen(), SettingsScreen()],
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
            _NavItem(icon: Icons.mic_none, label: 'Talk', active: app.tab == AppTab.home, onTap: () => app.setTab(AppTab.home)),
            _NavItem(icon: Icons.campaign_outlined, label: 'Broadcast', active: app.tab == AppTab.broadcast, onTap: () => app.setTab(AppTab.broadcast)),
            _NavItem(icon: Icons.tune, label: 'Settings', active: app.tab == AppTab.settings, onTap: () => app.setTab(AppTab.settings)),
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
