import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/weather/weather_repository.dart';
import 'app/weather/weather_settings.dart';

export 'app/app.dart';
export 'app/chat/chat_context.dart';
export 'app/chat/chat_controller.dart';
export 'app/chat/chat_context_debug_page.dart';
export 'app/chat/chat_message_payloads.dart';
export 'app/chat/chat_models.dart';
export 'app/chat/chat_summary_store.dart';
export 'app/startup/startup_flow_page.dart';
export 'app/startup/startup_security_store.dart';
export 'app/weather/weather_repository.dart';
export 'app/weather/weather_settings.dart';
export 'app/weather/weather_types.dart';

void main() {
  runApp(
    WangWangApp(
      weatherRepository: buildDefaultWeatherRepository(),
      weatherSettingsStore: buildDefaultWeatherSettingsStore(),
    ),
  );
}
