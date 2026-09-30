import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/bluetooth_manager.dart';
import '../theme.dart';
import 'alert_history_screen.dart';

/// Matches the reference design's "Broadcast" screen. Presets fill the
/// message text — nothing is auto-sent or fabricated — and "Broadcast"
/// sends it through the same real recognize/translate/send pipeline as a
/// typed message. No fake device-reach counts: since iTantra has one direct
/// connection, delivery is shown as sent/delivered on the message itself
/// (back on the Conversation screen), matching what's actually knowable.
class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _controller = TextEditingController();
  String? _selectedPreset;
  String? _preview;
  bool _previewing = false;

  static const _presets = [
    ('Emergency', Icons.warning_amber_rounded, 'This is an emergency — I need immediate help.'),
    ('Need Help', Icons.pan_tool_alt_outlined, 'I need help.'),
    ('Information', Icons.info_outline, 'Important update: '),
    ("I'm Safe", Icons.check_circle_outline, 'I am safe.'),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _preview = null);
    });
  }

  Future<void> _showPreview() async {
    final app = context.read<AppState>();
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _previewing = true);
    final translated = await app.previewTranslation(text);
    if (!mounted) return;
    setState(() {
      _preview = translated;
      _previewing = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPreset(String label, String text) {
    setState(() {
      _selectedPreset = label;
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    });
  }

  void _send() {
    final app = context.read<AppState>();
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_selectedPreset == 'Emergency') {
      app.triggerEmergency();
    } else {
      app.sendTypedMessage(text);
    }
    setState(() {
      _controller.clear();
      _selectedPreset = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast sent'), duration: Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothManager>();
    final connected = bt.connectedDevice != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Broadcast', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w800, fontSize: 28, color: AppColors.textPrimary))),
                  Material(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(100),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertHistoryScreen())),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history, size: 15, color: AppColors.accent),
                            SizedBox(width: 6),
                            Text('History', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.accent)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                connected ? "Send an important message to the device you're connected to." : 'Connect a device from Home to send a broadcast.',
                style: TextStyle(fontFamily: appFont, fontSize: 13, color: AppColors.textSecondary(0.55)),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 90),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(0.12))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines: 4,
                        minLines: 2,
                        style: const TextStyle(fontFamily: appFont, fontSize: 14.5, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: "I'm trapped near the railway station and need assistance.",
                          hintStyle: TextStyle(fontFamily: appFont, fontSize: 14, color: AppColors.textSecondary(0.35)),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                    if (_controller.text.trim().isNotEmpty) ...[
                      IconButton(
                        onPressed: () => context.read<AppState>().speakPreview(_controller.text),
                        tooltip: 'Hear it spoken',
                        icon: const Icon(Icons.volume_up, size: 18, color: AppColors.accent),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(left: 6),
                      ),
                      IconButton(
                        onPressed: _previewing ? null : _showPreview,
                        tooltip: 'Preview translation',
                        icon: _previewing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                            : const Icon(Icons.translate, size: 18, color: AppColors.accent),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(left: 6),
                      ),
                    ],
                  ],
                ),
              ),
              if (_preview != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.translate, size: 14, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _preview!,
                            style: const TextStyle(fontFamily: appFont, fontSize: 13.5, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final p in _presets)
                    _PresetButton(
                      icon: p.$2,
                      label: p.$1,
                      selected: _selectedPreset == p.$1,
                      danger: p.$1 == 'Emergency',
                      onTap: () => _selectPreset(p.$1, p.$3),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary(0.45)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sent directly over Bluetooth to your connected device — translated automatically.',
                      style: TextStyle(fontFamily: appFont, fontSize: 11.5, color: AppColors.textSecondary(0.5)),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: connected ? AppColors.accent : AppColors.border(0.15),
                  borderRadius: BorderRadius.circular(100),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: connected ? _send : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign_outlined, size: 18, color: connected ? Colors.white : AppColors.textSecondary(0.4)),
                          const SizedBox(width: 8),
                          Text('Broadcast', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 15, color: connected ? Colors.white : AppColors.textSecondary(0.4))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;
  const _PresetButton({required this.icon, required this.label, required this.selected, required this.danger, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.accent;
    return Material(
      color: selected ? color.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? color : AppColors.border(0.12))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontFamily: appFont, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
