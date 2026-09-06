import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _siren;

  @override
  void initState() {
    super.initState();
    _siren = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _siren.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final msg = kEmergencyMessage[app.langMine]!;

    return Container(
      color: AppColors.danger,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _SirenRing(controller: _siren, delay: 0),
                _SirenRing(controller: _siren, delay: 0.33),
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('EMERGENCY ALERT', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.3, color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 8),
          Text(
            msg.native,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 22, height: 1.3, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            msg.latin,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: appFont, fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Container(
                height: 6,
                color: Colors.white.withValues(alpha: 0.25),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(widthFactor: app.emergencyProgress / 100, child: Container(color: Colors.white)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Playing at maximum volume…', style: TextStyle(fontFamily: appFont, fontSize: 12.5, color: Colors.white.withValues(alpha: 0.75))),
          const SizedBox(height: 24),
          if (app.emergencyDone)
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: app.acknowledgeEmergency,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  alignment: Alignment.center,
                  child: const Text('Acknowledge', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.danger)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SirenRing extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  const _SirenRing({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = (controller.value + delay) % 1.0;
        final scale = 1 + t;
        final opacity = (0.55 * (1 - t)).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(width: 100, height: 100, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
        );
      },
    );
  }
}
