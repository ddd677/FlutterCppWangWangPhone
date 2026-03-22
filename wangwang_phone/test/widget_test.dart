import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wangwang_phone/main.dart';

class _FakeWeatherRepository extends WeatherRepository {
  _FakeWeatherRepository(this.report);

  final WeatherReport report;

  @override
  Future<WeatherReport> fetchWeather() async {
    return report;
  }
}

WeatherReport _buildFakeReport() {
  final startDate = DateTime(2026, 3, 21);
  return WeatherReport(
    location: const WeatherLocationConfig(
      latitude: 22.5431,
      longitude: 114.0579,
      cityName: '深圳市',
    ),
    updatedAt: DateTime(2026, 3, 21, 10, 30),
    dailyForecasts: List.generate(7, (index) {
      return SevenTimerDailyForecast(
        date: startDate.add(Duration(days: index)),
        weatherType: switch (index) {
          0 => SevenTimerWeatherCode.clearDay,
          1 => SevenTimerWeatherCode.partlyCloudyDay,
          2 => SevenTimerWeatherCode.rainDay,
          3 => SevenTimerWeatherCode.cloudyDay,
          4 => SevenTimerWeatherCode.clearDay,
          5 => SevenTimerWeatherCode.thunderRainDay,
          _ => SevenTimerWeatherCode.lightSnowDay,
        },
        maxTemperature: 28 - index,
        minTemperature: 21 - index,
        cloudCover: 30 + index * 5,
        relativeHumidity: 65 + index,
        windDirection: 'NE',
        windSpeedLevel: 3 + (index % 2),
        precipitationType: switch (index) {
          2 => SevenTimerPrecipitationType.rain,
          5 => SevenTimerPrecipitationType.rain,
          6 => SevenTimerPrecipitationType.snow,
          _ => SevenTimerPrecipitationType.none,
        },
      );
    }),
  );
}

WangWangApp _buildTestApp({
  MemoryWeatherSettingsStore? settingsStore,
  StartupSecurityStore? startupSecurityStore,
  StartupDebugOptions startupDebugOptions = const StartupDebugOptions(
    skipSplash: true,
    skipLockScreen: true,
  ),
}) {
  return WangWangApp(
    weatherRepository: _FakeWeatherRepository(_buildFakeReport()),
    weatherSettingsStore: settingsStore ?? MemoryWeatherSettingsStore(),
    startupSecurityStore:
        startupSecurityStore ??
        MemoryStartupSecurityStore(initialPasscode: '246810'),
    startupDebugOptions: startupDebugOptions,
  );
}

Future<void> _tapPasscodeDigits(
  WidgetTester tester,
  String digits,
) async {
  for (final digit in digits.split('')) {
    await tester.tap(find.byKey(Key('startup_keypad_digit_$digit')));
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('7timer天气类型映射正确', () {
    expect(
      SevenTimerWeatherCodeMapper.fromApiValue(
        'clearday',
      ).toWidgetWeatherType(),
      WeatherType.sunny,
    );
    expect(
      SevenTimerWeatherCodeMapper.fromApiValue(
        'pcloudyday',
      ).toWidgetWeatherType(),
      WeatherType.partlyCloudy,
    );
    expect(
      SevenTimerWeatherCodeMapper.fromApiValue(
        'rainnight',
      ).toWidgetWeatherType(),
      WeatherType.rainy,
    );
    expect(
      SevenTimerWeatherCodeMapper.fromApiValue('snowday').toWidgetWeatherType(),
      WeatherType.snowy,
    );
    expect(
      SevenTimerWeatherCodeMapper.fromApiValue('tsday').toWidgetWeatherType(),
      WeatherType.thunder,
    );
  });

  test('TXT人设可以解析成联系人草稿', () {
    final controller = ChatAppController.seeded();

    final draft = controller.draftFromImportedText(
      fileName: '小雨.txt',
      content: '''
名字：小雨
签名：晚风会替我说想你
人设：温柔系夜聊搭子，擅长安慰情绪，也会分享喜欢的歌。
开场白：你好呀，我刚抱着热牛奶坐下，你今天过得怎么样？
''',
    );

    expect(draft.name, '小雨');
    expect(draft.signature, '晚风会替我说想你');
    expect(draft.personaSummary, contains('温柔系夜聊搭子'));
    expect(draft.initialGreeting, contains('热牛奶'));
  });

  test('结构化消息解析器会按type分发不同消息体', () {
    final redPacketBody = ChatStructuredMessageParser.parseBody({
      'type': 'redpacket',
      'title': '晚安红包',
      'amount': '6.66',
      'note': '早点休息',
    });
    final imageBody = ChatStructuredMessageParser.parseBody({
      'type': 'image',
      'title': '夜空照片',
      'description': '月亮像一盏小灯',
      'theme': '夜色',
    });

    expect(redPacketBody, isA<RedPacketMessageBody>());
    expect(imageBody, isA<ImageMessageBody>());
    expect(redPacketBody.previewText, contains('红包'));
  });

  test('隐藏消息会落到summary memory diary并驱动朋友圈', () async {
    final controller = ChatAppController.seeded(
      summaryStore: MemoryChatSummaryStore(),
    );
    final beforeMemories = controller.memories.length;
    final beforeDiaries = controller.diaries.length;
    final beforeThoughts = controller.thoughts.length;
    final beforeSystems = controller.systemEntries.length;
    final beforeMoments = controller.moments.length;

    await controller.ingestStructuredPayloads(
      contactId: 'ari',
      payloads: [
        {'type': 'summary', 'content': '阿梨更新了一段新的陪伴总结。'},
        {'type': 'memory', 'title': '新的长期记忆', 'content': '她希望被先安静抱一下。'},
        {
          'type': 'diary',
          'title': '今晚的记录',
          'content': '她愿意把疲惫讲给我听。',
          'mood': '珍惜',
        },
        {'type': 'thought', 'content': '她今天真的很累。'},
        {'type': 'system', 'content': '已同步一条新的总结。', 'level': 'info'},
        {'type': 'moment', 'content': '晚风把今天的疲惫吹松了一点。', 'mood': '夜晚碎片'},
      ],
    );

    final latestMoment = controller.moments.first;
    await controller.ingestStructuredPayloads(
      contactId: 'yuejian',
      payloads: [
        {'type': 'moment_like', 'momentId': latestMoment.id},
        {
          'type': 'moment_comment',
          'momentId': latestMoment.id,
          'content': '这条动态的气氛很温柔。',
        },
      ],
    );

    expect(controller.summaryFor('ari')?.content, contains('陪伴总结'));
    expect(controller.memories.length, beforeMemories + 1);
    expect(controller.diaries.length, beforeDiaries + 1);
    expect(controller.thoughts.length, beforeThoughts + 1);
    expect(controller.systemEntries.length, beforeSystems + 1);
    expect(controller.moments.length, beforeMoments + 1);
    expect(controller.moments.first.likedByContactIds, contains('yuejian'));
    expect(controller.moments.first.comments.last.content, contains('气氛很温柔'));
  });

  test('动态summary会持久化并在新控制器中恢复', () async {
    final summaryStore = MemoryChatSummaryStore();
    final firstController = ChatAppController.seeded(
      summaryStore: summaryStore,
    );

    await firstController.ingestStructuredPayloads(
      contactId: 'ari',
      payloads: [
        {'type': 'summary', 'content': '阿梨已经记住你最近更需要柔和、低压的陪伴语气。'},
      ],
    );

    final secondController = ChatAppController.seeded(
      summaryStore: summaryStore,
    );
    await secondController.loadPersistedSummaries();

    expect(secondController.summaryFor('ari')?.content, contains('更需要柔和'));
  });

  test('上下文组装器会按固定顺序拼接system prompt并注入memory', () {
    final controller = ChatAppController.seeded();

    final bundle = controller.buildContextBundle(
      contactId: 'ari',
      latestUserInput: '你先帮我整理一下最近的聊天重点',
    );

    expect(bundle.systemSections.map((section) => section.title).toList(), [
      '系统日期',
      '系统时间',
      '主系统提示词',
      'AI角色人设',
      '用户人设',
      '世界书',
      '预设',
      '动态summary',
      'AI角色记忆memory',
      '可用表情包列表',
    ]);
    expect(bundle.systemPrompt, contains('世界书'));
    expect(bundle.systemPrompt, contains('你怕在高压时被催促'));
    expect(bundle.userPrompt, contains('当前用户输入'));
  });

  test('上下文组装器会按配置截取聊天记录并由summary承接更早内容', () {
    const config = ChatContextConfig(
      mainSystemPrompt: '主系统提示',
      userPersona: '用户人设',
      worldBook: '世界书',
      preset: '预设',
      maxRecentMessages: 2,
    );

    final contact = ChatSeedData.contacts.first;
    final bundle = const ChatContextAssembler().build(
      ChatContextAssemblerInput(
        generatedAt: DateTime(2026, 3, 21, 21, 0),
        contact: contact,
        config: config,
        summary: ChatSeedData.summaries['ari'],
        memories: ChatSeedData.memories
            .where((entry) => entry.contactId == 'ari')
            .toList(),
        recentMessages: ChatSeedData.messages['ari']!,
        latestUserInput: '继续聊工作',
        availableEmojis: const [
          ChatEmojiEntry(id: 'hug', symbol: '🥹', description: '抱抱'),
        ],
      ),
    );

    expect(bundle.selectedMessages.length, 2);
    expect(bundle.usedSummaryBridge, isTrue);
    expect(bundle.userPrompt, contains('更早聊天内容已由 summary 承接'));
  });

  testWidgets('首次启动会经过开屏和密码设置后进入主屏幕', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        startupSecurityStore: MemoryStartupSecurityStore(),
        startupDebugOptions: const StartupDebugOptions(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byKey(const Key('startup_splash_page')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('startup_passcode_setup_page')), findsOneWidget);

    await _tapPasscodeDigits(tester, '246810');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('深圳市'), findsOneWidget);
    expect(find.text('微信'), findsOneWidget);
  });

  testWidgets('已有密码时会经过锁屏和密码解锁后进入主屏幕', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        startupSecurityStore: MemoryStartupSecurityStore(
          initialPasscode: '246810',
        ),
        startupDebugOptions: const StartupDebugOptions(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byKey(const Key('startup_splash_page')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('startup_lock_page')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('startup_lock_swipe_layer')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('startup_passcode_unlock_page')), findsOneWidget);

    await _tapPasscodeDigits(tester, '111111');
    await tester.pumpAndSettle();

    expect(find.text('密码不正确，请重新输入'), findsOneWidget);

    await _tapPasscodeDigits(tester, '246810');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('深圳市'), findsOneWidget);
    expect(find.text('微信'), findsOneWidget);
  });

  testWidgets('桌面展示天气小组件与应用图标', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('深圳市'), findsOneWidget);
    expect(find.textContaining('°'), findsWidgets);
    expect(find.text('点击查看详情'), findsOneWidget);
    expect(find.text('微信'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('天气'), findsOneWidget);
    expect(find.byIcon(Icons.lock_reset_rounded), findsOneWidget);
  });

  testWidgets('桌面天气小组件初始展示加载状态', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    expect(find.text('正在加载天气...'), findsOneWidget);
  });

  testWidgets('点击天气图标后进入天气应用详情页', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_dock_weather')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weather_detail_scroll')), findsOneWidget);
    expect(find.text('天气'), findsWidgets);

    await tester.drag(
      find.byKey(const Key('weather_detail_scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    expect(find.text('温度走势'), findsOneWidget);
    expect(find.text('今日细节'), findsOneWidget);
  });

  testWidgets('点击桌面天气卡片后进入天气详情页', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('点击查看详情'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weather_detail_scroll')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('weather_detail_scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    expect(find.text('温度走势'), findsOneWidget);
  });

  testWidgets('点击微信图标后进入聊天应用并显示四个Tab', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_app_chat')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat_app_page')), findsOneWidget);
    expect(find.text('聊天'), findsWidgets);
    expect(find.text('联系人'), findsOneWidget);
    expect(find.text('朋友圈'), findsOneWidget);
    expect(find.text('我'), findsOneWidget);
    expect(find.text('阿梨'), findsOneWidget);
  });

  testWidgets('聊天详情支持打开上下文调试页', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_app_chat')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat_thread_ari')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.dataset_linked_rounded));
    await tester.pumpAndSettle();

    expect(find.text('上下文调试'), findsOneWidget);
    expect(find.text('System Prompt'), findsOneWidget);
  });

  testWidgets('首页可打开记忆与日记应用', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_app_memory')));
    await tester.pumpAndSettle();
    expect(find.text('记忆'), findsWidgets);
    expect(find.text('动态总结'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_app_diary')));
    await tester.pumpAndSettle();
    expect(find.text('日记'), findsWidgets);
    expect(find.textContaining('想把她今天的疲惫接住'), findsOneWidget);
  });

  testWidgets('聊天应用支持发送文字并收到角色回复', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_app_chat')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat_thread_ari')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('chat_input_field')),
      '今天会议好多，我有点累',
    );
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pump();

    expect(find.text('今天会议好多，我有点累'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.textContaining('先抱抱你一下'), findsOneWidget);
  });

  testWidgets('红包卡片支持收下后更新状态', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_app_chat')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat_thread_ari')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('accept_money_ari-4')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accept_money_ari-4')));
    await tester.pumpAndSettle();

    expect(find.text('已收下'), findsOneWidget);
  });

  testWidgets('联系人页支持直接创建新联系人', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_app_chat')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('联系人').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create_contact_button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('contact_name_field')), '小雨');
    await tester.enterText(
      find.byKey(const Key('contact_signature_field')),
      '晚风会替我说想你',
    );
    await tester.enterText(
      find.byKey(const Key('contact_persona_field')),
      '温柔系夜聊搭子，擅长安慰情绪，也会分享喜欢的歌。',
    );
    await tester.enterText(
      find.byKey(const Key('contact_greeting_field')),
      '你好呀，我刚抱着热牛奶坐下。',
    );

    await tester.ensureVisible(find.byKey(const Key('contact_save_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contact_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('小雨'), findsWidgets);
    expect(find.textContaining('温柔系夜聊搭子'), findsOneWidget);
    expect(find.text('发消息'), findsOneWidget);
  });

  testWidgets('朋友圈支持发布新动态', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_app_chat')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('朋友圈').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create_moment_button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('moment_mood_field')), '夜晚心情');
    await tester.enterText(
      find.byKey(const Key('moment_content_field')),
      '今晚的风很轻，适合把没说完的话慢慢讲完。',
    );
    await tester.ensureVisible(find.byKey(const Key('moment_publish_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('moment_publish_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('夜晚心情'), findsOneWidget);
    expect(find.textContaining('今晚的风很轻'), findsOneWidget);
  });

  testWidgets('切换华氏度后桌面与天气详情同步更新', (WidgetTester tester) async {
    final settingsStore = MemoryWeatherSettingsStore();

    await tester.pumpWidget(_buildTestApp(settingsStore: settingsStore));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('25°C'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home_dock_weather')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('temperature_unit_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('temperature_unit_fahrenheit')));
    await tester.pumpAndSettle();

    expect(find.text('77°F'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('77°F'), findsOneWidget);
  });
}
