import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/constants.dart';
import 'package:selfcheckoutapp/utils/app_utils.dart';

class ChartData {
  final String label;
  final double value;
  final Color? color;

  ChartData({
    required this.label,
    required this.value,
    this.color,
  });
}

class PieChartWidget extends StatelessWidget {
  final List<ChartData> data;
  final double? size;
  final double strokeWidth;
  final bool showLabels;
  final bool showLegend;
  final TextStyle? labelStyle;
  final EdgeInsets? padding;

  const PieChartWidget({
    required this.data,
    this.size,
    this.strokeWidth = 2.0,
    this.showLabels = true,
    this.showLegend = true,
    this.labelStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final chartSize = size ?? 200.0;
    final total = data.fold(0.0, (sum, item) => sum + item.value);
    
    return Container(
      padding: padding,
      child: Column(
        children: [
          SizedBox(
            width: chartSize,
            height: chartSize,
            child: CustomPaint(
              painter: PieChartPainter(
                data: data,
                strokeWidth: strokeWidth,
                showLabels: showLabels,
                labelStyle: labelStyle ?? Constants.smallText,
              ),
            ),
          ),
          if (showLegend) ...[
            SizedBox(height: 16),
            _buildLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: data.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color ?? AppUtils.getRandomColor(),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6),
            Text(
              '${item.label} (${(item.value / total * 100).toStringAsFixed(1)}%)',
              style: Constants.smallText,
            ),
          ],
        );
      }).toList(),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<ChartData> data;
  final double strokeWidth;
  final bool showLabels;
  final TextStyle labelStyle;

  PieChartPainter({
    required this.data,
    required this.strokeWidth,
    required this.showLabels,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;
    
    final total = data.fold(0.0, (sum, item) => sum + item.value);
    double startAngle = -math.pi / 2;

    for (final item in data) {
      final sweepAngle = (item.value / total) * 2 * math.pi;
      final color = item.color ?? AppUtils.getRandomColor();

      // Draw pie slice
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw labels
      if (showLabels && item.value > 0) {
        final labelAngle = startAngle + sweepAngle / 2;
        final labelRadius = radius * 0.7;
        final labelX = center.dx + math.cos(labelAngle) * labelRadius;
        final labelY = center.dy + math.sin(labelAngle) * labelRadius;

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${(item.value / total * 100).toStringAsFixed(0)}%',
            style: labelStyle.copyWith(color: Colors.white),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            labelX - textPainter.width / 2,
            labelY - textPainter.height / 2,
          ),
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarChartWidget extends StatelessWidget {
  final List<ChartData> data;
  final double? height;
  final double barWidth;
  final Color? barColor;
  final bool showValues;
  final bool showGridLines;
  final TextStyle? valueStyle;
  final EdgeInsets? padding;

  const BarChartWidget({
    required this.data,
    this.height = 200,
    this.barWidth = 40,
    this.barColor,
    this.showValues = true,
    this.showGridLines = true,
    this.valueStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: height,
        child: Center(
          child: Text(
            'No data available',
            style: Constants.regularText.copyWith(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: padding,
      child: CustomPaint(
        painter: BarChartPainter(
          data: data,
          barWidth: barWidth,
          barColor: barColor,
          showValues: showValues,
          showGridLines: showGridLines,
          valueStyle: valueStyle ?? Constants.smallText,
        ),
      ),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<ChartData> data;
  final double barWidth;
  final Color? barColor;
  final bool showValues;
  final bool showGridLines;
  final TextStyle valueStyle;

  BarChartPainter({
    required this.data,
    required this.barWidth,
    this.barColor,
    required this.showValues,
    required this.showGridLines,
    required this.valueStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final maxValue = data.map((item) => item.value).reduce(math.max);
    final chartHeight = size.height - 40; // Leave space for labels
    final chartWidth = size.width;
    final barSpacing = (chartWidth - (data.length * barWidth)) / (data.length + 1);

    // Draw grid lines
    if (showGridLines) {
      final gridPaint = Paint()
        ..color = Colors.grey[300]!
        ..strokeWidth = 0.5;

      for (int i = 0; i <= 5; i++) {
        final y = (chartHeight / 5) * i;
        canvas.drawLine(
          Offset(0, y),
          Offset(chartWidth, y),
          gridPaint,
        );
      }
    }

    // Draw bars
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final barHeight = (item.value / maxValue) * chartHeight;
      final x = barSpacing + (i * (barWidth + barSpacing));
      final y = chartHeight - barHeight;

      // Draw bar
      paint.color = item.color ?? barColor ?? Constants.primaryColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          Radius.circular(4),
        ),
        paint,
      );

      // Draw value label
      if (showValues) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: item.value.toStringAsFixed(0),
            style: valueStyle,
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            x + (barWidth - textPainter.width) / 2,
            y - textPainter.height - 4,
          ),
        );
      }

      // Draw label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: Constants.smallText,
        ),
        textDirection: TextDirection.ltr,
      );

      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          x + (barWidth - labelPainter.width) / 2,
          chartHeight + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LineChartWidget extends StatelessWidget {
  final List<ChartData> data;
  final double? height;
  final Color? lineColor;
  final Color? pointColor;
  final double lineWidth;
  final double pointRadius;
  final bool showPoints;
  final bool showGridLines;
  final bool showArea;
  final TextStyle? labelStyle;
  final EdgeInsets? padding;

  const LineChartWidget({
    required this.data,
    this.height = 200,
    this.lineColor,
    this.pointColor,
    this.lineWidth = 2.0,
    this.pointRadius = 4.0,
    this.showPoints = true,
    this.showGridLines = true,
    this.showArea = false,
    this.labelStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: height,
        child: Center(
          child: Text(
            'No data available',
            style: Constants.regularText.copyWith(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: padding,
      child: CustomPaint(
        painter: LineChartPainter(
          data: data,
          lineColor: lineColor,
          pointColor: pointColor,
          lineWidth: lineWidth,
          pointRadius: pointRadius,
          showPoints: showPoints,
          showGridLines: showGridLines,
          showArea: showArea,
          labelStyle: labelStyle ?? Constants.smallText,
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<ChartData> data;
  final Color? lineColor;
  final Color? pointColor;
  final double lineWidth;
  final double pointRadius;
  final bool showPoints;
  final bool showGridLines;
  final bool showArea;
  final TextStyle labelStyle;

  LineChartPainter({
    required this.data,
    this.lineColor,
    this.pointColor,
    required this.lineWidth,
    required this.pointRadius,
    required this.showPoints,
    required this.showGridLines,
    required this.showArea,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final maxValue = data.map((item) => item.value).reduce(math.max);
    final chartHeight = size.height - 40;
    final chartWidth = size.width;
    final pointSpacing = chartWidth / (data.length - 1);

    // Draw grid lines
    if (showGridLines) {
      final gridPaint = Paint()
        ..color = Colors.grey[300]!
        ..strokeWidth = 0.5;

      for (int i = 0; i <= 5; i++) {
        final y = (chartHeight / 5) * i;
        canvas.drawLine(
          Offset(0, y),
          Offset(chartWidth, y),
          gridPaint,
        );
      }
    }

    // Create path for line
    final path = Path();
    final areaPath = Path();

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final x = i * pointSpacing;
      final y = chartHeight - (item.value / maxValue) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
        areaPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }

    // Draw area
    if (showArea) {
      areaPath.lineTo(chartWidth, chartHeight);
      areaPath.lineTo(0, chartHeight);
      areaPath.close();

      final areaPaint = Paint()
        ..color = (lineColor ?? Constants.primaryColor).withOpacity(0.1)
        ..style = PaintingStyle.fill;

      canvas.drawPath(areaPath, areaPaint);
    }

    // Draw line
    paint
      ..color = lineColor ?? Constants.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    // Draw points
    if (showPoints) {
      for (int i = 0; i < data.length; i++) {
        final item = data[i];
        final x = i * pointSpacing;
        final y = chartHeight - (item.value / maxValue) * chartHeight;

        paint
          ..color = pointColor ?? lineColor ?? Constants.primaryColor
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), pointRadius, paint);

        // Draw value label
        final textPainter = TextPainter(
          text: TextSpan(
            text: item.value.toStringAsFixed(1),
            style: labelStyle,
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            x - textPainter.width / 2,
            y - textPainter.height - pointRadius - 4,
          ),
        );

        // Draw x-axis label
        final labelPainter = TextPainter(
          text: TextSpan(
            text: item.label,
            style: Constants.smallText,
          ),
          textDirection: TextDirection.ltr,
        );

        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(
            x - labelPainter.width / 2,
            chartHeight + 8,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ProgressRingWidget extends StatelessWidget {
  final double progress;
  final double? size;
  final Color? backgroundColor;
  final Color? progressColor;
  final double strokeWidth;
  final bool showPercentage;
  final TextStyle? percentageStyle;
  final String? label;
  final TextStyle? labelStyle;

  const ProgressRingWidget({
    required this.progress,
    this.size = 100,
    this.backgroundColor,
    this.progressColor,
    this.strokeWidth = 8.0,
    this.showPercentage = true,
    this.percentageStyle,
    this.label,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            painter: ProgressRingPainter(
              progress: progress.clamp(0.0, 1.0),
              backgroundColor: backgroundColor ?? Colors.grey[300]!,
              progressColor: progressColor ?? Constants.primaryColor,
              strokeWidth: strokeWidth,
            ),
          ),
          if (showPercentage || label != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showPercentage)
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: percentageStyle ?? 
                          Constants.boldText.copyWith(fontSize: size! * 0.2),
                    ),
                  if (label != null) ...[
                    SizedBox(height: 4),
                    Text(
                      label!,
                      style: labelStyle ?? 
                          Constants.smallText.copyWith(fontSize: size! * 0.12),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    // Draw background ring
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress ring
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2;
    final sweepAngle = progress * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color? color;
  final IconData? icon;
  final double? progress;
  final bool showProgress;

  const StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.color,
    this.icon,
    this.progress,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: color ?? Constants.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Constants.regularText.copyWith(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: Constants.boldText.copyWith(
                fontSize: 24,
                color: color ?? Constants.primaryColor,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4),
              Text(
                subtitle!,
                style: Constants.smallText.copyWith(color: Colors.grey[600]),
              ),
            ],
            if (showProgress && progress != null) ...[
              SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Constants.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Import math library for calculations
import 'dart:math' as math;
