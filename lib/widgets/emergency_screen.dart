import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme.dart';
import 'wave_bars.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with TickerProviderStateMixin {
  late final AnimationController _siren;
  late final AnimationController _bar;

  @override
  void initState() {
    super.initState();
    _siren = AnimationController(vsync: this, duration: const Duration(milliseconds: 550))..repeat(reverse: true);
    _bar = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  }

  @override
  void dispose() {
    _siren.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return AnimatedBuilder(
      animation: _siren,
      builder: (context, child) {
        final bg = Color.lerp(AppColors.sirenA, AppColors.sirenB, _siren.value)!;
        return Container(color: bg, child: child);
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 34),
                const SizedBox(width: 12),
                const Text('PRIORITY', style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w800, fontSize: 26, color: Colors.white, letterSpacing: 1.2)),
                const Spacer(),
                Text('MAX VOLUME', style: TextStyle(fontFamily: mono, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 74, child: WaveBars(color: Colors.white, barWidth: 9, maxHeight: 74)),
                  const SizedBox(height: 26),
                  Text(
                    'From $kPairedDeviceName · TA → EN',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: mono, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 1.3, color: Colors.white.withValues(alpha: 0.82)),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Rockfall on the north track. Do not proceed. Hold at marker 4.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w700, fontSize: 40, height: 1.14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    color: Colors.black.withValues(alpha: 0.3),
                    child: AnimatedBuilder(
                      animation: _bar,
                      builder: (context, _) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(widthFactor: _bar.value, child: Container(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'PLAYBACK LOCKED · 5s',
                  style: TextStyle(fontFamily: mono, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 1.0, color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: app.ackEmergency,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 76),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 2)),
                      child: const Center(
                        child: Text('ACKNOWLEDGE', style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: 0.6, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
