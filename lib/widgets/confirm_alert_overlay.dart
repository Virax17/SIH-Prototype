import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme.dart';

class ConfirmAlertOverlay extends StatelessWidget {
  const ConfirmAlertOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Container(
      color: const Color(0xFF050706).withValues(alpha: 0.92),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'SENDING PRIORITY ALERT',
            style: TextStyle(fontFamily: mono, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 1.6, color: AppColors.redGlyph),
          ),
          const SizedBox(height: 22),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.redDeep, width: 6)),
            child: Center(
              child: Text('${app.countdown}', style: const TextStyle(fontFamily: barlow, fontWeight: FontWeight.w800, fontSize: 52, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Broadcasts at max volume to $kPairedDeviceName. Cannot be recalled once sent.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: barlow, fontWeight: FontWeight.w500, fontSize: 15, height: 1.4, color: Color(0xFFCFD9D3)),
          ),
          const SizedBox(height: 22),
          Material(
            color: const Color(0xFF1C2620),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: app.cancelConfirm,
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF33413A), width: 2)),
                child: const Center(child: Text('CANCEL', style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFFEDF2EE)))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
