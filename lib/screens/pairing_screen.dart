import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class PairingScreen extends StatelessWidget {
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tk = app.themeMode == AppThemeMode.dark ? ThemeTokens.dark : ThemeTokens.light;

    return Container(
      color: tk.bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _BackButton(tk: tk, onTap: app.goHome),
                const SizedBox(width: 12),
                Text('Devices', style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w700, fontSize: 24, color: tk.text)),
                const Spacer(),
                Material(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: app.toggleScan,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sync, color: Color(0xFF0A0C0B), size: 22),
                          const SizedBox(width: 9),
                          Text(app.scanning ? 'Scanning' : 'Scan', style: const TextStyle(fontFamily: barlow, fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0A0C0B))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (app.scanning)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: const _ScanProgressBar(),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              children: [
                for (final d in app.devices) ...[
                  _DeviceCard(d: d, app: app, tk: tk),
                  const SizedBox(height: 10),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFF26332C), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4D5A53), shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pairing works with no SIM, no Wi-Fi, no cell signal. Range ≈ 60 m line of sight.',
                          style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w500, fontSize: 13, height: 1.35, color: tk.textSec),
                        ),
                      ),
                    ],
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

class _ScanProgressBar extends StatefulWidget {
  const _ScanProgressBar();
  @override
  State<_ScanProgressBar> createState() => _ScanProgressBarState();
}

class _ScanProgressBarState extends State<_ScanProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 4,
        color: const Color(0xFF1C2520),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(widthFactor: _c.value, child: Container(color: AppColors.amber)),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final ThemeTokens tk;
  final VoidCallback onTap;
  const _BackButton({required this.tk, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tk.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: tk.cardBorder, width: 1.5)),
          child: const Icon(Icons.arrow_back, color: Color(0xFFCFD9D3), size: 26),
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final DeviceInfo d;
  final AppState app;
  final ThemeTokens tk;
  const _DeviceCard({required this.d, required this.app, required this.tk});

  @override
  Widget build(BuildContext context) {
    final lit = d.state == DeviceLinkState.failed
        ? AppColors.red
        : d.state == DeviceLinkState.connected
            ? AppColors.green
            : AppColors.amber;
    final statusColor = d.state == DeviceLinkState.failed
        ? AppColors.red
        : d.state == DeviceLinkState.connected
            ? AppColors.green
            : tk.textSec;

    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111614),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF232E28), width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 26,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (i) {
                final heights = [8.0, 14.0, 20.0, 26.0];
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Container(
                    width: 5,
                    height: heights[i],
                    decoration: BoxDecoration(color: i < d.bars ? lit : const Color(0xFF2C3A32), borderRadius: BorderRadius.circular(1)),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w600, fontSize: 19, color: tk.text)),
                const SizedBox(height: 4),
                Text(d.status.toUpperCase(), style: TextStyle(fontFamily: mono, fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 1.0, color: statusColor)),
              ],
            ),
          ),
          if (d.state == DeviceLinkState.connected)
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Color(0xFF08150E), size: 24),
            )
          else if (d.state == DeviceLinkState.failed)
            Material(
              color: AppColors.redSoftBg,
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: app.retryScan,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), border: Border.all(color: AppColors.redSoftBorder, width: 1.5)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.sync, color: AppColors.redGlyph, size: 20),
                      SizedBox(width: 8),
                      Text('Retry', style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.redText)),
                    ],
                  ),
                ),
              ),
            )
          else
            Material(
              color: const Color(0xFF1C2620),
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: app.connectTo,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFF33413A), width: 1.5)),
                  child: const Icon(Icons.arrow_forward, color: Color(0xFFCFD9D3), size: 24),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
