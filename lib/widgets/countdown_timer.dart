import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endsAt;
  final VoidCallback? onFinished;
  final bool compact;

  const CountdownTimer({
    super.key,
    required this.endsAt,
    this.onFinished,
    this.compact = false,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  late Duration _remaining;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt) {
      _notified = false;
      _updateRemaining();
    }
  }

  void _updateRemaining() {
    final diff = widget.endsAt.difference(DateTime.now());
    if (!mounted) return;
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
    if (_remaining == Duration.zero && !_notified) {
      _notified = true;
      widget.onFinished?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hours = d.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _remaining == Duration.zero;
    final color = isDone
        ? ProtocoloZColors.radarGreen
        : ProtocoloZColors.textPrimary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 10 : 14,
        vertical: widget.compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: ProtocoloZColors.bgDarkest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDone
              ? ProtocoloZColors.radarGreen
              : ProtocoloZColors.borderGray,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.timer_rounded,
            size: widget.compact ? 16 : 20,
            color: ProtocoloZColors.radarGreen,
          ),
          const SizedBox(width: 8),
          Text(
            isDone ? 'PRONTA PARA COLETA!' : _formatDuration(_remaining),
            style: TextStyle(
              fontSize: widget.compact ? 13 : 16,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
