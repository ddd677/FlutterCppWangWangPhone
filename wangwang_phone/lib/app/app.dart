import 'package:flutter/material.dart';

import 'startup/startup_flow_page.dart';
import 'startup/startup_security_store.dart';
import 'weather/weather_repository.dart';
import 'weather/weather_settings.dart';

class WangWangApp extends StatelessWidget {
  const WangWangApp({
    super.key,
    required this.weatherRepository,
    required this.weatherSettingsStore,
    this.startupSecurityStore,
    this.startupDebugOptions = const StartupDebugOptions(),
  });

  final WeatherRepository weatherRepository;
  final WeatherSettingsStore weatherSettingsStore;
  final StartupSecurityStore? startupSecurityStore;
  final StartupDebugOptions startupDebugOptions;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFFF8FA3);

    return MaterialApp(
      title: '汪汪机',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'WangWang',
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F4FB),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'WangWang',
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF120B1B),
      ),
      home: StartupFlowPage(
        weatherRepository: weatherRepository,
        weatherSettingsStore: weatherSettingsStore,
        securityStore: startupSecurityStore,
        debugOptions: startupDebugOptions,
      ),
    );
  }
}
