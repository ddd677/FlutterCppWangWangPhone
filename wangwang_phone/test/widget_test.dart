import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wangwang_phone/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  testWidgets('默认展示开屏页面', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final bootstrap = await AppBootstrap.initialize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appBootstrapProvider.overrideWithValue(bootstrap)],
        child: const WangWangApp(),
      ),
    );

    expect(find.text('汪汪机'), findsOneWidget);
    expect(find.text('像小狗一样陪伴你的AI小手机'), findsOneWidget);
  });

  testWidgets('已有密码时可以进入修改密码流程', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppPreferenceKeys.passcode: '123456',
    });

    final bootstrap = await AppBootstrap.initialize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appBootstrapProvider.overrideWithValue(bootstrap)],
        child: const WangWangApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    expect(find.text('轻点屏幕开始解锁'), findsOneWidget);

    await tester.tap(find.text('轻点屏幕开始解锁'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('解锁'));
    await tester.pumpAndSettle();

    expect(find.text('深圳市'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.lock_reset_rounded));
    await tester.pumpAndSettle();

    expect(find.text('修改密码'), findsOneWidget);
  });
}
