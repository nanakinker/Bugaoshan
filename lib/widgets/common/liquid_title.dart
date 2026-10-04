import 'package:flutter/material.dart';

/// 会「横向滑动 + 形变」的 AppBar 大标题。
///
/// 动效对齐底部导航的共享玻璃透镜：`index` 变化时旧标题向左滑出、
/// 新标题从右侧滑入，交叉淡入淡出（不是单纯的淡入淡出）。
///
/// 用于「标题不变但下方Tab 在切换」的场景（如成绩统计页：标题恒为
/// 「成绩统计」，下方三个 Tab 切换时标题跟着滑一下，强化层级关系）。
/// 若标题本身也要变，直接把 [text] 换成随index 变化的值即可。
///
/// 用法：
/// ```dart
/// AppBar(
///   title: LiquidTitle(
///     text: l10n.gradesStats,
///     index: _currentIndex,   // 变化即触发一次滑动
///   ),
/// )
/// ```
class LiquidTitle extends StatelessWidget {
  const LiquidTitle({
    super.key,
    required this.text,
    this.index = 0,
    this.style,
  });

  /// 当前标题文本。
  final String text;

  /// 触发滑动的序号：值变化即播放一次横向滑动。
  final int index;

  /// 标题样式；不传则用主题的 titleLarge。
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ?? theme.textTheme.titleLarge;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      // 交叉淡入淡出：旧标题淡出时新标题已滑入，避免中间出现空白。
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(index);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            // 新标题从右滑入、旧标题向左滑出，形成横向连续感。
            position: Tween<Offset>(
              begin: Offset(incoming ? 0.35 : -0.35, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        text,
        key: ValueKey(index),
        style: base,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// [LiquidTitle] 的 AppBar 便捷封装。
///
/// 直接替换 `AppBar(title: Text('xxx'))`，其余参数（actions、返回键等）
/// 保持原样，只把标题换成滑动版。
class LiquidTitleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LiquidTitleAppBar({
    super.key,
    required this.text,
    this.index = 0,
    this.actions,
    this.leading,
    this.bottom,
  });

  final String text;
  final int index;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      actions: actions,
      bottom: bottom,
      title: LiquidTitle(text: text, index: index),
    );
  }
}
