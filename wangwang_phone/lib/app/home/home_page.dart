import 'package:flutter/material.dart';

import '../shared/ui.dart';
import '../weather/weather_detail_page.dart';
import '../weather/weather_repository.dart';
import '../weather/weather_widget_card.dart';

enum WangWangAppModule { chat, settings, weather }

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.weatherRepository});

  final WeatherRepository weatherRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final WeatherController _weatherController;

  final List<_AppIconData> _items = const [
    _AppIconData(
      module: WangWangAppModule.chat,
      label: '微信',
      icon: Icons.chat_bubble_rounded,
      color: Color(0xFF5EDC7E),
      subtitle: '和 AI 好友聊天',
    ),
    _AppIconData(
      module: WangWangAppModule.settings,
      label: '设置',
      icon: Icons.settings_rounded,
      color: Color(0xFF7D8BFF),
      subtitle: '管理系统与接口',
    ),
    _AppIconData(
      module: WangWangAppModule.weather,
      label: '天气',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFFFB65C),
      subtitle: '查看 7 日天气趋势',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _weatherController = WeatherController(repository: widget.weatherRepository)
      ..loadWeather();
  }

  @override
  void dispose() {
    _weatherController.dispose();
    widget.weatherRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _weatherController,
                  builder: (context, _) {
                    return WeatherWidgetCard(
                      state: _weatherController.state,
                      onRefresh: _weatherController.loadWeather,
                      onOpenDetail: _openWeatherPage,
                    );
                  },
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: GridView.builder(
                    itemCount: _items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 24,
                          childAspectRatio: 0.82,
                        ),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _AppIcon(item: item, onTap: () => _openApp(item));
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
                      ..._items.map(
                        (item) =>
                            _DockIcon(item: item, onTap: () => _openApp(item)),
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: palette.iconSurface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          color: palette.primaryText,
                          size: 26,
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

  /// 统一处理桌面图标跳转，后续补真实聊天页和设置页时只需要替换目标页面。
  void _openApp(_AppIconData item) {
    final page = switch (item.module) {
      WangWangAppModule.weather => WeatherDetailPage(
        controller: _weatherController,
      ),
      WangWangAppModule.chat => _PlaceholderAppPage(
        item: item,
        title: '微信',
        description: '消息列表、联系人和朋友圈入口已经打通，下一步继续接聊天数据与 AI 回复。',
        roadmap: const ['聊天列表', '联系人导入', '朋友圈动态'],
      ),
      WangWangAppModule.settings => _PlaceholderAppPage(
        item: item,
        title: '设置',
        description: '启动设置、API 配置和数据管理会在这里继续接入，桌面导航已经可直接进入。',
        roadmap: const ['启动设置', 'API 配置', '数据导入导出'],
      ),
    };

    Navigator.of(context).push(_buildPageRoute(page));
  }

  void _openWeatherPage() {
    Navigator.of(
      context,
    ).push(_buildPageRoute(WeatherDetailPage(controller: _weatherController)));
  }
}

PageRoute<T> _buildPageRoute<T>(Widget child) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, page) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: page,
        ),
      );
    },
  );
}

class _PlaceholderAppPage extends StatelessWidget {
  const _PlaceholderAppPage({
    required this.item,
    required this.title,
    required this.description,
    required this.roadmap,
  });

  final _AppIconData item;
  final String title;
  final String description;
  final List<String> roadmap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = [
      Color.lerp(
        palette.backgroundGradient.first,
        item.color,
        isDark ? 0.2 : 0.28,
      )!,
      palette.backgroundGradient[1],
      palette.backgroundGradient.last,
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: gradient)),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: AccentOrb(
                color: item.color,
                size: 220,
                opacity: isDark ? 0.2 : 0.16,
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  PageHeader(
                    title: title,
                    subtitle: item.subtitle,
                    onBack: () {
                      Navigator.of(context).maybePop();
                    },
                    trailing: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.iconSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: palette.borderColor),
                      ),
                      alignment: Alignment.center,
                      child: Icon(item.icon, color: item.color, size: 24),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FrostPanel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: item.color,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: item.color.withValues(alpha: 0.24),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(item.icon, color: Colors.white, size: 34),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '$title 已接入桌面打开流程',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: palette.primaryText,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: palette.secondaryText,
                                height: 1.6,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionTitle(title: '当前规划', subtitle: '按 TODO 继续往下接功能'),
                  const SizedBox(height: 12),
                  ...roadmap.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RoadmapTile(color: item.color, title: feature),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadmapTile extends StatelessWidget {
  const _RoadmapTile({required this.color, required this.title});

  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return FrostPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 22,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: palette.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.item, required this.onTap});

  final _AppIconData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return Semantics(
      button: true,
      label: '打开${item.label}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Column(
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
                ).textTheme.bodyMedium?.copyWith(color: palette.primaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  const _DockIcon({required this.item, required this.onTap});

  final _AppIconData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: palette.iconSurface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(item.icon, color: palette.primaryText, size: 26),
        ),
      ),
    );
  }
}

class _AppIconData {
  const _AppIconData({
    required this.module,
    required this.label,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  final WangWangAppModule module;
  final String label;
  final IconData icon;
  final Color color;
  final String subtitle;
}
