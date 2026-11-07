import 'package:flutter/material.dart';

import '../data/game_state.dart';

const playerColors = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFFFDD835),
  Color(0xFF8E24AA),
  Color(0xFFFB8C00),
  Color(0xFF00ACC1),
  Color(0xFFEC407A),
  Color(0xFF7CB342),
];

/// Running total per player after each round (starting at 0).
class ProgressChart extends StatelessWidget {
  const ProgressChart({super.key, required this.view});
  final GameView view;

  @override
  Widget build(BuildContext context) {
    final ids = view.config.participants;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: CustomPaint(
            painter: _ChartPainter(
              series: [
                for (final p in ids)
                  [
                    0,
                    for (var i = 0; i < view.cumulative.length; i++)
                      if (view.roundComplete[i]) view.cumulative[i][p]!,
                  ],
              ],
              axisColor: cs.outline,
              textColor: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            for (var i = 0; i < ids.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: playerColors[i % playerColors.length],
                  ),
                  const SizedBox(width: 6),
                  Text(view.nameOf(ids[i])),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.series,
    required this.axisColor,
    required this.textColor,
  });

  final List<List<int>> series;
  final Color axisColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 40.0, bottom = 20.0, pad = 8.0;
    final all = series.expand((s) => s);
    var lo = all.fold<int>(0, (a, b) => b < a ? b : a);
    var hi = all.fold<int>(0, (a, b) => b > a ? b : a);
    if (hi == lo) hi = lo + 1;
    final rounds = series.first.length - 1;
    final w = size.width - left - pad, h = size.height - bottom - pad;

    double x(int i) => left + (rounds == 0 ? 0 : w * i / rounds);
    double y(int v) => pad + h * (1 - (v - lo) / (hi - lo));

    final axis = Paint()
      ..color = axisColor.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(left, y(0)), Offset(size.width - pad, y(0)), axis);
    canvas.drawLine(Offset(left, pad), Offset(left, pad + h), axis);

    void label(String text, Offset at) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: 11, color: textColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
    }

    label('$hi', Offset(left / 2, y(hi)));
    if (lo < 0) label('$lo', Offset(left / 2, y(lo)));
    label('0', Offset(left / 2, y(0)));
    label('1', Offset(x(1), size.height - bottom / 2));
    if (rounds > 1) {
      label('$rounds', Offset(x(rounds), size.height - bottom / 2));
    }

    for (var s = 0; s < series.length; s++) {
      final paint = Paint()
        ..color = playerColors[s % playerColors.length]
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final path = Path()..moveTo(x(0), y(series[s][0]));
      for (var i = 1; i < series[s].length; i++) {
        path.lineTo(x(i), y(series[s][i]));
      }
      canvas.drawPath(path, paint);
      canvas.drawCircle(
        Offset(x(rounds), y(series[s].last)),
        4,
        paint..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => true;
}
