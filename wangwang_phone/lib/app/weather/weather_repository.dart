import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'weather_types.dart';

/// 统一封装默认天气仓库，保证桌面小组件和独立天气 App 共用同一份 7timer 配置。
WeatherRepository buildDefaultWeatherRepository({http.Client? client}) {
  return SevenTimerWeatherRepository(
    client: client ?? http.Client(),
    config: const WeatherLocationConfig(
      latitude: 22.5431,
      longitude: 114.0579,
      cityName: '深圳市',
    ),
  );
}

abstract class WeatherRepository {
  const WeatherRepository();

  Future<WeatherReport> fetchWeather();

  void dispose() {}
}

class SevenTimerWeatherRepository extends WeatherRepository {
  const SevenTimerWeatherRepository({
    required this.client,
    required this.config,
  });

  final http.Client client;
  final WeatherLocationConfig config;

  /// 请求 7timer 的 civillight 数据，并统一转换成前端页面可直接消费的天气模型。
  @override
  Future<WeatherReport> fetchWeather() async {
    final uri = Uri.parse('http://www.7timer.info/bin/api.php').replace(
      queryParameters: {
        'lon': config.longitude.toString(),
        'lat': config.latitude.toString(),
        'product': 'civillight',
        'output': 'json',
      },
    );

    final response = await client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('天气接口请求失败');
    }

    final Map<String, dynamic> jsonMap =
        jsonDecode(response.body) as Map<String, dynamic>;
    final forecast = SevenTimerForecast.fromJson(jsonMap);
    return forecast.toReport(config: config);
  }

  @override
  void dispose() {
    client.close();
  }
}

class SevenTimerForecast {
  const SevenTimerForecast({required this.dailyForecasts});

  final List<SevenTimerDailyForecast> dailyForecasts;

  /// 7timer 的每日序列就是后续天气页的基础数据源，这里统一做一次安全解析。
  factory SevenTimerForecast.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['dataseries'];
    if (rawSeries is! List || rawSeries.isEmpty) {
      throw const FormatException('天气数据为空');
    }

    final parsedList = rawSeries.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('天气数据格式错误');
      }

      return SevenTimerDailyForecast(
        date: _parseForecastDate(item['date']),
        weatherType: SevenTimerWeatherCodeMapper.fromApiValue(
          item['weather']?.toString() ?? '',
        ),
        maxTemperature: _parseTemperatureValue(item['temp2m_max']),
        minTemperature: _parseTemperatureValue(item['temp2m_min']),
        cloudCover: _parsePercentScale(item['cloudcover']),
        relativeHumidity: _parsePercentScale(item['rh2m']),
        windDirection:
            (item['wind10m'] as Map<String, dynamic>?)?['direction']
                ?.toString() ??
            '--',
        windSpeedLevel: _parseIntValue(
          (item['wind10m'] as Map<String, dynamic>?)?['speed'],
        ),
        precipitationType: SevenTimerPrecipitationTypeParser.fromApiValue(
          (item['prec_type'] ?? item['precipitation']?['type'])?.toString() ??
              'none',
        ),
      );
    }).toList();

    if (parsedList.isEmpty) {
      throw const FormatException('天气数据格式错误');
    }

    return SevenTimerForecast(dailyForecasts: parsedList);
  }

  WeatherReport toReport({required WeatherLocationConfig config}) {
    return WeatherReport(
      location: config,
      updatedAt: DateTime.now(),
      dailyForecasts: dailyForecasts,
    );
  }
}

DateTime _parseForecastDate(Object? value) {
  final raw = value?.toString() ?? '';
  if (raw.length != 8) {
    return DateTime.now();
  }

  final year = int.tryParse(raw.substring(0, 4)) ?? DateTime.now().year;
  final month = int.tryParse(raw.substring(4, 6)) ?? DateTime.now().month;
  final day = int.tryParse(raw.substring(6, 8)) ?? DateTime.now().day;
  return DateTime(year, month, day);
}

int _parseTemperatureValue(Object? value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed == -9999) {
    return 0;
  }
  return parsed;
}

int? _parseIntValue(Object? value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed == -9999) {
    return null;
  }
  return parsed;
}

int? _parsePercentScale(Object? value) {
  final parsed = _parseIntValue(value);
  if (parsed == null) {
    return null;
  }

  const mapping = {
    -4: 0,
    -3: 5,
    -2: 10,
    -1: 15,
    0: 20,
    1: 25,
    2: 35,
    3: 45,
    4: 55,
    5: 65,
    6: 75,
    7: 80,
    8: 85,
    9: 90,
    10: 92,
    11: 94,
    12: 96,
    13: 97,
    14: 98,
    15: 99,
    16: 100,
  };

  return mapping[parsed] ?? (parsed.clamp(1, 9) * 10);
}

/// 控制天气数据加载、错误展示和详情页同步刷新，桌面和天气页共用这一份状态。
class WeatherController extends ChangeNotifier {
  WeatherController({required WeatherRepository repository})
    : _repository = repository;

  final WeatherRepository _repository;

  WeatherState _state = const WeatherState(isLoading: true);

  WeatherState get state => _state;

  Future<void> loadWeather() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final report = await _repository.fetchWeather();
      _state = WeatherState(report: report, isLoading: false);
    } catch (_) {
      _state = _state.copyWith(isLoading: false, errorMessage: '天气加载失败，点击重试');
    }

    notifyListeners();
  }
}
