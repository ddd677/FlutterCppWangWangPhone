import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  _configureLogging();

  final appBootstrap = await AppBootstrap.initialize();
  runApp(
    ProviderScope(
      overrides: [appBootstrapProvider.overrideWithValue(appBootstrap)],
      child: const WangWangApp(),
    ),
  );
}

void _configureLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.loggerName}: ${record.time.toIso8601String()} ${record.message}',
    );
  });
}

final appLogger = Logger('WangWangPhone');

final appBootstrapProvider = Provider<AppBootstrap>((ref) {
  throw UnimplementedError('应用启动信息尚未初始化');
});

final appFlowControllerProvider =
    StateNotifierProvider<AppFlowController, AppFlowState>((ref) {
      final bootstrap = ref.watch(appBootstrapProvider);
      return AppFlowController(bootstrap: bootstrap);
    });

class AppBootstrap {
  AppBootstrap({
    required this.preferences,
    required this.coreBridge,
    required this.shouldSkipSplash,
    required this.shouldSkipLockScreen,
    required this.hasPasscode,
  });

  final SharedPreferences preferences;
  final NativeCoreBridge coreBridge;
  final bool shouldSkipSplash;
  final bool shouldSkipLockScreen;
  final bool hasPasscode;

  /// 初始化应用启动依赖，包括本地配置与原生核心层。
  static Future<AppBootstrap> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final coreBridge = NativeCoreBridge();
    await coreBridge.initialize();

    return AppBootstrap(
      preferences: preferences,
      coreBridge: coreBridge,
      shouldSkipSplash:
          preferences.getBool(AppPreferenceKeys.skipSplash) ?? false,
      shouldSkipLockScreen:
          preferences.getBool(AppPreferenceKeys.skipLockScreen) ?? false,
      hasPasscode:
          (preferences.getString(AppPreferenceKeys.passcode) ?? '').length == 6,
    );
  }
}

class AppPreferenceKeys {
  static const skipSplash = 'startup.skip_splash';
  static const skipLockScreen = 'startup.skip_lockscreen';
  static const passcode = 'security.passcode';
}

class WangWangApp extends ConsumerWidget {
  const WangWangApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '汪汪机',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'WangWang',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8FA3),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF120B1B),
      ),
      home: const AppFlowPage(),
    );
  }
}

class AppFlowController extends StateNotifier<AppFlowState> {
  AppFlowController({required AppBootstrap bootstrap})
    : _bootstrap = bootstrap,
      super(AppFlowState.initial(bootstrap: bootstrap));

  final AppBootstrap _bootstrap;

  /// 开屏结束后，按照当前配置决定进入锁屏还是主屏幕。
  void completeSplash() {
    if (_bootstrap.shouldSkipLockScreen) {
      state = state.copyWith(stage: AppStage.home);
      return;
    }

    if (_bootstrap.hasPasscode) {
      state = state.copyWith(stage: AppStage.lockScreen);
      return;
    }

    state = state.copyWith(stage: AppStage.passcodeSetup, unlockError: null);
  }

  /// 点击锁屏界面后，进入密码输入层。
  void activateUnlock() {
    state = state.copyWith(stage: AppStage.passcodeUnlock, unlockError: null);
  }

  /// 从主屏幕进入密码修改流程。
  void openPasscodeChange() {
    state = state.copyWith(stage: AppStage.passcodeChange, unlockError: null);
  }

  /// 首次设置六位密码，并同步保存到本地。
  Future<void> setupPasscode(String passcode) async {
    if (passcode.length != 6) {
      state = state.copyWith(unlockError: '请输入6位数字密码');
      return;
    }

    await _bootstrap.preferences.setString(
      AppPreferenceKeys.passcode,
      passcode,
    );
    state = state.copyWith(
      stage: AppStage.home,
      hasPasscode: true,
      unlockError: null,
    );
  }

  /// 校验输入密码，正确后进入主屏幕。
  Future<void> unlock(String passcode) async {
    final savedPasscode =
        _bootstrap.preferences.getString(AppPreferenceKeys.passcode) ?? '';
    if (passcode == savedPasscode) {
      state = state.copyWith(stage: AppStage.home, unlockError: null);
      return;
    }

    state = state.copyWith(unlockError: '密码错误，请重新输入');
  }

  /// 修改当前锁屏密码，成功后返回主屏幕。
  Future<void> changePasscode(String passcode) async {
    if (passcode.length != 6) {
      state = state.copyWith(unlockError: '请输入新的6位数字密码');
      return;
    }

    await _bootstrap.preferences.setString(
      AppPreferenceKeys.passcode,
      passcode,
    );
    state = state.copyWith(
      stage: AppStage.home,
      hasPasscode: true,
      unlockError: '密码修改成功',
    );
  }
}

class AppFlowState {
  const AppFlowState({
    required this.stage,
    required this.shouldSkipSplash,
    required this.shouldSkipLockScreen,
    required this.hasPasscode,
    this.unlockError,
    this.snackMessage,
  });

  final AppStage stage;
  final bool shouldSkipSplash;
  final bool shouldSkipLockScreen;
  final bool hasPasscode;
  final String? unlockError;
  final String? snackMessage;

  factory AppFlowState.initial({required AppBootstrap bootstrap}) {
    final initialStage = bootstrap.shouldSkipSplash
        ? (bootstrap.shouldSkipLockScreen
              ? AppStage.home
              : (bootstrap.hasPasscode
                    ? AppStage.lockScreen
                    : AppStage.passcodeSetup))
        : AppStage.splash;

    return AppFlowState(
      stage: initialStage,
      shouldSkipSplash: bootstrap.shouldSkipSplash,
      shouldSkipLockScreen: bootstrap.shouldSkipLockScreen,
      hasPasscode: bootstrap.hasPasscode,
    );
  }

  AppFlowState copyWith({
    AppStage? stage,
    bool? shouldSkipSplash,
    bool? shouldSkipLockScreen,
    bool? hasPasscode,
    String? unlockError,
    String? snackMessage,
    bool clearSnackMessage = false,
  }) {
    return AppFlowState(
      stage: stage ?? this.stage,
      shouldSkipSplash: shouldSkipSplash ?? this.shouldSkipSplash,
      shouldSkipLockScreen: shouldSkipLockScreen ?? this.shouldSkipLockScreen,
      hasPasscode: hasPasscode ?? this.hasPasscode,
      unlockError: unlockError,
      snackMessage: clearSnackMessage
          ? null
          : (snackMessage ?? this.snackMessage),
    );
  }
}

enum AppStage {
  splash,
  lockScreen,
  passcodeUnlock,
  passcodeSetup,
  passcodeChange,
  home,
}

class AppFlowPage extends ConsumerWidget {
  const AppFlowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appFlowControllerProvider);
    final controller = ref.read(appFlowControllerProvider.notifier);

    return switch (state.stage) {
      AppStage.splash => SplashPage(onFinished: controller.completeSplash),
      AppStage.lockScreen => LockScreenPage(
        onTapUnlock: controller.activateUnlock,
      ),
      AppStage.passcodeUnlock => PasscodePage(
        title: '输入密码',
        description: '输入6位数字密码，回到你的汪汪机',
        actionLabel: '解锁',
        errorText: state.unlockError,
        onSubmit: controller.unlock,
      ),
      AppStage.passcodeSetup => PasscodePage(
        title: '设置密码',
        description: '首次使用需要创建6位数字密码',
        actionLabel: '保存并进入',
        errorText: state.unlockError,
        onSubmit: controller.setupPasscode,
      ),
      AppStage.passcodeChange => PasscodePage(
        title: '修改密码',
        description: '请输入新的6位数字密码',
        actionLabel: '确认修改',
        errorText: state.unlockError,
        onSubmit: controller.changePasscode,
      ),
      AppStage.home => HomePage(
        snackMessage: state.snackMessage,
        onOpenPasscodeChange: controller.openPasscodeChange,
      ),
    };
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    _logoScale = Tween<double>(
      begin: 0.78,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _logoOpacity = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _timer = Timer(const Duration(milliseconds: 2500), widget.onFinished);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF29152F), Color(0xFF120B1B), Color(0xFF0D1D2A)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _logoOpacity,
            child: ScaleTransition(
              scale: _logoScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFC2D1), Color(0xFFFF8FA3)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55FF8FA3),
                          blurRadius: 32,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: Colors.white,
                      size: 58,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '汪汪机',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '像小狗一样陪伴你的AI小手机',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key, required this.onTapUnlock});

  final VoidCallback onTapUnlock;

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  late final Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat('HH:mm').format(_now);
    final dateText = DateFormat('M月d日 EEEE', 'zh_CN').format(_now);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D1B38), Color(0xFF101725), Color(0xFF0B0E18)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 60,
                left: 24,
                right: 24,
                child: Column(
                  children: [
                    Text(
                      timeText,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateText,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: widget.onTapUnlock,
                    child: FrostPanel(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '微信',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '小雪：我刚刚给你发了一张新照片～',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '轻点屏幕开始解锁',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 32,
                child: Text(
                  '向上轻点进入密码界面',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PasscodePage extends StatefulWidget {
  const PasscodePage({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onSubmit,
    this.errorText,
  });

  final String title;
  final String description;
  final String actionLabel;
  final String? errorText;
  final Future<void> Function(String passcode) onSubmit;

  @override
  State<PasscodePage> createState() => _PasscodePageState();
}

class _PasscodePageState extends State<PasscodePage> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
    });
    await widget.onSubmit(_controller.text);
    if (mounted) {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF20192D), Color(0xFF100D18), Color(0xFF090C13)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FrostPanel(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      obscuringCharacter: '●',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        letterSpacing: 10,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '● ● ● ● ● ●',
                        hintStyle: const TextStyle(
                          color: Colors.white24,
                          letterSpacing: 10,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (widget.errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.errorText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFFFB4C0),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8FA3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _submitting ? '处理中...' : widget.actionLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.snackMessage,
    required this.onOpenPasscodeChange,
  });

  final String? snackMessage;
  final VoidCallback onOpenPasscodeChange;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _AppIconData('微信', Icons.chat_bubble_rounded, Color(0xFF5EDC7E)),
      _AppIconData('设置', Icons.settings_rounded, Color(0xFF7D8BFF)),
      _AppIconData('天气', Icons.wb_sunny_rounded, Color(0xFFFFB65C)),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A1630), Color(0xFF171126), Color(0xFF0E1322)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snackMessage != null) ...[
                  FrostPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    borderRadius: 20,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFFA7F3C2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            snackMessage!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                FrostPanel(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_queue_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '深圳市',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '26°C · 多云 · 适合和AI朋友散步聊天',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: GridView.builder(
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 24,
                          childAspectRatio: 0.82,
                        ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _AppIcon(item: item);
                    },
                  ),
                ),
                FrostPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  borderRadius: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ...items.map((item) => _DockIcon(item: item)),
                      GestureDetector(
                        onTap: onOpenPasscodeChange,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.item});

  final _AppIconData item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(item.icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 10),
        Text(
          item.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}

class _DockIcon extends StatelessWidget {
  const _DockIcon({required this.item});

  final _AppIconData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(item.icon, color: Colors.white, size: 26),
    );
  }
}

class _AppIconData {
  const _AppIconData(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class FrostPanel extends StatelessWidget {
  const FrostPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 32,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class NativeCoreBridge {
  NativeCoreBridge() : _library = _tryOpenLibrary();

  final ffi.DynamicLibrary? _library;
  _NativeInitFn? _nativeInit;
  _NativeVersionFn? _nativeVersion;
  _NativeFreeStringFn? _nativeFreeString;
  bool _ready = false;

  /// 初始化FFI桥接，优先探测动态库，失败时自动降级到纯Flutter演示模式。
  Future<void> initialize() async {
    if (_ready) return;
    try {
      if (_library == null) {
        appLogger.warning('未找到C++动态库，当前使用纯Flutter演示模式');
        return;
      }

      final library = _library;
      _nativeInit = library.lookupFunction<_NativeInitNative, _NativeInitFn>(
        'wangwang_init',
      );
      _nativeVersion = library
          .lookupFunction<_NativeVersionNative, _NativeVersionFn>(
            'wangwang_version',
          );
      _nativeFreeString = library
          .lookupFunction<_NativeFreeStringNative, _NativeFreeStringFn>(
            'wangwang_free_string',
          );

      final supportDir = await getApplicationSupportDirectory();
      final dbPath = p.join(supportDir.path, 'wangwang_phone.db');
      final dbPathPointer = dbPath.toNativeUtf8();
      final resultPointer = _nativeInit!.call(dbPathPointer.cast());
      calloc.free(dbPathPointer);
      final result = resultPointer.cast<Utf8>().toDartString();
      _nativeFreeString?.call(resultPointer.cast());
      appLogger.info('C++核心层初始化结果: $result');
    } catch (error, stackTrace) {
      appLogger.warning('FFI初始化失败，已降级为演示模式: $error');
      appLogger.fine(stackTrace.toString());
    } finally {
      _ready = true;
    }
  }

  /// 读取核心层版本，用于确认原生动态库是否可用。
  String? readVersion() {
    if (_nativeVersion == null || _nativeFreeString == null) {
      return null;
    }

    final resultPointer = _nativeVersion!.call();
    final version = resultPointer.cast<Utf8>().toDartString();
    _nativeFreeString!.call(resultPointer.cast());
    return version;
  }

  static ffi.DynamicLibrary? _tryOpenLibrary() {
    try {
      if (Platform.isAndroid || Platform.isLinux) {
        return ffi.DynamicLibrary.open('libwangwang_core.so');
      }
      if (Platform.isIOS || Platform.isMacOS) {
        return ffi.DynamicLibrary.process();
      }
      if (Platform.isWindows) {
        return ffi.DynamicLibrary.open('wangwang_core.dll');
      }
    } catch (error) {
      appLogger.warning('动态库加载失败: $error');
    }
    return null;
  }
}

typedef _NativeInitNative =
    ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> dbPath);
typedef _NativeInitFn = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> dbPath);

typedef _NativeVersionNative = ffi.Pointer<Utf8> Function();
typedef _NativeVersionFn = ffi.Pointer<Utf8> Function();

typedef _NativeFreeStringNative =
    ffi.Void Function(ffi.Pointer<ffi.Char> result);
typedef _NativeFreeStringFn = void Function(ffi.Pointer<ffi.Char> result);
