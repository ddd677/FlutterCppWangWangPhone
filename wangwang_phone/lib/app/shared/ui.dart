import 'dart:ui';

import 'package:flutter/material.dart';

class HomePalette {
  const HomePalette({
    required this.backgroundGradient,
    required this.panelBackground,
    required this.borderColor,
    required this.primaryText,
    required this.secondaryText,
    required this.iconSurface,
    required this.chipBackground,
  });

  final List<Color> backgroundGradient;
  final Color panelBackground;
  final Color borderColor;
  final Color primaryText;
  final Color secondaryText;
  final Color iconSurface;
  final Color chipBackground;

  /// 根据深浅色模式统一返回桌面和天气页所需配色，保证两套界面观感一致。
  static HomePalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const HomePalette(
        backgroundGradient: [
          Color(0xFF2A1630),
          Color(0xFF171126),
          Color(0xFF0E1322),
        ],
        panelBackground: Color(0x1FFFFFFF),
        borderColor: Color(0x2EFFFFFF),
        primaryText: Colors.white,
        secondaryText: Color(0xCCFFFFFF),
        iconSurface: Color(0x19FFFFFF),
        chipBackground: Color(0x14FFFFFF),
      );
    }

    return const HomePalette(
      backgroundGradient: [
        Color(0xFFFFF1F4),
        Color(0xFFF7F2FB),
        Color(0xFFEFF4FF),
      ],
      panelBackground: Color(0xCCFFFFFF),
      borderColor: Color(0x1F6B4B73),
      primaryText: Color(0xFF2D2238),
      secondaryText: Color(0xFF6A6078),
      iconSurface: Color(0xE8FFFFFF),
      chipBackground: Color(0xF5FFFFFF),
    );
  }
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
    final palette = HomePalette.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: palette.panelBackground,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: palette.borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AccentOrb extends StatelessWidget {
  const AccentOrb({
    super.key,
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class RoundActionButton extends StatelessWidget {
  const RoundActionButton({
    super.key,
    this.icon,
    this.progressColor,
    this.onTap,
  });

  final IconData? icon;
  final Color? progressColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: palette.iconSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.borderColor),
          ),
          alignment: Alignment.center,
          child: icon == null
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: progressColor ?? palette.primaryText,
                  ),
                )
              : Icon(icon, color: palette.primaryText, size: 20),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return Row(
      children: [
        RoundActionButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: palette.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.secondaryText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: palette.primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.secondaryText),
        ),
      ],
    );
  }
}

class PageLoadingCard extends StatelessWidget {
  const PageLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return FrostPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '正在加载天气...',
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

class PageErrorCard extends StatelessWidget {
  const PageErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return FrostPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: palette.primaryText,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              onRetry();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重新加载'),
          ),
        ],
      ),
    );
  }
}

class InlineHint extends StatelessWidget {
  const InlineHint({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: palette.secondaryText,
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.secondaryText),
          ),
        ),
      ],
    );
  }
}
