import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../chat/chat_app_page.dart';
import '../chat/chat_controller.dart';
import '../chat/memory_app_page.dart';
import '../chat/chat_summary_store.dart';
import '../shared/ui.dart';
import '../weather/weather_detail_page.dart';
import '../weather/weather_repository.dart';
import '../weather/weather_settings.dart';
import '../weather/weather_widget_card.dart';

enum WangWangAppModule { chat, memory, diary, settings, weather }

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.weatherRepository,
    required this.weatherSettingsStore,
  });

  final WeatherRepository weatherRepository;
  final WeatherSettingsStore weatherSettingsStore;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final WeatherController _weatherController;
  late final TemperatureUnitController _temperatureUnitController;
  late final ChatAppController _chatController;
  late final AnimationController _iconJiggleController;
  bool _isEditingIcons = false;
  WangWangAppModule? _draggingModule;

  final List<_AppIconData> _items = [
    const _AppIconData(
      module: WangWangAppModule.chat,
      label: '微信',
      icon: Icons.chat_bubble_rounded,
      color: Color(0xFF5EDC7E),
      subtitle: '和 AI 好友聊天',
    ),
    const _AppIconData(
      module: WangWangAppModule.memory,
      label: '记忆',
      icon: Icons.psychology_alt_rounded,
      color: Color(0xFFFFA25A),
      subtitle: '查看 summary 和 memory',
    ),
    const _AppIconData(
      module: WangWangAppModule.diary,
      label: '日记',
      icon: Icons.menu_book_rounded,
      color: Color(0xFFEF7FB0),
      subtitle: '查看 diary 记录',
    ),
    const _AppIconData(
      module: WangWangAppModule.settings,
      label: '设置',
      icon: Icons.settings_rounded,
      color: Color(0xFF7D8BFF),
      subtitle: '管理系统与接口',
    ),
    const _AppIconData(
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
    _iconJiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
    );
    _weatherController = WeatherController(repository: widget.weatherRepository)
      ..loadWeather();
    _temperatureUnitController = TemperatureUnitController(
      store: widget.weatherSettingsStore,
    )..load();
    _chatController = ChatAppController.seeded(
      summaryStore: buildDefaultChatSummaryStore(),
    )..loadPersistedSummaries();
  }

  @override
  void dispose() {
    _iconJiggleController.dispose();
    _weatherController.dispose();
    _temperatureUnitController.dispose();
    _chatController.dispose();
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
                  animation: Listenable.merge([
                    _weatherController,
                    _temperatureUnitController,
                  ]),
                  builder: (context, _) {
                    return WeatherWidgetCard(
                      state: _weatherController.state,
                      temperatureUnit: _temperatureUnitController.unit,
                      onRefresh: _weatherController.loadWeather,
                      onOpenDetail: _openWeatherPage,
                    );
                  },
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _isEditingIcons ? _exitIconEditMode : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _isEditingIcons
                              ? Padding(
                                  key: const ValueKey('home_icon_edit_banner'),
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _EditModeBanner(
                                    onDone: _exitIconEditMode,
                                  ),
                                )
                              : const SizedBox(
                                  key: ValueKey('home_icon_edit_banner_hidden'),
                                ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            key: const Key('home_app_grid'),
                            physics: const BouncingScrollPhysics(),
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
                              return KeyedSubtree(
                                key: ValueKey(item.module),
                                child: _AppIcon(
                                  item: item,
                                  isEditing: _isEditingIcons,
                                  isDragging: _draggingModule == item.module,
                                  jiggleAnimation: _iconJiggleController,
                                  onTap: () => _openApp(item),
                                  onDragStarted: () =>
                                      _handleIconDragStarted(item),
                                  onDragMovedTo: (draggedItem) =>
                                      _reorderHomeIcons(draggedItem, item),
                                  onDragFinished: _handleIconDragFinished,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
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
                        (item) => _DockIcon(
                          item: item,
                          isEditing: _isEditingIcons,
                          onTap: () => _openApp(item),
                        ),
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
    if (_isEditingIcons) {
      _exitIconEditMode();
      return;
    }

    final page = switch (item.module) {
      WangWangAppModule.weather => WeatherDetailPage(
        controller: _weatherController,
        temperatureUnitController: _temperatureUnitController,
      ),
      WangWangAppModule.chat => ChatAppPage(controller: _chatController),
      WangWangAppModule.memory => MemoryAppPage(controller: _chatController),
      WangWangAppModule.diary => DiaryAppPage(controller: _chatController),
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
    if (_isEditingIcons) {
      _exitIconEditMode();
      return;
    }

    Navigator.of(context).push(
      _buildPageRoute(
        WeatherDetailPage(
          controller: _weatherController,
          temperatureUnitController: _temperatureUnitController,
        ),
      ),
    );
  }

  /// 长按桌面图标后进入整理态，并启动仿 iOS 的轻微抖动反馈。
  void _enterIconEditMode() {
    if (_isEditingIcons) {
      return;
    }

    HapticFeedback.mediumImpact();
    _iconJiggleController.repeat(reverse: true);
    setState(() {
      _isEditingIcons = true;
    });
  }

  void _exitIconEditMode() {
    if (!_isEditingIcons || _draggingModule != null) {
      return;
    }

    _iconJiggleController.stop();
    _iconJiggleController.value = 0;
    setState(() {
      _isEditingIcons = false;
    });
  }

  void _handleIconDragStarted(_AppIconData item) {
    _enterIconEditMode();
    if (_draggingModule == item.module) {
      return;
    }

    setState(() {
      _draggingModule = item.module;
    });
  }

  /// 拖拽过程中按目标格位实时换位，让图标跟手移动，而不是松手后才跳动。
  void _reorderHomeIcons(_AppIconData draggedItem, _AppIconData targetItem) {
    if (draggedItem.module == targetItem.module) {
      return;
    }

    final fromIndex = _items.indexWhere(
      (item) => item.module == draggedItem.module,
    );
    final toIndex = _items.indexWhere((item) => item.module == targetItem.module);
    if (fromIndex == -1 || toIndex == -1 || fromIndex == toIndex) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      final movedItem = _items.removeAt(fromIndex);
      _items.insert(toIndex, movedItem);
    });
  }

  void _handleIconDragFinished() {
    if (_draggingModule == null) {
      return;
    }

    setState(() {
      _draggingModule = null;
    });
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

class _EditModeBanner extends StatelessWidget {
  const _EditModeBanner({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return FrostPanel(
      key: const Key('home_icon_edit_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: palette.iconSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.drag_indicator_rounded,
              color: palette.primaryText,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '桌面整理中，长按拖动图标排序，点空白也能退出',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onDone,
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({
    required this.item,
    required this.isEditing,
    required this.isDragging,
    required this.jiggleAnimation,
    required this.onTap,
    required this.onDragStarted,
    required this.onDragMovedTo,
    required this.onDragFinished,
  });

  final _AppIconData item;
  final bool isEditing;
  final bool isDragging;
  final Animation<double> jiggleAnimation;
  final VoidCallback onTap;
  final VoidCallback onDragStarted;
  final ValueChanged<_AppIconData> onDragMovedTo;
  final VoidCallback onDragFinished;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_AppIconData>(
      onWillAcceptWithDetails: (details) {
        final draggedItem = details.data;
        if (draggedItem.module == item.module) {
          return false;
        }

        onDragMovedTo(draggedItem);
        return true;
      },
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;
        final iconFrame = _AppIconFrame(
          item: item,
          isEditing: isEditing,
          isDragging: isDragging,
          isDropTarget: isDropTarget,
          jiggleAnimation: jiggleAnimation,
        );

        return LongPressDraggable<_AppIconData>(
          data: item,
          hapticFeedbackOnStart: false,
          onDragStarted: onDragStarted,
          onDragEnd: (_) => onDragFinished(),
          feedback: Material(color: Colors.transparent, child: iconFrame),
          childWhenDragging: Opacity(
            opacity: 0.22,
            child: IgnorePointer(
              child: _AppIconFrame(
                item: item,
                isEditing: false,
                isDragging: false,
                isDropTarget: false,
                jiggleAnimation: const AlwaysStoppedAnimation<double>(0),
              ),
            ),
          ),
          child: Semantics(
            button: true,
            label: isEditing ? '拖动${item.label}' : '打开${item.label}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: Key('home_app_${item.module.name}'),
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                child: iconFrame,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppIconFrame extends StatelessWidget {
  const _AppIconFrame({
    required this.item,
    required this.isEditing,
    required this.isDragging,
    required this.isDropTarget,
    required this.jiggleAnimation,
  });

  final _AppIconData item;
  final bool isEditing;
  final bool isDragging;
  final bool isDropTarget;
  final Animation<double> jiggleAnimation;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return AnimatedBuilder(
      animation: jiggleAnimation,
      builder: (context, child) {
        final rotation =
            isDragging
                ? 0.045
                : isEditing
                ? math.sin(
                      (jiggleAnimation.value * math.pi * 2) +
                          (item.module.index * 0.85),
                    ) *
                    0.026
                : 0.0;

        return SizedBox(
          width: 74,
          child: Transform.rotate(
            angle: rotation,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              scale: isDragging ? 1.08 : (isDropTarget ? 0.96 : 1),
              child: child,
            ),
          ),
        ),
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(20),
              border: isDropTarget
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.84),
                      width: 1.4,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(alpha: isDragging ? 0.46 : 0.35),
                  blurRadius: isDragging ? 24 : 18,
                  offset: Offset(0, isDragging ? 14 : 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(child: Icon(item.icon, color: Colors.white, size: 32)),
                if (isEditing)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: item.color,
                        size: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.primaryText,
              fontWeight: isEditing ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  const _DockIcon({
    required this.item,
    required this.isEditing,
    required this.onTap,
  });

  final _AppIconData item;
  final bool isEditing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isEditing ? 0.72 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('home_dock_${item.module.name}'),
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
