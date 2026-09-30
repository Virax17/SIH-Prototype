import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../services/bluetooth_manager.dart';
import '../theme.dart';
import '../widgets/wave_bars.dart';
import 'network_screen.dart';

/// Matches the reference design's "Conversation" screen: header with the
/// peer device, the message thread, a live pipeline stepper while a
/// recording is being processed, and the PTT button. iTantra has one active
/// connection, so this always represents "the conversation with whichever
/// device is currently connected" — if it drops, the header reflects that.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _typedFocusNode = FocusNode();

  @override
  void dispose() {
    _typedFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final bt = context.watch<BluetoothManager>();
    final connected = bt.connectedDevice;
    final playing = app.playingMessage;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border(0.08)))),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary)),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        connected != null && connected.displayName.isNotEmpty ? connected.displayName.substring(0, 1).toUpperCase() : '?',
                        style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(connected?.displayName ?? 'Not connected', overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                        Row(
                          children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: connected != null ? AppColors.success : AppColors.textSecondary(0.35))),
                            const SizedBox(width: 5),
                            Text(connected != null ? 'Connected' : 'Disconnected', style: TextStyle(fontFamily: appFont, fontSize: 12, fontWeight: FontWeight.w600, color: connected != null ? AppColors.success : AppColors.textSecondary(0.5))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(100),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: app.openLangSheet,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(app.langMine.latinName, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 11.5, color: AppColors.accent)),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward, size: 12, color: AppColors.accent)),
                            Text(app.langTheirs.latinName, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 11.5, color: AppColors.accent)),
                          ],
                        ),
                      ),
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
              child: app.messages.isEmpty
                  ? Center(
                      child: Text('No messages yet — hold the mic to talk.', style: TextStyle(fontFamily: appFont, fontSize: 13, color: AppColors.textSecondary(0.4))),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [for (final m in app.messages) _MessageBubble(m: m)],
                    ),
            ),
            _TypedMessageBar(focusNode: _typedFocusNode),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border(0.06)))),
              child: Column(
                children: [
                  _ActionRow(
                    onMesh: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NetworkScreen())),
                    onText: () => _typedFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 10),
                  if (app.pipelineStage != PipelineStage.idle) _PipelineStepper(stage: app.pipelineStage),
                  if (app.recording && app.partialTranscript.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        app.partialTranscript,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: appFont, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                  Text(
                    _pttLabel(app.pipelineStage),
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
      ),
    );
  }

  String _pttLabel(PipelineStage stage) {
    switch (stage) {
      case PipelineStage.idle:
        return 'Hold to talk';
      case PipelineStage.listening:
        return 'Recording — release to send';
      case PipelineStage.understanding:
        return 'Understanding…';
      case PipelineStage.sending:
        return 'Sending…';
    }
  }
}

/// Matches the reference design's Speak/Text/Mesh row above the PTT button.
/// "Speak" labels the PTT button below (the primary input); "Text" focuses
/// the typed-message field; "Mesh" opens the real network view.
class _ActionRow extends StatelessWidget {
  final VoidCallback onMesh;
  final VoidCallback onText;
  const _ActionRow({required this.onMesh, required this.onText});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionIcon(icon: Icons.mic, label: 'Speak', active: true, onTap: () {}),
        _ActionIcon(icon: Icons.short_text, label: 'Text', active: false, onTap: onText),
        _ActionIcon(icon: Icons.hub_outlined, label: 'Mesh', active: false, onTap: onMesh),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textSecondary(0.5);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: active ? AppColors.accentSoft : Colors.transparent, shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontFamily: appFont, fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Live Listening → Understanding → Sending stepper over the real STT → MT
/// → Bluetooth-send pipeline (see `AppState.pipelineStage`) — not a fixed
/// animation, each step lights up only once that stage actually starts.
class _PipelineStepper extends StatelessWidget {
  final PipelineStage stage;
  const _PipelineStepper({required this.stage});

  static const _steps = [
    (PipelineStage.listening, Icons.mic, 'Listening'),
    (PipelineStage.understanding, Icons.translate, 'Understanding'),
    (PipelineStage.sending, Icons.send, 'Sending'),
  ];

  @override
  Widget build(BuildContext context) {
    final activeIdx = _steps.indexWhere((s) => s.$1 == stage);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            if (i > 0) Container(width: 20, height: 1.5, color: i <= activeIdx ? AppColors.success.withValues(alpha: 0.5) : AppColors.border(0.12)),
            _StepDot(icon: _steps[i].$2, label: _steps[i].$3, state: i < activeIdx ? _StepState.done : (i == activeIdx ? _StepState.active : _StepState.pending)),
          ],
        ],
      ),
    );
  }
}

enum _StepState { pending, active, done }

class _StepDot extends StatelessWidget {
  final IconData icon;
  final String label;
  final _StepState state;
  const _StepDot({required this.icon, required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.done => AppColors.success,
      _StepState.active => AppColors.accent,
      _StepState.pending => AppColors.border(0.18),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(shape: BoxShape.circle, color: state == _StepState.pending ? Colors.transparent : color, border: Border.all(color: color, width: 1.5)),
          child: Icon(state == _StepState.done ? Icons.check : icon, size: 13, color: state == _StepState.pending ? color : Colors.white),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontFamily: appFont, fontSize: 9.5, fontWeight: FontWeight.w600, color: state == _StepState.pending ? AppColors.textSecondary(0.35) : AppColors.textPrimary)),
      ],
    );
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

/// Shows which language a message is actually in, and — since TTS voice
/// selection (`AppState._tts.speak(text, lang)`) uses this exact same
/// [Message.lang] — confirms the voice that will speak it.
class _LangBadge extends StatelessWidget {
  final LangCode lang;
  final bool onDark;
  const _LangBadge({required this.lang, required this.onDark});

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white.withValues(alpha: 0.9) : AppColors.accent;
    final bg = onDark ? Colors.white.withValues(alpha: 0.18) : AppColors.accentSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.volume_up, size: 9, color: fg),
          const SizedBox(width: 3),
          Text(
            lang.latinName,
            style: TextStyle(fontFamily: appFont, fontSize: 9, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
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
    final primary = m.text;

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
                    const SizedBox(width: 6),
                    _LangBadge(lang: m.lang, onDark: sent),
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
                if (sent && m.delivery != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          m.delivery == DeliveryStatus.delivered ? Icons.done_all : Icons.schedule,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          m.delivery == DeliveryStatus.delivered ? 'Delivered' : 'Sending…',
                          style: TextStyle(fontFamily: appFont, fontSize: 10.5, color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ],
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
  final FocusNode focusNode;
  const _TypedMessageBar({required this.focusNode});

  @override
  State<_TypedMessageBar> createState() => _TypedMessageBarState();
}

class _TypedMessageBarState extends State<_TypedMessageBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final app = context.read<AppState>();
    app.sendTypedMessage(_controller.text);
    _controller.clear();
  }

  void _speakPreview() {
    context.read<AppState>().speakPreview(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.border(0.12))),
              child: TextField(
                controller: _controller,
                focusNode: widget.focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: const TextStyle(fontFamily: appFont, fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(fontFamily: appFont, fontSize: 14, color: AppColors.textSecondary(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: _hasText
                      ? IconButton(
                          onPressed: _speakPreview,
                          tooltip: 'Hear it spoken',
                          icon: const Icon(Icons.volume_up, size: 18, color: AppColors.accent),
                        )
                      : null,
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
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _PttButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  // Only spend animation-tick battery/CPU while actually recording and
  // pulsing is shown at all — Emergency Mode turns this decorative ring off
  // entirely, a real (if small) reduction in background activity.
  void _syncPulse() {
    final shouldRun = widget.app.recording && !widget.app.emergencyMode;
    if (shouldRun && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!shouldRun && _pulse.isAnimating) {
      _pulse.stop();
    }
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
          if (app.recording && !app.emergencyMode) ...[
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
