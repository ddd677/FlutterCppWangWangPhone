import 'package:flutter/material.dart';

class WeatherReport {
  const WeatherReport({
    required this.location,
    required this.updatedAt,
    required this.dailyForecasts,
  });

  final WeatherLocationConfig location;
  final DateTime updatedAt;
  final List<SevenTimerDailyForecast> dailyForecasts;

  String get cityName => location.cityName;

  SevenTimerDailyForecast get today => dailyForecasts.first;

  WeatherType get weatherType => today.weatherType.toWidgetWeatherType();

  int get currentTemperatureCelsius => today.averageTemperature;

  int get apparentTemperatureCelsius => today.apparentTemperature;

  int get highTemperatureCelsius => today.maxTemperature;

  int get lowTemperatureCelsius => today.minTemperature;

  String get summary => today.buildSummary();

  String get feelsLikeLabel => '体感约${today.apparentTemperature}°';

  String get humidityLabel => today.humidityLabel;

  String get cloudCoverLabel => today.cloudCoverLabel;

  String get windLabel => '${today.windDirection} · ${today.windSpeedLabel}';

  String get precipitationLabel => today.precipitationType.label;

  String get coordinateLabel =>
      '${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}';

  String updatedLabel(DateTime now) {
    final minutes = now.difference(updatedAt).inMinutes;
    if (minutes <= 0) {
      return '刚刚更新';
    }
    if (minutes < 60) {
      return '$minutes分钟前';
    }
    final hours = now.difference(updatedAt).inHours;
    return '$hours小时前';
  }
}

enum WeatherType { sunny, cloudy, partlyCloudy, rainy, snowy, thunder }

extension WeatherTypePresentation on WeatherType {
  String get label {
    return switch (this) {
      WeatherType.sunny => '晴朗',
      WeatherType.cloudy => '阴天',
      WeatherType.partlyCloudy => '多云',
      WeatherType.rainy => '下雨',
      WeatherType.snowy => '下雪',
      WeatherType.thunder => '雷暴',
    };
  }

  IconData get icon {
    return switch (this) {
      WeatherType.sunny => Icons.wb_sunny_rounded,
      WeatherType.cloudy => Icons.cloud_rounded,
      WeatherType.partlyCloudy => Icons.cloud_queue_rounded,
      WeatherType.rainy => Icons.umbrella_rounded,
      WeatherType.snowy => Icons.ac_unit_rounded,
      WeatherType.thunder => Icons.thunderstorm_rounded,
    };
  }

  List<Color> colorsFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (this) {
      WeatherType.sunny =>
        isDark
            ? const [Color(0xFFFFB457), Color(0xFFFF8F6B)]
            : const [Color(0xFFFFD978), Color(0xFFFFB36A)],
      WeatherType.cloudy =>
        isDark
            ? const [Color(0xFF7C8AA5), Color(0xFF5B647A)]
            : const [Color(0xFFC5D1E2), Color(0xFFAAB8CD)],
      WeatherType.partlyCloudy =>
        isDark
            ? const [Color(0xFF8C8AF7), Color(0xFFFF9D7A)]
            : const [Color(0xFFA7B6FF), Color(0xFFFFC49B)],
      WeatherType.rainy =>
        isDark
            ? const [Color(0xFF58A6FF), Color(0xFF4361EE)]
            : const [Color(0xFF86C5FF), Color(0xFF6F92FF)],
      WeatherType.snowy =>
        isDark
            ? const [Color(0xFF9DD7FF), Color(0xFF7AB6E6)]
            : const [Color(0xFFD5EEFF), Color(0xFFB9DAFF)],
      WeatherType.thunder =>
        isDark
            ? const [Color(0xFF8E7CFF), Color(0xFF5A45D6)]
            : const [Color(0xFFC1B5FF), Color(0xFF8E7DFF)],
    };
  }
}

class WeatherState {
  const WeatherState({this.report, this.isLoading = false, this.errorMessage});

  final WeatherReport? report;
  final bool isLoading;
  final String? errorMessage;

  WeatherState copyWith({
    WeatherReport? report,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WeatherState(
      report: report ?? this.report,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class WeatherLocationConfig {
  const WeatherLocationConfig({
    required this.latitude,
    required this.longitude,
    required this.cityName,
  });

  final double latitude;
  final double longitude;
  final String cityName;
}

enum TemperatureTrend { rising, stable, falling }

extension TemperatureTrendPresentation on TemperatureTrend {
  IconData get icon {
    return switch (this) {
      TemperatureTrend.rising => Icons.trending_up_rounded,
      TemperatureTrend.stable => Icons.trending_flat_rounded,
      TemperatureTrend.falling => Icons.trending_down_rounded,
    };
  }

  String get label {
    return switch (this) {
      TemperatureTrend.rising => '升温',
      TemperatureTrend.stable => '平稳',
      TemperatureTrend.falling => '降温',
    };
  }
}

enum SevenTimerPrecipitationType { none, rain, snow, freezingRain, icePellets }

extension SevenTimerPrecipitationTypePresentation
    on SevenTimerPrecipitationType {
  String get label {
    return switch (this) {
      SevenTimerPrecipitationType.none => '无降水',
      SevenTimerPrecipitationType.rain => '降雨',
      SevenTimerPrecipitationType.snow => '降雪',
      SevenTimerPrecipitationType.freezingRain => '冻雨',
      SevenTimerPrecipitationType.icePellets => '冰粒',
    };
  }
}

extension SevenTimerPrecipitationTypeParser on SevenTimerPrecipitationType {
  static SevenTimerPrecipitationType fromApiValue(String value) {
    return switch (value.toLowerCase()) {
      'rain' => SevenTimerPrecipitationType.rain,
      'snow' => SevenTimerPrecipitationType.snow,
      'frzr' => SevenTimerPrecipitationType.freezingRain,
      'icep' => SevenTimerPrecipitationType.icePellets,
      _ => SevenTimerPrecipitationType.none,
    };
  }
}

enum SevenTimerWeatherCode {
  clearDay,
  clearNight,
  partlyCloudyDay,
  partlyCloudyNight,
  mostlyCloudyDay,
  mostlyCloudyNight,
  cloudyDay,
  cloudyNight,
  humidDay,
  humidNight,
  lightRainDay,
  lightRainNight,
  occasionalShowerDay,
  occasionalShowerNight,
  isolatedShowerDay,
  isolatedShowerNight,
  lightSnowDay,
  lightSnowNight,
  rainDay,
  rainNight,
  snowDay,
  snowNight,
  rainSnowDay,
  rainSnowNight,
  thunderstormDay,
  thunderstormNight,
  thunderRainDay,
  thunderRainNight,
  unknown,
}

extension SevenTimerWeatherCodeMapper on SevenTimerWeatherCode {
  static SevenTimerWeatherCode fromApiValue(String value) {
    return switch (value.toLowerCase()) {
      'clearday' => SevenTimerWeatherCode.clearDay,
      'clearnight' => SevenTimerWeatherCode.clearNight,
      'pcloudyday' => SevenTimerWeatherCode.partlyCloudyDay,
      'pcloudynight' => SevenTimerWeatherCode.partlyCloudyNight,
      'mcloudyday' => SevenTimerWeatherCode.mostlyCloudyDay,
      'mcloudynight' => SevenTimerWeatherCode.mostlyCloudyNight,
      'cloudyday' => SevenTimerWeatherCode.cloudyDay,
      'cloudynight' => SevenTimerWeatherCode.cloudyNight,
      'humidday' => SevenTimerWeatherCode.humidDay,
      'humidnight' => SevenTimerWeatherCode.humidNight,
      'lightrainday' => SevenTimerWeatherCode.lightRainDay,
      'lightrainnight' => SevenTimerWeatherCode.lightRainNight,
      'oshowerday' => SevenTimerWeatherCode.occasionalShowerDay,
      'oshowernight' => SevenTimerWeatherCode.occasionalShowerNight,
      'ishowerday' => SevenTimerWeatherCode.isolatedShowerDay,
      'ishowernight' => SevenTimerWeatherCode.isolatedShowerNight,
      'lightsnowday' => SevenTimerWeatherCode.lightSnowDay,
      'lightsnownight' => SevenTimerWeatherCode.lightSnowNight,
      'rainday' => SevenTimerWeatherCode.rainDay,
      'rainnight' => SevenTimerWeatherCode.rainNight,
      'snowday' => SevenTimerWeatherCode.snowDay,
      'snownight' => SevenTimerWeatherCode.snowNight,
      'rainsnowday' => SevenTimerWeatherCode.rainSnowDay,
      'rainsnownight' => SevenTimerWeatherCode.rainSnowNight,
      'tsday' => SevenTimerWeatherCode.thunderstormDay,
      'tsnight' => SevenTimerWeatherCode.thunderstormNight,
      'tsrainday' => SevenTimerWeatherCode.thunderRainDay,
      'tsrainnight' => SevenTimerWeatherCode.thunderRainNight,
      _ => SevenTimerWeatherCode.unknown,
    };
  }

  String get label {
    return switch (this) {
      SevenTimerWeatherCode.clearDay ||
      SevenTimerWeatherCode.clearNight => '晴朗',
      SevenTimerWeatherCode.partlyCloudyDay ||
      SevenTimerWeatherCode.partlyCloudyNight => '多云',
      SevenTimerWeatherCode.mostlyCloudyDay ||
      SevenTimerWeatherCode.mostlyCloudyNight ||
      SevenTimerWeatherCode.cloudyDay ||
      SevenTimerWeatherCode.cloudyNight => '阴天',
      SevenTimerWeatherCode.humidDay ||
      SevenTimerWeatherCode.humidNight => '潮湿',
      SevenTimerWeatherCode.lightRainDay ||
      SevenTimerWeatherCode.lightRainNight ||
      SevenTimerWeatherCode.occasionalShowerDay ||
      SevenTimerWeatherCode.occasionalShowerNight ||
      SevenTimerWeatherCode.isolatedShowerDay ||
      SevenTimerWeatherCode.isolatedShowerNight ||
      SevenTimerWeatherCode.rainDay ||
      SevenTimerWeatherCode.rainNight => '降雨',
      SevenTimerWeatherCode.lightSnowDay ||
      SevenTimerWeatherCode.lightSnowNight ||
      SevenTimerWeatherCode.snowDay ||
      SevenTimerWeatherCode.snowNight ||
      SevenTimerWeatherCode.rainSnowDay ||
      SevenTimerWeatherCode.rainSnowNight => '降雪',
      SevenTimerWeatherCode.thunderstormDay ||
      SevenTimerWeatherCode.thunderstormNight ||
      SevenTimerWeatherCode.thunderRainDay ||
      SevenTimerWeatherCode.thunderRainNight => '雷暴',
      SevenTimerWeatherCode.unknown => '未知天气',
    };
  }

  WeatherType toWidgetWeatherType() {
    return switch (this) {
      SevenTimerWeatherCode.clearDay ||
      SevenTimerWeatherCode.clearNight => WeatherType.sunny,
      SevenTimerWeatherCode.partlyCloudyDay ||
      SevenTimerWeatherCode.partlyCloudyNight => WeatherType.partlyCloudy,
      SevenTimerWeatherCode.mostlyCloudyDay ||
      SevenTimerWeatherCode.mostlyCloudyNight ||
      SevenTimerWeatherCode.cloudyDay ||
      SevenTimerWeatherCode.cloudyNight ||
      SevenTimerWeatherCode.humidDay ||
      SevenTimerWeatherCode.humidNight => WeatherType.cloudy,
      SevenTimerWeatherCode.lightRainDay ||
      SevenTimerWeatherCode.lightRainNight ||
      SevenTimerWeatherCode.occasionalShowerDay ||
      SevenTimerWeatherCode.occasionalShowerNight ||
      SevenTimerWeatherCode.isolatedShowerDay ||
      SevenTimerWeatherCode.isolatedShowerNight ||
      SevenTimerWeatherCode.rainDay ||
      SevenTimerWeatherCode.rainNight => WeatherType.rainy,
      SevenTimerWeatherCode.lightSnowDay ||
      SevenTimerWeatherCode.lightSnowNight ||
      SevenTimerWeatherCode.snowDay ||
      SevenTimerWeatherCode.snowNight ||
      SevenTimerWeatherCode.rainSnowDay ||
      SevenTimerWeatherCode.rainSnowNight => WeatherType.snowy,
      SevenTimerWeatherCode.thunderstormDay ||
      SevenTimerWeatherCode.thunderstormNight ||
      SevenTimerWeatherCode.thunderRainDay ||
      SevenTimerWeatherCode.thunderRainNight => WeatherType.thunder,
      SevenTimerWeatherCode.unknown => WeatherType.cloudy,
    };
  }
}

String weekdayLabel(DateTime date) {
  return switch (date.weekday) {
    DateTime.monday => '周一',
    DateTime.tuesday => '周二',
    DateTime.wednesday => '周三',
    DateTime.thursday => '周四',
    DateTime.friday => '周五',
    DateTime.saturday => '周六',
    DateTime.sunday => '周日',
    _ => '今天',
  };
}

class SevenTimerDailyForecast {
  const SevenTimerDailyForecast({
    required this.date,
    required this.weatherType,
    required this.maxTemperature,
    required this.minTemperature,
    required this.cloudCover,
    required this.relativeHumidity,
    required this.windDirection,
    required this.windSpeedLevel,
    required this.precipitationType,
  });

  final DateTime date;
  final SevenTimerWeatherCode weatherType;
  final int maxTemperature;
  final int minTemperature;
  final int? cloudCover;
  final int? relativeHumidity;
  final String windDirection;
  final int? windSpeedLevel;
  final SevenTimerPrecipitationType precipitationType;

  int get averageTemperature => ((maxTemperature + minTemperature) / 2).round();

  String get humidityLabel =>
      relativeHumidity == null ? '--' : '$relativeHumidity%';

  String get cloudCoverLabel => cloudCover == null ? '--' : '$cloudCover%';

  String get windSpeedLabel =>
      windSpeedLevel == null ? '风速未知' : '$windSpeedLevel级风';

  String get weekLabel => weekdayLabel(date);

  String get dateLabel => '${date.month}月${date.day}日';

  /// 7timer civillight 没有直接给体感温度，这里用湿度和风力做轻量估算，方便 UI 给用户直观反馈。
  int get apparentTemperature {
    final humidityOffset = relativeHumidity == null
        ? 0
        : ((relativeHumidity! - 60) / 12).round();
    final windOffset = windSpeedLevel == null
        ? 0
        : ((windSpeedLevel! - 2) / 3).floor();
    return averageTemperature + humidityOffset - windOffset;
  }

  String buildSummary() {
    final parts = <String>[
      cloudCover == null ? weatherType.label : '云量$cloudCover%',
      '风向$windDirection',
      windSpeedLabel,
      precipitationType.label,
    ];

    return parts.where((item) => item.isNotEmpty).join(' · ');
  }

  TemperatureTrend compareTrendFrom(SevenTimerDailyForecast? previousForecast) {
    if (previousForecast == null) {
      return TemperatureTrend.stable;
    }

    final delta = averageTemperature - previousForecast.averageTemperature;
    if (delta >= 2) {
      return TemperatureTrend.rising;
    }
    if (delta <= -2) {
      return TemperatureTrend.falling;
    }
    return TemperatureTrend.stable;
  }
}
