import 'package:flutter/material.dart';

import '../shared/ui.dart';
import 'weather_types.dart';

class WeatherWidgetCard extends StatelessWidget {
  const WeatherWidgetCard({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onOpenDetail,
  });

  final WeatherState state;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final report = state.report;

    if (state.isLoading && report == null) {
      return const PageLoadingCard();
    }

    if (state.errorMessage != null && report == null) {
      return PageErrorCard(message: state.errorMessage!, onRetry: onRefresh);
    }

    final weather = report!;
    final accentColors = weather.weatherType.colorsFor(
      Theme.of(context).brightness,
    );

    return FrostPanel(
      padding: const EdgeInsets.all(18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onOpenDetail,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: accentColors),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: accentColors.last.withValues(alpha: 0.26),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      weather.weatherType.icon,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                weather.cityName,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: palette.primaryText,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            Text(
                              weather.updatedLabel(DateTime.now()),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.secondaryText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${weather.currentTemperatureCelsius}°',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: palette.primaryText,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.2,
                                  ),
                            ),
                            Text(
                              weather.weatherType.label,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: palette.primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${weather.highTemperatureCelsius}° / ${weather.lowTemperatureCelsius}° · ${weather.summary}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: palette.secondaryText,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: WeatherInfoChip(
                      icon: Icons.thermostat_rounded,
                      label: weather.feelsLikeLabel,
                      accentColor: accentColors.first,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: WeatherInfoChip(
                      icon: Icons.touch_app_rounded,
                      label: '点击查看详情',
                      accentColor: accentColors.last,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: state.isLoading
                          ? null
                          : () {
                              onRefresh();
                            },
                      child: Ink(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: palette.chipBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.borderColor),
                        ),
                        child: state.isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accentColors.last,
                                ),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                color: palette.primaryText,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 10),
                InlineHint(message: state.errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WeatherInfoChip extends StatelessWidget {
  const WeatherInfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.chipBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
