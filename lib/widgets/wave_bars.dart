import 'dart:math';
import 'package:flutter/material.dart';

class WaveBars extends StatefulWidget {
  final Color color;
  final int barCount;
  final double barWidth;
  final double maxHeight;

  const WaveBars({
    super.key,
    required this.color,
    this.barCount = 13,
    this.barWidth = 6,
    this.maxHeight = 44,
  });

  @override
  State<WaveBars> createState() => _WaveBarsState();
}

class _WaveBarsState extends State<WaveBars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 720))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.barCount, (i) {
        final phase = (i * 0.06) / 0.72;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = (_controller.value + phase) % 1.0;
              final h = 0.12 + 0.88 * sin(t * pi).abs();
              return Container(
                width: widget.barWidth,
                height: widget.maxHeight * h,
                decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(widget.barWidth / 2)),
              );
            },
          ),
        );
      }),
    );
  }
}
