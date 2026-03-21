import 'package:flutter/material.dart';

import 'home/home_page.dart';
import 'weather/weather_repository.dart';

class WangWangApp extends StatelessWidget {
  const WangWangApp({super.key, required this.weatherRepository});

  final WeatherRepository weatherRepository;

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
      home: HomePage(weatherRepository: weatherRepository),
    );
  }
}
