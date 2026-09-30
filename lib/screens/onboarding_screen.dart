import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/bluetooth_manager.dart';
import '../theme.dart';

/// First-launch only (gated by `AppState.onboardingDone`, persisted): an
/// intro page plus a permissions page whose status/actions are all real —
/// wired to the same `BluetoothManager`/`permission_handler` calls the rest
/// of the app uses, not decorative toggles.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                physics: const NeverScrollableScrollPhysics(),
                children: [_IntroPage(onContinue: _next), _PermissionsPage()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 2; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(color: i == _page ? AppColors.accent : AppColors.border(0.2), borderRadius: BorderRadius.circular(100)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final VoidCallback onContinue;
  const _IntroPage({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Onboarding', style: TextStyle(fontFamily: appFont, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
          const SizedBox(height: 20),
          const _MeshIllustration(),
          const SizedBox(height: 28),
          const Text(
            'Stay connected.\nEven offline.',
            style: TextStyle(fontFamily: appFont, fontSize: 27, fontWeight: FontWeight.w800, height: 1.15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            'Communicate with people nearby when cellular networks and the internet are unavailable.',
            style: TextStyle(fontFamily: appFont, fontSize: 14, height: 1.4, color: AppColors.textSecondary(0.6)),
          ),
          const SizedBox(height: 22),
          const _FeatureRow(icon: Icons.mic, title: 'Talk', subtitle: 'Speak — it\'s recognized, translated, and sent as text.'),
          const SizedBox(height: 12),
          const _FeatureRow(icon: Icons.campaign_outlined, title: 'Broadcast', subtitle: 'Send an important message to the device you\'re connected to.'),
          const SizedBox(height: 12),
          const _FeatureRow(icon: Icons.bluetooth, title: 'Bluetooth link', subtitle: 'Works phone-to-phone with no SIM, no internet.'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(100),
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: onContinue,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Continue', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white))),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              Text(subtitle, style: TextStyle(fontFamily: appFont, fontSize: 12.5, height: 1.3, color: AppColors.textSecondary(0.55))),
            ],
          ),
        ),
      ],
    );
  }
}

class _MeshIllustration extends StatelessWidget {
  const _MeshIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Stack(
        children: [
          CustomPaint(size: const Size.fromHeight(130), painter: _MeshLinesPainter()),
          Positioned(left: 10, top: 60, child: _NodeIcon(icon: Icons.mic, filled: true)),
          Positioned(left: 100, top: 20, child: _NodeIcon(icon: Icons.podcasts, filled: false)),
          Positioned(left: 190, top: 70, child: _NodeIcon(icon: Icons.podcasts, filled: false)),
          const Positioned(right: 10, top: 15, child: _NodeIcon(icon: Icons.volume_up, filled: true)),
        ],
      ),
    );
  }
}

class _NodeIcon extends StatelessWidget {
  final IconData icon;
  final bool filled;
  const _NodeIcon({required this.icon, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: filled ? AppColors.accentSoft : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: filled ? 0.3 : 0.55)),
      ),
      child: Icon(icon, size: 18, color: AppColors.accent),
    );
  }
}

class _MeshLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    void dashedLine(Offset a, Offset b) {
      const dashLen = 5.0;
      final total = (b - a).distance;
      final dir = (b - a) / total;
      var covered = 0.0;
      while (covered < total) {
        final next = (covered + dashLen).clamp(0, total);
        canvas.drawLine(a + dir * covered, a + dir * next.toDouble(), paint);
        covered += dashLen * 2;
      }
    }

    dashedLine(const Offset(34, 84), const Offset(124, 44));
    dashedLine(const Offset(124, 44), const Offset(214, 94));
    dashedLine(const Offset(214, 94), Offset(size.width - 34, 39));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PermissionsPage extends StatefulWidget {
  @override
  State<_PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<_PermissionsPage> with WidgetsBindingObserver {
  PermissionStatus? _mic;
  PermissionStatus? _notif;
  PermissionStatus? _location;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final mic = await Permission.microphone.status;
    final notif = await Permission.notification.status;
    final location = await Permission.location.status;
    if (!mounted) return;
    setState(() {
      _mic = mic;
      _notif = notif;
      _location = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final bt = context.watch<BluetoothManager>();
    final btGranted = bt.permissionStatus == BtcPermissionStatus.granted || bt.permissionStatus == BtcPermissionStatus.notRequired;
    final micGranted = _mic?.isGranted ?? false;
    final canContinue = btGranted && micGranted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set up your emergency connection',
            style: TextStyle(fontFamily: appFont, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 18),
          _PermissionRow(
            icon: Icons.bluetooth,
            title: 'Bluetooth',
            subtitle: 'Required to communicate with nearby devices.',
            granted: btGranted,
            onEnable: () async {
              await bt.init();
            },
          ),
          const SizedBox(height: 10),
          _PermissionRow(
            icon: Icons.mic,
            title: 'Microphone',
            subtitle: 'Required for voice communication.',
            granted: micGranted,
            onEnable: () async {
              await Permission.microphone.request();
              await _refresh();
            },
          ),
          const SizedBox(height: 10),
          _PermissionRow(
            icon: Icons.notifications_none,
            title: 'Notifications',
            subtitle: 'Receive important incoming messages.',
            granted: _notif?.isGranted ?? false,
            onEnable: () async {
              await Permission.notification.request();
              await _refresh();
            },
          ),
          const SizedBox(height: 10),
          _PermissionRow(
            icon: Icons.location_on_outlined,
            title: 'Location',
            subtitle: 'Required by some devices for Bluetooth discovery.',
            granted: _location?.isGranted ?? false,
            onEnable: () async {
              await Permission.location.request();
              await _refresh();
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary(0.45)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Your data stays on your device unless you choose to send it.', style: TextStyle(fontFamily: appFont, fontSize: 12, color: AppColors.textSecondary(0.5))),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: canContinue ? AppColors.accent : AppColors.border(0.15),
              borderRadius: BorderRadius.circular(100),
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: canContinue ? app.completeOnboarding : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('Continue', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 15, color: canContinue ? Colors.white : AppColors.textSecondary(0.4))),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final Future<void> Function() onEnable;
  const _PermissionRow({required this.icon, required this.title, required this.subtitle, required this.granted, required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(0.08))),
      child: Row(
        children: [
          Container(width: 38, height: 38, decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle), child: Icon(icon, size: 17, color: AppColors.accent)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                Text(subtitle, style: TextStyle(fontFamily: appFont, fontSize: 12, color: AppColors.textSecondary(0.5))),
              ],
            ),
          ),
          if (granted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                const SizedBox(width: 4),
                Text('On', style: TextStyle(fontFamily: appFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.success)),
              ],
            )
          else
            OutlinedButton(
              onPressed: onEnable,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              child: const Text('Enable', style: TextStyle(fontFamily: appFont, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
