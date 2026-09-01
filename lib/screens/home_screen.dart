import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/wave_bars.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tk = app.themeMode == AppThemeMode.dark ? ThemeTokens.dark : ThemeTokens.light;

    return Container(
      color: tk.bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: _DeviceChip(app: app, tk: tk),
                ),
                const SizedBox(width: 10),
                _SquareIconButton(
                  icon: Icons.settings_outlined,
                  tk: tk,
                  onTap: app.goSettings,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: _LangPairButton(app: app, tk: tk),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _TranscriptPanel(app: app, tk: tk),
            ),
          ),
          SizedBox(
            height: 64,
            child: Center(child: _StatusArea(app: app)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: _ControlRow(app: app, tk: tk),
          ),
          SizedBox(
            height: 22,
            child: !app.isRec
                ? Center(
                    child: Text(
                      'SLIDE UP TO LOCK · LONG-PRESS FOR ALERT',
                      style: TextStyle(
                        fontFamily: mono,
                        fontSize: 11,
                        letterSpacing: 1.1,
                        color: const Color(0xFF5C6862),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _DeviceChip extends StatelessWidget {
  final AppState app;
  final ThemeTokens tk;
  const _DeviceChip({required this.app, required this.tk});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tk.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: app.goPairing,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tk.cardBorder, width: 1.5),
          ),
          child: Row(
            children: [
              _SignalBars(litCount: 3, color: AppColors.green),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kPairedDeviceName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w600, fontSize: 17, color: tk.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'LINKED',
                      style: TextStyle(fontFamily: mono, fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 1.2, color: AppColors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final int litCount; // out of 4
  final Color color;
  final Color dim;
  const _SignalBars({required this.litCount, required this.color, this.dim = const Color(0xFF2C3A32)});

  @override
  Widget build(BuildContext context) {
    final heights = [7.0, 12.0, 17.0, 22.0];
    return SizedBox(
      height: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: 4,
              height: heights[i],
              decoration: BoxDecoration(
                color: i < litCount ? color : dim,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final ThemeTokens tk;
  final VoidCallback onTap;
  const _SquareIconButton({required this.icon, required this.tk, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tk.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tk.cardBorder, width: 1.5),
          ),
          child: Icon(icon, color: const Color(0xFFC8D3CC), size: 26),
        ),
      ),
    );
  }
}

class _LangPairButton extends StatelessWidget {
  final AppState app;
  final ThemeTokens tk;
  const _LangPairButton({required this.app, required this.tk});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tk.panelBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: app.openLang,
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tk.cardBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Text(app.src, style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w700, fontSize: 26, color: tk.text)),
              const SizedBox(width: 14),
              const Icon(Icons.arrow_forward, color: AppColors.amber, size: 22),
              const SizedBox(width: 14),
              Text(app.dst, style: const TextStyle(fontFamily: barlow, fontWeight: FontWeight.w700, fontSize: 26, color: AppColors.amber)),
              const Spacer(),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6F7D76), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _TranscriptPanel extends StatelessWidget {
  final AppState app;
  final ThemeTokens tk;
  const _TranscriptPanel({required this.app, required this.tk});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tk.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tk.panelBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tk.panelBorder, width: 1.5))),
            child: Row(
              children: [
                Text(
                  'TRANSCRIPT · CONFIRMATION ONLY',
                  style: TextStyle(fontFamily: mono, fontWeight: FontWeight.w500, fontSize: 10.5, letterSpacing: 1.3, color: const Color(0xFF66736C)),
                ),
                const Spacer(),
                if (app.isIncoming) const _PlayingIndicator(),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(13),
              children: [
                for (final m in app.messages) ...[
                  _MessageBubble(m: m),
                  const SizedBox(height: 11),
                ],
                if (app.isRec) _ListeningBubble(partial: app.partial.isEmpty ? '…' : app.partial),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayingIndicator extends StatefulWidget {
  const _PlayingIndicator();
  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.15).animate(_c),
          child: const _Dot(color: AppColors.amber, size: 8),
        ),
        const SizedBox(width: 6),
        const Text('PLAYING', style: TextStyle(fontFamily: mono, fontWeight: FontWeight.w600, fontSize: 10.5, letterSpacing: 1.1, color: AppColors.amber)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _MessageBubble extends StatelessWidget {
  final Message m;
  const _MessageBubble({required this.m});

  @override
  Widget build(BuildContext context) {
    final isSent = m.dir == MsgDir.sent;
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isSent)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.tag, style: const TextStyle(fontFamily: mono, fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 1.0, color: Color(0xFF5F6C65))),
                const SizedBox(width: 6),
                const Icon(Icons.check, size: 13, color: Color(0xFF5F6C65)),
              ],
            )
          else
            Text(m.tag, style: const TextStyle(fontFamily: mono, fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 1.0, color: AppColors.amber)),
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: isSent ? const Color(0xFF1C2620) : AppColors.amberSoftBg,
                border: Border.all(color: isSent ? const Color(0xFF2B3830) : AppColors.amberSoftBorder, width: 1.5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(11),
                  topRight: const Radius.circular(11),
                  bottomLeft: Radius.circular(isSent ? 11 : 3),
                  bottomRight: Radius.circular(isSent ? 3 : 11),
                ),
              ),
              child: Text(
                m.text,
                style: TextStyle(
                  fontFamily: barlow,
                  fontWeight: isSent ? FontWeight.w500 : FontWeight.w600,
                  fontSize: isSent ? 18 : 19,
                  height: 1.32,
                  color: isSent ? const Color(0xFFDFE8E2) : const Color(0xFFF6EFE0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeningBubble extends StatelessWidget {
  final String partial;
  const _ListeningBubble({required this.partial});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('LISTENING…', style: TextStyle(fontFamily: mono, fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 1.0, color: AppColors.red)),
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF241A1A),
                border: Border.all(color: AppColors.red, width: 1.5),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11), bottomLeft: Radius.circular(3), bottomRight: Radius.circular(11)),
              ),
              child: Text(partial, style: const TextStyle(fontFamily: barlow, fontWeight: FontWeight.w500, fontSize: 18, height: 1.32, color: Color(0xFFE8D8D6))),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusArea extends StatelessWidget {
  final AppState app;
  const _StatusArea({required this.app});

  @override
  Widget build(BuildContext context) {
    if (app.isRec) {
      return const WaveBars(color: AppColors.red, maxHeight: 44);
    }
    if (app.isIncoming) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF423823),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF6B562F), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.volume_up, color: AppColors.amberGlyph, size: 22),
            SizedBox(width: 10),
            Text('Replaying audio…', style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFFF6EFE0))),
          ],
        ),
      );
    }
    return const Text(
      'HOLD TO TALK',
      style: TextStyle(fontFamily: mono, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 1.6, color: Color(0xFF5C6862)),
    );
  }
}

class _ControlRow extends StatelessWidget {
  final AppState app;
  final ThemeTokens tk;
  const _ControlRow({required this.app, required this.tk});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CircleButton(
          size: 74,
          bg: tk.cardBg,
          border: const Color(0xFF2B3830),
          icon: Icons.play_arrow,
          iconColor: const Color(0xFFCFD9D3),
          onTap: app.replay,
        ),
        _PttButton(app: app),
        _CircleButton(
          size: 74,
          bg: AppColors.redSoftBg,
          border: AppColors.redSoftBorder,
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.redGlyph,
          onTap: app.beginConfirm,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final double size;
  final Color bg;
  final Color border;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  const _CircleButton({required this.size, required this.bg, required this.border, required this.icon, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: border, width: 2)),
          child: Icon(icon, color: iconColor, size: size * 0.46),
        ),
      ),
    );
  }
}

class _PttButton extends StatefulWidget {
  final AppState app;
  const _PttButton({required this.app});

  @override
  State<_PttButton> createState() => _PttButtonState();
}

class _PttButtonState extends State<_PttButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return SizedBox(
      width: 186,
      height: 186,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (app.isRec)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = _pulse.value;
                final scale = 1 + 0.55 * t;
                final opacity = (1 - t) * 0.55;
                return Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 186,
                      height: 186,
                      decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                    ),
                  ),
                );
              },
            ),
          GestureDetector(
            onTapDown: (_) => app.startRec(),
            onTapUp: (_) => app.stopRec(),
            onTapCancel: () => app.stopRec(),
            child: Container(
              width: 186,
              height: 186,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: app.isRec ? AppColors.red : AppColors.amber,
                boxShadow: const [
                  BoxShadow(color: Colors.black45, offset: Offset(0, 10)),
                ],
                border: Border.all(color: Colors.black.withValues(alpha: 0.28), width: 7),
              ),
              child: const Icon(Icons.mic, color: Color(0xFF0A0C0B), size: 78),
            ),
          ),
        ],
      ),
    );
  }
}
