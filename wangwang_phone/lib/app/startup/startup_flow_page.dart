import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../home/home_page.dart';
import '../shared/ui.dart';
import '../weather/weather_repository.dart';
import '../weather/weather_settings.dart';
import 'startup_security_store.dart';

class StartupDebugOptions {
  const StartupDebugOptions({
    this.skipSplash = false,
    this.skipLockScreen = false,
  });

  final bool skipSplash;
  final bool skipLockScreen;
}

enum StartupStage { splash, lockScreen, passcodeUnlock, passcodeSetup, home }

class StartupBootstrap {
  const StartupBootstrap({
    required this.securityStore,
    required this.shouldSkipSplash,
    required this.shouldSkipLockScreen,
    required this.hasPasscode,
  });

  final StartupSecurityStore securityStore;
  final bool shouldSkipSplash;
  final bool shouldSkipLockScreen;
  final bool hasPasscode;

  /// 预先准备日期格式和数据库密码存储，避免首屏阶段出现状态抖动。
  static Future<StartupBootstrap> load({
    required StartupSecurityStore securityStore,
    required StartupDebugOptions debugOptions,
  }) async {
    await initializeDateFormatting('zh_CN');
    await securityStore.initialize();

    return StartupBootstrap(
      securityStore: securityStore,
      shouldSkipSplash: debugOptions.skipSplash,
      shouldSkipLockScreen: debugOptions.skipLockScreen,
      hasPasscode: await securityStore.hasPasscode(),
    );
  }

  StartupBootstrap copyWith({
    StartupSecurityStore? securityStore,
    bool? shouldSkipSplash,
    bool? shouldSkipLockScreen,
    bool? hasPasscode,
  }) {
    return StartupBootstrap(
      securityStore: securityStore ?? this.securityStore,
      shouldSkipSplash: shouldSkipSplash ?? this.shouldSkipSplash,
      shouldSkipLockScreen:
          shouldSkipLockScreen ?? this.shouldSkipLockScreen,
      hasPasscode: hasPasscode ?? this.hasPasscode,
    );
  }
}

class StartupFlowPage extends StatefulWidget {
  const StartupFlowPage({
    super.key,
    required this.weatherRepository,
    required this.weatherSettingsStore,
    this.securityStore,
    this.debugOptions = const StartupDebugOptions(),
  });

  final WeatherRepository weatherRepository;
  final WeatherSettingsStore weatherSettingsStore;
  final StartupSecurityStore? securityStore;
  final StartupDebugOptions debugOptions;

  @override
  State<StartupFlowPage> createState() => _StartupFlowPageState();
}

class _StartupFlowPageState extends State<StartupFlowPage> {
  late final StartupSecurityStore _securityStore;
  late final Future<void> _bootstrapFuture;

  StartupBootstrap? _bootstrap;
  StartupStage? _stage;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _securityStore = widget.securityStore ?? buildDefaultStartupSecurityStore();
    _bootstrapFuture = _loadBootstrap();
  }

  /// 统一加载启动配置，保证开屏、锁屏和设密逻辑共享同一份状态来源。
  Future<void> _loadBootstrap() async {
    final bootstrap = await StartupBootstrap.load(
      securityStore: _securityStore,
      debugOptions: widget.debugOptions,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _bootstrap = bootstrap;
      _stage = _resolveInitialStage(bootstrap);
      _errorText = null;
    });
  }

  StartupStage _resolveInitialStage(StartupBootstrap bootstrap) {
    if (!bootstrap.shouldSkipSplash) {
      return StartupStage.splash;
    }
    if (bootstrap.shouldSkipLockScreen) {
      return StartupStage.home;
    }
    if (bootstrap.hasPasscode) {
      return StartupStage.lockScreen;
    }
    return StartupStage.passcodeSetup;
  }

  /// 开屏结束后根据密码状态流转到锁屏或首次设密页。
  void _handleSplashFinished() {
    final bootstrap = _bootstrap;
    if (bootstrap == null) {
      return;
    }

    setState(() {
      _errorText = null;
      if (bootstrap.shouldSkipLockScreen) {
        _stage = StartupStage.home;
      } else if (bootstrap.hasPasscode) {
        _stage = StartupStage.lockScreen;
      } else {
        _stage = StartupStage.passcodeSetup;
      }
    });
  }

  void _openUnlockPage() {
    setState(() {
      _stage = StartupStage.passcodeUnlock;
      _errorText = null;
    });
  }

  /// 首次设置密码时直接写入数据库 settings 表，确保后续解锁走同一份数据。
  Future<void> _savePasscode(String passcode) async {
    final bootstrap = _bootstrap;
    if (bootstrap == null) {
      return;
    }
    if (passcode.length != 6) {
      setState(() {
        _errorText = '请输入 6 位数字密码';
      });
      return;
    }

    await bootstrap.securityStore.writePasscode(passcode);
    if (!mounted) {
      return;
    }

    setState(() {
      _bootstrap = bootstrap.copyWith(hasPasscode: true);
      _stage = StartupStage.home;
      _errorText = null;
    });
  }

  /// 解锁时直接读取数据库密码进行校验，避免和首次设密逻辑分叉。
  Future<void> _unlockWithPasscode(String passcode) async {
    final bootstrap = _bootstrap;
    if (bootstrap == null) {
      return;
    }

    final savedPasscode = await bootstrap.securityStore.readPasscode();
    if (passcode == savedPasscode) {
      if (!mounted) {
        return;
      }
      setState(() {
        _stage = StartupStage.home;
        _errorText = null;
      });
      return;
    }

    setState(() {
      _errorText = '密码不正确，请重新输入';
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            _bootstrap == null ||
            _stage == null) {
          return const _StartupLoadingPage();
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<StartupStage>(_stage!),
            child: _buildCurrentStage(),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStage() {
    return switch (_stage!) {
      StartupStage.splash => _SplashPage(onFinished: _handleSplashFinished),
      StartupStage.lockScreen => _LockScreenPage(onSwipeUnlock: _openUnlockPage),
      StartupStage.passcodeUnlock => _PasscodePage(
        pageKey: const Key('startup_passcode_unlock_page'),
        title: '输入锁屏密码',
        description: '输入你设置的 6 位数字密码',
        helperText: '输入完成后会自动解锁',
        errorText: _errorText,
        onSubmit: _unlockWithPasscode,
      ),
      StartupStage.passcodeSetup => _PasscodePage(
        pageKey: const Key('startup_passcode_setup_page'),
        title: '设置密码',
        description: '首次进入汪汪机，请先设置 6 位数字密码',
        helperText: '密码会保存到本地数据库中',
        errorText: _errorText,
        onSubmit: _savePasscode,
      ),
      StartupStage.home => HomePage(
        weatherRepository: widget.weatherRepository,
        weatherSettingsStore: widget.weatherSettingsStore,
      ),
    };
  }
}

class _StartupLoadingPage extends StatelessWidget {
  const _StartupLoadingPage();

  @override
  Widget build(BuildContext context) {
    final visuals = _StartupVisuals.of(context);

    return Scaffold(
      body: _StartupScene(
        sceneKey: const Key('startup_loading_page'),
        visuals: visuals,
        child: Center(
          child: FrostPanel(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            borderRadius: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: visuals.accentPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '正在唤醒汪汪机...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: visuals.primaryText,
                    fontWeight: FontWeight.w700,
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

class _SplashPage extends StatefulWidget {
  const _SplashPage({required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _taglineOpacity;
  Timer? _finishTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..forward();
    _logoScale = Tween<double>(
      begin: 0.82,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _logoOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _taglineOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 1, curve: Curves.easeOut),
      ),
    );
    _finishTimer = Timer(const Duration(milliseconds: 2350), widget.onFinished);
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visuals = _StartupVisuals.of(context);

    return Scaffold(
      body: _StartupScene(
        sceneKey: const Key('startup_splash_page'),
        visuals: visuals,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(38),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            visuals.accentSoft,
                            visuals.accentPrimary,
                            visuals.accentSecondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: visuals.accentPrimary.withValues(alpha: 0.28),
                            blurRadius: 40,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        '../asset/app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _logoOpacity,
                  child: Text(
                    '汪汪机',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: visuals.primaryText,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: Text(
                    '万象成澜，相由心生',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: visuals.secondaryText,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: visuals.badgeBackground,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: visuals.badgeBorder),
                    ),
                    child: Text(
                      '正在进入汪汪机',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: visuals.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _LockScreenPage extends StatefulWidget {
  const _LockScreenPage({required this.onSwipeUnlock});

  final VoidCallback onSwipeUnlock;

  @override
  State<_LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<_LockScreenPage> {
  static const double _unlockThreshold = 120;

  late final Timer _timer;
  DateTime _now = DateTime.now();
  double _dragExtent = 0;
  bool _unlockTriggered = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
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

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_unlockTriggered) {
      return;
    }
    if (details.delta.dy >= 0) {
      return;
    }

    setState(() {
      _dragExtent = math
          .min(_unlockThreshold, _dragExtent + (-details.delta.dy))
          .toDouble();
    });
    if (_dragExtent >= _unlockThreshold) {
      _triggerUnlock();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_unlockTriggered) {
      return;
    }
    if (details.primaryVelocity != null && details.primaryVelocity! < -560) {
      _triggerUnlock();
      return;
    }

    setState(() {
      _dragExtent = 0;
    });
  }

  /// 只有达到上滑阈值后才真正切到密码页，避免误触直接解锁。
  void _triggerUnlock() {
    if (_unlockTriggered) {
      return;
    }
    _unlockTriggered = true;
    widget.onSwipeUnlock();
  }

  @override
  Widget build(BuildContext context) {
    final visuals = _StartupVisuals.of(context);
    final timeText = DateFormat('HH:mm').format(_now);
    final dateText = DateFormat('M月d日 EEEE', 'zh_CN').format(_now);
    final swipeProgress =
        (_dragExtent / _unlockThreshold).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      body: _StartupScene(
        sceneKey: const Key('startup_lock_page'),
        visuals: visuals,
        child: GestureDetector(
          key: const Key('startup_lock_swipe_layer'),
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    timeText,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: visuals.primaryText,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: visuals.secondaryText,
                    ),
                  ),
                  const Spacer(),
                  Transform.translate(
                    offset: Offset(0, -24 * swipeProgress),
                    child: FrostPanel(
                      padding: const EdgeInsets.all(22),
                      borderRadius: 30,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: visuals.notificationBadge,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '微信',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: visuals.primaryText,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '小雪：我刚刚给你发了一张新照片，记得来看看哦～',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: visuals.secondaryText,
                                        height: 1.5,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Transform.translate(
                    offset: Offset(0, -48 * swipeProgress),
                    child: Column(
                      children: [
                        Container(
                          width: 128,
                          height: 38,
                          decoration: BoxDecoration(
                            color: visuals.badgeBackground,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: visuals.badgeBorder),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '上滑解锁',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: visuals.primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedOpacity(
                          opacity: 1 - swipeProgress * 0.6,
                          duration: const Duration(milliseconds: 120),
                          child: Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: visuals.secondaryText,
                            size: 30,
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
      ),
    );
  }
}

class _PasscodePage extends StatefulWidget {
  const _PasscodePage({
    required this.pageKey,
    required this.title,
    required this.description,
    required this.helperText,
    required this.onSubmit,
    this.errorText,
  });

  final Key pageKey;
  final String title;
  final String description;
  final String helperText;
  final String? errorText;
  final Future<void> Function(String passcode) onSubmit;

  @override
  State<_PasscodePage> createState() => _PasscodePageState();
}

class _PasscodePageState extends State<_PasscodePage> {
  String _value = '';
  bool _submitting = false;

  @override
  void didUpdateWidget(covariant _PasscodePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != null &&
        widget.errorText != oldWidget.errorText &&
        mounted) {
      setState(() {
        _value = '';
        _submitting = false;
      });
    }
  }

  void _appendDigit(String digit) {
    if (_submitting || _value.length >= 6) {
      return;
    }

    setState(() {
      _value = '$_value$digit';
    });

    if (_value.length == 6) {
      _submit();
    }
  }

  void _removeLastDigit() {
    if (_submitting || _value.isEmpty) {
      return;
    }

    setState(() {
      _value = _value.substring(0, _value.length - 1);
    });
  }

  /// 自定义数字键盘满 6 位后自动提交，尽量贴近 iOS 密码输入体验。
  Future<void> _submit() async {
    if (_submitting || _value.length != 6) {
      return;
    }

    setState(() {
      _submitting = true;
    });
    await widget.onSubmit(_value);
    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visuals = _StartupVisuals.of(context);

    return Scaffold(
      body: _StartupScene(
        sceneKey: widget.pageKey,
        visuals: visuals,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: FrostPanel(
                padding: const EdgeInsets.all(28),
                borderRadius: 32,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            visuals.accentPrimary,
                            visuals.accentSecondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: visuals.accentPrimary.withValues(alpha: 0.24),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: visuals.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: visuals.secondaryText,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PasscodeDots(valueLength: _value.length, visuals: visuals),
                    const SizedBox(height: 18),
                    Text(
                      _submitting ? '处理中...' : widget.helperText,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: visuals.secondaryText,
                        height: 1.5,
                      ),
                    ),
                    if (widget.errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.errorText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: visuals.errorText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _PasscodeKeypad(
                      visuals: visuals,
                      submitting: _submitting,
                      onDigitPressed: _appendDigit,
                      onDeletePressed: _removeLastDigit,
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

class _PasscodeDots extends StatelessWidget {
  const _PasscodeDots({
    required this.valueLength,
    required this.visuals,
  });

  final int valueLength;
  final _StartupVisuals visuals;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      children: List.generate(6, (index) {
        final filled = index < valueLength;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? visuals.accentPrimary : visuals.dotBackground,
            border: Border.all(
              color: filled ? visuals.accentPrimary : visuals.dotBorder,
              width: 1.4,
            ),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: visuals.accentPrimary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _PasscodeKeypad extends StatelessWidget {
  const _PasscodeKeypad({
    required this.visuals,
    required this.submitting,
    required this.onDigitPressed,
    required this.onDeletePressed,
  });

  final _StartupVisuals visuals;
  final bool submitting;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '<'],
    ];

    return Column(
      children: [
        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var columnIndex = 0; columnIndex < rows[rowIndex].length; columnIndex++)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildKey(context, rows[rowIndex][columnIndex]),
                ),
            ],
          ),
          if (rowIndex != rows.length - 1) const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildKey(BuildContext context, String value) {
    if (value.isEmpty) {
      return const SizedBox(width: 82, height: 82);
    }

    final isDelete = value == '<';
    final key = isDelete
        ? const Key('startup_keypad_backspace')
        : Key('startup_keypad_digit_$value');
    final label = isDelete ? '删除' : value;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(999),
          onTap: submitting
              ? null
              : () {
                  if (isDelete) {
                    onDeletePressed();
                  } else {
                    onDigitPressed(value);
                  }
                },
          child: Ink(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: visuals.badgeBackground,
              shape: BoxShape.circle,
              border: Border.all(color: visuals.badgeBorder),
            ),
            child: Center(
              child: isDelete
                  ? Icon(
                      Icons.backspace_outlined,
                      color: visuals.primaryText,
                      size: 28,
                    )
                  : Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: visuals.primaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupScene extends StatelessWidget {
  const _StartupScene({
    required this.sceneKey,
    required this.visuals,
    required this.child,
  });

  final Key sceneKey;
  final _StartupVisuals visuals;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sceneKey,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: visuals.backgroundGradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -76,
            left: -48,
            child: AccentOrb(
              color: visuals.accentPrimary,
              size: 240,
              opacity: visuals.orbOpacity,
            ),
          ),
          Positioned(
            right: -64,
            bottom: -88,
            child: AccentOrb(
              color: visuals.accentSecondary,
              size: 260,
              opacity: visuals.orbOpacity,
            ),
          ),
          Positioned(
            top: 180,
            right: 12,
            child: AccentOrb(
              color: visuals.accentSoft,
              size: 140,
              opacity: visuals.smallOrbOpacity,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _StartupVisuals {
  const _StartupVisuals({
    required this.backgroundGradient,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.accentSoft,
    required this.primaryText,
    required this.secondaryText,
    required this.badgeBackground,
    required this.badgeBorder,
    required this.notificationBadge,
    required this.dotBackground,
    required this.dotBorder,
    required this.errorText,
    required this.orbOpacity,
    required this.smallOrbOpacity,
  });

  final List<Color> backgroundGradient;
  final Color accentPrimary;
  final Color accentSecondary;
  final Color accentSoft;
  final Color primaryText;
  final Color secondaryText;
  final Color badgeBackground;
  final Color badgeBorder;
  final Color notificationBadge;
  final Color dotBackground;
  final Color dotBorder;
  final Color errorText;
  final double orbOpacity;
  final double smallOrbOpacity;

  static _StartupVisuals of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _StartupVisuals(
        backgroundGradient: [
          Color(0xFF2B1736),
          Color(0xFF161223),
          Color(0xFF0C1220),
        ],
        accentPrimary: Color(0xFFFF8FA3),
        accentSecondary: Color(0xFF7D8BFF),
        accentSoft: Color(0xFFFFC2D1),
        primaryText: Colors.white,
        secondaryText: Color(0xCCFFFFFF),
        badgeBackground: Color(0x1AFFFFFF),
        badgeBorder: Color(0x2EFFFFFF),
        notificationBadge: Color(0xFF6B7CFF),
        dotBackground: Color(0x14FFFFFF),
        dotBorder: Color(0x40FFFFFF),
        errorText: Color(0xFFFFB8C4),
        orbOpacity: 0.24,
        smallOrbOpacity: 0.18,
      );
    }

    return const _StartupVisuals(
      backgroundGradient: [
        Color(0xFFFFF2F5),
        Color(0xFFF8F2FB),
        Color(0xFFEAF3FF),
      ],
      accentPrimary: Color(0xFFFA7E98),
      accentSecondary: Color(0xFF7A8CFF),
      accentSoft: Color(0xFFFFC4D0),
      primaryText: Color(0xFF30243C),
      secondaryText: Color(0xFF6D627D),
      badgeBackground: Color(0xD9FFFFFF),
      badgeBorder: Color(0x1A6B4B73),
      notificationBadge: Color(0xFF6B7CFF),
      dotBackground: Color(0xFFF4ECF4),
      dotBorder: Color(0xFFD6C9D9),
      errorText: Color(0xFFD44A6A),
      orbOpacity: 0.18,
      smallOrbOpacity: 0.14,
    );
  }
}
