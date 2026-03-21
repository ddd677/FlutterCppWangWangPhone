import 'package:flutter/material.dart';

import '../shared/ui.dart';
import 'weather_repository.dart';
import 'weather_types.dart';
import 'weather_widget_card.dart';

/// 天气详情页直接复用桌面控制器，保证桌面卡片和 App 详情的数据刷新始终一致。
class WeatherDetailPage extends StatelessWidget {
  const WeatherDetailPage({super.key, required this.controller});

  final WeatherController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final palette = HomePalette.of(context);
        final report = state.report;
        final accentColors = (report?.weatherType ?? WeatherType.sunny)
            .colorsFor(Theme.of(context).brightness);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    palette.backgroundGradient.first,
                    accentColors.first,
                    0.18,
                  )!,
                  palette.backgroundGradient[1],
                  palette.backgroundGradient.last,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -70,
                  right: -20,
                  child: AccentOrb(
                    color: accentColors.last,
                    size: 240,
                    opacity: 0.18,
                  ),
                ),
                SafeArea(
                  child: RefreshIndicator(
                    onRefresh: controller.loadWeather,
                    child: ListView(
                      key: const Key('weather_detail_scroll'),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      children: [
                        PageHeader(
                          title: '天气',
                          subtitle: report?.cityName ?? '桌面天气详情',
                          onBack: () {
                            Navigator.of(context).maybePop();
                          },
                          trailing: RoundActionButton(
                            icon: state.isLoading
                                ? null
                                : Icons.refresh_rounded,
                            progressColor: accentColors.last,
                            onTap: state.isLoading
                                ? null
                                : () {
                                    controller.loadWeather();
                                  },
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (state.isLoading && report == null)
                          const PageLoadingCard()
                        else if (state.errorMessage != null && report == null)
                          PageErrorCard(
                            message: state.errorMessage!,
                            onRetry: controller.loadWeather,
                          )
                        else if (report != null) ...[
                          _WeatherHeroCard(report: report),
                          const SizedBox(height: 18),
                          const SectionTitle(
                            title: '未来7天',
                            subtitle: '左右滑动查看每日变化',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 264,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: report.dailyForecasts.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final forecast = report.dailyForecasts[index];
                                final previousForecast = index == 0
                                    ? null
                                    : report.dailyForecasts[index - 1];

                                return SizedBox(
                                  width: 150,
                                  child: _DailyForecastCard(
                                    forecast: forecast,
                                    trend: forecast.compareTrendFrom(
                                      previousForecast,
                                    ),
                                    isToday: index == 0,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          _TemperatureTrendCard(
                            forecasts: report.dailyForecasts,
                            accentColors: accentColors,
                          ),
                          const SizedBox(height: 18),
                          const SectionTitle(
                            title: '今日细节',
                            subtitle: '基于 7timer 每日预报做展示',
                          ),
                          const SizedBox(height: 12),
                          _WeatherMetricGrid(report: report),
                          if (state.errorMessage != null) ...[
                            const SizedBox(height: 14),
                            InlineHint(message: state.errorMessage!),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeatherHeroCard extends StatelessWidget {
  const _WeatherHeroCard({required this.report});

  final WeatherReport report;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final accentColors = report.weatherType.colorsFor(
      Theme.of(context).brightness,
    );

    return FrostPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.cityName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: palette.primaryText,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '更新于 ${report.updatedLabel(DateTime.now())}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: accentColors),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentColors.last.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  report.weatherType.icon,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${report.currentTemperatureCelsius}°',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: palette.primaryText,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${report.weatherType.label} · 体感约 ${report.apparentTemperatureCelsius}°',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: palette.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '最高 ${report.highTemperatureCelsius}° / 最低 ${report.lowTemperatureCelsius}° · ${report.summary}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: palette.secondaryText,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              WeatherInfoChip(
                icon: Icons.water_drop_rounded,
                label: '湿度 ${report.humidityLabel}',
                accentColor: accentColors.first,
              ),
              WeatherInfoChip(
                icon: Icons.air_rounded,
                label: report.windLabel,
                accentColor: accentColors.last,
              ),
              WeatherInfoChip(
                icon: Icons.grain_rounded,
                label: report.precipitationLabel,
                accentColor: accentColors.first,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherMetricGrid extends StatelessWidget {
  const _WeatherMetricGrid({required this.report});

  final WeatherReport report;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricItem(
        icon: Icons.thermostat_auto_rounded,
        title: '体感参考',
        value: '${report.apparentTemperatureCelsius}°',
        subtitle: '根据湿度和风力估算',
      ),
      _MetricItem(
        icon: Icons.water_drop_rounded,
        title: '相对湿度',
        value: report.humidityLabel,
        subtitle: '数值越高越闷',
      ),
      _MetricItem(
        icon: Icons.cloud_rounded,
        title: '云量',
        value: report.cloudCoverLabel,
        subtitle: '越高说明天空越厚',
      ),
      _MetricItem(
        icon: Icons.air_rounded,
        title: '风向风速',
        value: report.windLabel,
        subtitle: '便于判断体感变化',
      ),
      _MetricItem(
        icon: Icons.umbrella_rounded,
        title: '降水',
        value: report.precipitationLabel,
        subtitle: '按 7timer 预报类型展示',
      ),
      _MetricItem(
        icon: Icons.place_rounded,
        title: '位置坐标',
        value: report.coordinateLabel,
        subtitle: report.cityName,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: cardWidth,
                  child: _WeatherMetricCard(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
}

class _WeatherMetricCard extends StatelessWidget {
  const _WeatherMetricCard({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return FrostPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: palette.primaryText, size: 22),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: palette.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: palette.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.secondaryText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyForecastCard extends StatelessWidget {
  const _DailyForecastCard({
    required this.forecast,
    required this.trend,
    required this.isToday,
  });

  final SevenTimerDailyForecast forecast;
  final TemperatureTrend trend;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final accentColors = forecast.weatherType.toWidgetWeatherType().colorsFor(
      Theme.of(context).brightness,
    );

    return FrostPanel(
      padding: const EdgeInsets.all(14),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isToday ? '今天' : forecast.weekLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColors.first.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trend.icon, size: 14, color: accentColors.last),
                    const SizedBox(width: 4),
                    Text(
                      trend.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: accentColors.last,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            forecast.dateLabel,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.secondaryText),
          ),
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: accentColors),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              forecast.weatherType.toWidgetWeatherType().icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            forecast.weatherType.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: palette.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${forecast.maxTemperature}° / ${forecast.minTemperature}°',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: palette.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            forecast.precipitationType.label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _TemperatureTrendCard extends StatelessWidget {
  const _TemperatureTrendCard({
    required this.forecasts,
    required this.accentColors,
  });

  final List<SevenTimerDailyForecast> forecasts;
  final List<Color> accentColors;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return FrostPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '温度走势',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: palette.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '用 7 日平均温度绘制趋势线，便于快速判断升温和降温。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _TemperatureTrendPainter(
                forecasts: forecasts,
                lineColor: accentColors.last,
                fillColor: accentColors.first.withValues(alpha: 0.14),
                labelColor: palette.secondaryText,
                pointColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemperatureTrendPainter extends CustomPainter {
  const _TemperatureTrendPainter({
    required this.forecasts,
    required this.lineColor,
    required this.fillColor,
    required this.labelColor,
    required this.pointColor,
  });

  final List<SevenTimerDailyForecast> forecasts;
  final Color lineColor;
  final Color fillColor;
  final Color labelColor;
  final Color pointColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (forecasts.isEmpty) {
      return;
    }

    final temperatures = forecasts
        .map((forecast) => forecast.averageTemperature.toDouble())
        .toList();
    final minTemp = temperatures.reduce(
      (value, element) => value < element ? value : element,
    );
    final maxTemp = temperatures.reduce(
      (value, element) => value > element ? value : element,
    );
    final tempRange = (maxTemp - minTemp).abs() < 1 ? 1.0 : maxTemp - minTemp;

    const horizontalPadding = 18.0;
    const topPadding = 18.0;
    const bottomPadding = 34.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartWidth = size.width - horizontalPadding * 2;
    final divisor = forecasts.length > 1 ? forecasts.length - 1 : 1;

    final points = <Offset>[];
    for (var index = 0; index < forecasts.length; index++) {
      final x = horizontalPadding + chartWidth * (index / divisor);
      final y =
          topPadding +
          chartHeight *
              (1 -
                  ((forecasts[index].averageTemperature - minTemp) /
                      tempRange));
      points.add(Offset(x, y));
    }

    final areaPath = Path()
      ..moveTo(points.first.dx, size.height - bottomPadding)
      ..lineTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      areaPath.lineTo(points[index].dx, points[index].dy);
    }
    areaPath
      ..lineTo(points.last.dx, size.height - bottomPadding)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      linePath.lineTo(points[index].dx, points[index].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      canvas.drawCircle(point, 6, Paint()..color = pointColor);
      canvas.drawCircle(point, 3.6, Paint()..color = lineColor);

      final temperaturePainter = TextPainter(
        text: TextSpan(
          text: '${forecasts[index].averageTemperature}°',
          style: TextStyle(
            color: lineColor,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      temperaturePainter.paint(
        canvas,
        Offset(point.dx - temperaturePainter.width / 2, point.dy - 24),
      );

      final dayPainter = TextPainter(
        text: TextSpan(
          text: forecasts[index].weekLabel,
          style: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      dayPainter.paint(
        canvas,
        Offset(
          point.dx - dayPainter.width / 2,
          size.height - bottomPadding + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TemperatureTrendPainter oldDelegate) {
    return oldDelegate.forecasts != forecasts ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.pointColor != pointColor;
  }
}
