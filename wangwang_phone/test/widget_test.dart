import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wangwang_phone/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
