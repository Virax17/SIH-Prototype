import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../services/bluetooth_manager.dart';
import '../theme.dart';
import '../widgets/wave_bars.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final bt = context.watch<BluetoothManager>();
    final connected = bt.connectedDevice;
    final playing = app.playingMessage;

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border(0.08)))),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => app.setTab(AppTab.devices),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: connected != null ? AppColors.success : const Color(0xFFB9B9B4)),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                connected?.displayName ?? 'No device paired',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.textPrimary),
                              ),
                              Text(
                                connected != null ? 'Connected' : 'Not connected',
                                style: TextStyle(fontFamily: appFont, fontSize: 11, color: AppColors.textSecondary(0.5)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(100),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: app.openLangSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(app.langMine.latinName, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.accent)),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 14, color: AppColors.accent)),
                          Text(app.langTheirs.latinName, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.accent)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Material(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: app.triggerEmergency,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.campaign_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Emergency Broadcast', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white, letterSpacing: 0.2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: app.toggleScriptMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.border(0.12))),
                    child: Text('Text: ${_scriptModeLabel(app.scriptMode)}', style: TextStyle(fontFamily: appFont, fontSize: 11, color: AppColors.textSecondary(0.45))),
                  ),
                ),
              ],
            ),
          ),
          if (playing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accent.withValues(alpha: 0.25))),
                child: Row(
                  children: [
                    const _PulsingIcon(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Playing message from ${connected?.displayName ?? 'device'}',
                        style: const TextStyle(fontFamily: appFont, fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                    ),
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => app.replay(playing.id),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.refresh, size: 14, color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [for (final m in app.messages) _MessageBubble(m: m)],
            ),
          ),
          const _TypedMessageBar(),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border(0.06)))),
            child: Column(
              children: [
                Text(
                  app.recording ? 'Recording — release to send' : 'Hold to talk',
                  style: TextStyle(fontFamily: appFont, fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary(0.5)),
                ),
                const SizedBox(height: 8),
                _PttButton(app: app),
                const SizedBox(height: 8),
                SizedBox(
                  height: 16,
                  child: app.recording ? const WaveBars(color: AppColors.accent, barCount: 5, barWidth: 3, maxHeight: 16) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _scriptModeLabel(ScriptMode m) {
    switch (m) {
      case ScriptMode.both:
        return 'Both';
      case ScriptMode.native:
        return 'Native script';
      case ScriptMode.latin:
        return 'Latin script';
    }
  }
}

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon();
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
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
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.35).animate(_c),
      child: const Icon(Icons.volume_up, size: 18, color: AppColors.accent),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message m;
  const _MessageBubble({required this.m});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final sent = m.dir == MsgDir.sent;

    String primary;
    String? secondary;
    if (m.customText != null) {
      primary = m.customText!;
      secondary = null;
    } else {
      final phrase = app.phraseFor(m.phraseIdx, m.lang);
      final showBoth = app.scriptMode == ScriptMode.both && m.lang != LangCode.en;
      final showLatinOnly = app.scriptMode == ScriptMode.latin && m.lang != LangCode.en;
      primary = showLatinOnly ? phrase.latin : phrase.native;
      secondary = showBoth ? phrase.latin : null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: sent ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: sent ? AppColors.accent : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: sent ? null : Border.all(color: AppColors.border(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sent ? Icons.mic : Icons.volume_up,
                      size: 12,
                      color: sent ? Colors.white : AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sent ? 'YOU' : 'THEM',
                      style: TextStyle(
                        fontFamily: appFont,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                        letterSpacing: 0.4,
                        color: sent ? Colors.white.withValues(alpha: 0.75) : AppColors.textSecondary(0.45),
                      ),
                    ),
                    if (!sent) ...[
                      const SizedBox(width: 10),
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => app.replay(m.id),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                          child: Icon(m.playing ? Icons.volume_up : Icons.play_arrow, size: 12, color: AppColors.accent),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  primary,
                  style: TextStyle(
                    fontFamily: m.lang.glyphFontFamily ?? appFont,
                    fontSize: 14.5,
                    height: 1.35,
                    color: sent ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (secondary != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      secondary,
                      style: TextStyle(
                        fontFamily: appFont,
                        fontSize: 12,
                        height: 1.3,
                        fontStyle: FontStyle.italic,
                        color: sent ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary(0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypedMessageBar extends StatefulWidget {
  const _TypedMessageBar();

  @override
  State<_TypedMessageBar> createState() => _TypedMessageBarState();
}

class _TypedMessageBarState extends State<_TypedMessageBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final app = context.read<AppState>();
    app.sendTypedMessage(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.border(0.12))),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: const TextStyle(fontFamily: appFont, fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(fontFamily: appFont, fontSize: 14, color: AppColors.textSecondary(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _send,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_upward, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
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
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
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
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (app.recording) ...[
            _PulseRing(controller: _pulse, delay: 0),
            _PulseRing(controller: _pulse, delay: 0.36),
          ],
          GestureDetector(
            onTapDown: (_) => app.startRecording(),
            onTapUp: (_) => app.stopRecording(),
            onTapCancel: () => app.stopRecording(),
            child: AnimatedScale(
              scale: app.recording ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: app.recording ? AppColors.accentDark : AppColors.accent,
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 34),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  const _PulseRing({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = (controller.value + delay) % 1.0;
        final scale = 1 + 0.9 * t;
        final opacity = (0.45 * (1 - t)).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(width: 104, height: 104, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
          ),
        );
      },
    );
  }
}
