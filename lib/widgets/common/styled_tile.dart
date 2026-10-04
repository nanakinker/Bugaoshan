import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:bugaoshan/widgets/common/adaptive_widgets.dart';
import 'package:bugaoshan/theme_shape.dart';

/// Base tile with padding and optional InkWell tap.
class BaseTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BaseTile({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: child,
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppShapes.largeIncreased),
        child: tile,
      );
    }
    return tile;
  }
}

/// Icon container (36x36, rounded, primary tint).
class TileIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const TileIcon({super.key, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final iconChild = Icon(icon, color: primaryColor, size: 20);

    // 液态玻璃风格：图标底衬用玻璃小方块（能透出背后的卡片），
    // 而不是原先 primary @0.1 的实色圆角矩形——那是实心色块，不通透。
    if (useLiquidGlass(context)) {
      // 性能：图标底衬是**静态小方块**，用 minimal 档（不跑自定义
      // fragment shader）即可。设置页有十几行图标，降级后滚动更顺。
      // 不能用 RepaintBoundary 包裹：BackdropFilter 需要每帧重新采样
      // 背后内容，被 RepaintBoundary 缓存后会拿到**过期的（或空的）backdrop**，
      // 表现为「图标底衬变成黑方块」——用户反馈「进入三级页再退回，
      // 一半图标变黑」。这里直接渲染，让滤镜正常采样。
      // 不用 GlassCard：`GlassQuality.minimal` 下部分图标会出现
      // 底衬渲染成纯黑方块（用户反馈「一半图标变黑」，脚本取色确认
      // 黑块中心 #463E3C、四周 #FFFBFA → 是底衬黑，不是图标黑）。
      // 改用自绘 Container：模糊交给 BackdropFilter，描边与底色自己给，
      // 行为可预测。
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppShapes.medium),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(AppShapes.medium),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: SizedBox(width: 20, height: 20, child: iconChild),
          ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(AppShapes.medium),
      ),
      child: iconChild,
    );
  }
}

/// Common tile: icon + label + optional value + optional trailing.
class IconTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? value;
  final Widget? trailing;
  final Color? iconColor;
  final Color? labelColor;

  /// When true, suppress the auto-chevron even if [onTap] is provided.
  /// Used by subclasses ([BadgedTile], [LinkTile]) that manage their own trailing.
  final bool _suppressChevron;

  const IconTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.value,
    this.trailing,
    this.iconColor,
    this.labelColor,
  }) : _suppressChevron = false;

  const IconTile._internal({
    required this.icon,
    required this.label,
    this.onTap,
    this.value,
    this.trailing,
    this.iconColor,
  }) : _suppressChevron = true,
       labelColor = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseTile(
      onTap: onTap,
      child: Row(
        children: [
          TileIcon(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(color: labelColor),
            ),
          ),
          if (value != null)
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          if (trailing != null) ...[
            if (value != null) const SizedBox(width: 8),
            trailing!,
          ],
          if (onTap != null && !_suppressChevron) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ],
      ),
    );
  }
}

/// [IconTile] with a red dot badge next to the label.
class BadgedTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool showBadge;
  final Widget? trailing;

  const BadgedTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.showBadge = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge && trailing == null) {
      return IconTile(
        icon: icon,
        label: label,
        onTap: onTap,
        iconColor: iconColor,
      );
    }
    return IconTile._internal(
      icon: icon,
      label: label,
      onTap: onTap,
      iconColor: iconColor,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBadge) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (trailing != null)
            trailing!
          else ...[
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ],
      ),
    );
  }
}

/// [IconTile] with an external link icon (open_in_new).
class LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final String? value;

  const LinkTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return IconTile._internal(
      icon: icon,
      label: label,
      onTap: onTap,
      iconColor: iconColor,
      value: value,
      trailing: Icon(
        Icons.open_in_new,
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        size: 18,
      ),
    );
  }
}

/// [IconTile] variant with label and value stacked vertically.
class StackedTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final String? value;
  final IconData? trailing;

  const StackedTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BaseTile(
      onTap: onTap,
      child: Row(
        children: [
          TileIcon(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                if (value != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            trailing ?? Icons.chevron_right_rounded,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            size: 20,
          ),
        ],
      ),
    );
  }
}
