import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'device_model.dart';

class WashHistoryChart extends StatelessWidget {
  final List<WashCycle> history;
  final bool isDark;

  const WashHistoryChart({
    super.key,
    required this.history,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          "No diagnostic history available.",
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      );
    }

    // Sort and limit to 7 cycles
    final sortedHistory = List<WashCycle>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));
    final recentHistory = sortedHistory.length > 7
        ? sortedHistory.sublist(sortedHistory.length - 7)
        : sortedHistory;

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BarChartPainter(
            history: recentHistory,
            isDark: isDark,
            primaryColor: isDark ? Colors.purple.shade300 : Colors.deepPurple,
            secondaryColor: isDark ? Colors.indigo.shade300 : Colors.indigo,
          ),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<WashCycle> history;
  final bool isDark;
  final Color primaryColor;
  final Color secondaryColor;

  _BarChartPainter({
    required this.history,
    required this.isDark,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double paddingLeft = 35.0;
    final double paddingBottom = 25.0;
    final double paddingTop = 10.0;
    final double paddingRight = 10.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    final Paint axisPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black12
      ..strokeWidth = 1.0;

    final double maxY = 100.0; // Health Severity Percentage

    // Draw horizontal grid lines
    final healthLabels = ["0%", "Healthy", "Warning", "Critical", "100%"];
    for (int i = 0; i <= 4; i++) {
      double y = paddingTop + chartHeight - (chartHeight * i / 4);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        axisPaint,
      );

      // Draw Y labels (Health States)
      final textPainter = TextPainter(
        text: TextSpan(
          text: healthLabels[i],
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 9,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
          canvas, Offset(paddingLeft - textPainter.width - 5, y - textPainter.height / 2));
    }

    // Draw bars
    final double barSpacing = chartWidth / history.length;
    final double barWidth = barSpacing * 0.5;

    for (int i = 0; i < history.length; i++) {
      final cycle = history[i];
      final double x = paddingLeft + (i * barSpacing) + (barSpacing - barWidth) / 2;
      
      // Calculate severity height based on status
      double severity = 45.0; // Normal - boosted baseline for visibility
      Color barColor = Colors.green;
      
      if (cycle.status == DeviceStatus.earlyWarning) {
        severity = 65.0;
        barColor = Colors.orange;
      } else if (cycle.status == DeviceStatus.failureDetected || cycle.status == DeviceStatus.maintenanceRequired) {
        severity = 100.0;
        barColor = Colors.redAccent;
      }

      final double barHeight = (severity / maxY) * chartHeight;
      final double y = paddingTop + chartHeight - barHeight;

      final RRect barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );

      final Paint barPaint = Paint()..color = barColor.withAlpha(200);

      canvas.drawRRect(barRect, barPaint);

      // Draw X labels (Date)
      final labelPainter = TextPainter(
        text: TextSpan(
          text: DateFormat('d/M').format(cycle.date),
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 10,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      labelPainter.paint(
          canvas,
          Offset(x + (barWidth - labelPainter.width) / 2,
              paddingTop + chartHeight + 5));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.history != history || oldDelegate.isDark != isDark;
}
