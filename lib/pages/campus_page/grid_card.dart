import 'package:bugaoshan/widgets/common/styled_card.dart';
import 'package:flutter/material.dart';
import 'package:bugaoshan/theme_shape.dart';

/// Shared grid-style card: icon container + title (vertical layout).
class CampusGridCard extends StatelessWidget {
  const CampusGridCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconContainerColor,
    this.iconColor,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final Color? iconContainerColor;
  final Color? iconColor;

  /// 强调色。传入后自动派生柔和的图标容器底色与图标色；
  /// 优先级低于显式指定的 [iconContainerColor] / [iconColor]。
  final Color? accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = accentColor;
    final containerColor =
        iconContainerColor ??
        (accent != null
            ? accent.withValues(
                alpha: colorScheme.brightness == Brightness.dark ? 0.24 : 0.14,
              )
            : colorScheme.primaryContainer);
    final foregroundColor =
        iconColor ?? accent ?? colorScheme.onPrimaryContainer;

    return StyledCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppShapes.medium),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(AppShapes.large),
              // 玻璃质感：顶部高光 + 底部内阴影。底色仍不透明（保留功能
              // 类别的可扫读性），只加厚度感——纯色块看起来像「贴纸」。
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.14
                        : 0.60,
                  ),
                  blurRadius: 7,
                  offset: const Offset(0, -1),
                  spreadRadius: -3,
                ),
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.34
                        : 0.10,
                  ),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Icon(icon, color: foregroundColor, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
