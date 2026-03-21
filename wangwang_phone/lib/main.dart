import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/weather/weather_repository.dart';

export 'app/app.dart';
export 'app/weather/weather_repository.dart';
export 'app/weather/weather_types.dart';

void main() {
  runApp(WangWangApp(weatherRepository: buildDefaultWeatherRepository()));
}
