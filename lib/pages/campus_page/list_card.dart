import 'package:bugaoshan/widgets/common/styled_card.dart';
import 'package:flutter/material.dart';
import 'package:bugaoshan/theme_shape.dart';

/// Shared list-style card: icon container + title + desc + trailing widget.
class CampusListCard extends StatelessWidget {
  const CampusListCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.desc,
    this.trailing,
    this.iconContainerColor,
    this.iconColor,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String? desc;
  final Widget? trailing;
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
                alpha: colorScheme.brightness == Brightness.dark ? 0.28 : 0.18,
              )
            : colorScheme.primaryContainer);
    final foregroundColor =
        iconColor ?? accent ?? colorScheme.onPrimaryContainer;

    // 不传 staticGlass：走 [StyledCard] 的**自动判定**。
    // 校园页背后是 `scaffoldBackgroundColor` 纯色（全项目只有课表页有
    // 背景图），纯色被模糊后还是那个纯色 —— 实时采样在此页视觉上是空操作，
    // 却要为每张卡付一次整屏背景采样（一屏 24 张 → 每帧 24 次），
    // 这是滑动卡顿与「描边偶尔卡没」的根因。自动判定会选静态绘制：
    // 像素等价，成本与普通卡片相同。
    return StyledCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              // 图标块：**玻璃族**的半透明强调色 + 细描边。
              //
              // 原先这里是「不透明底色 + 上下两道光影」模拟立体 —— 视觉上
              // 是一块贴上去的塑料片（用户反馈「自绘描边风格框太丑」）。
              // 改为与 [GlassSpec] 同一套语言：淡色填充（强调色低透明度）
              // + 同色系描边，读起来是「玻璃上的一块彩色玻璃」。
              //
              // 不在此处再套一层 GlassCard：校园页有 20+ 个入口，每个再叠
              // 一层折射层会在滚动时同时光栅化 40+ 层，得不偿失。
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(AppShapes.large),
                border: Border.all(
                  color: foregroundColor.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Icon(icon, color: foregroundColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (desc != null && desc!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      desc!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ?trailing,
          ],
        ),
      ),
    );
  }
}
