import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app_glass.dart';
import 'frosted_glass_dock.dart';

/// 竖排（侧边）导航栏的液态玻璃实现。
///
/// 包只提供了 `GlassTabBar.bottom`（横排），没有竖排变体，
/// 所以这里用底层 `GlassCard` 手工搭一个竖排导航：
/// - 外层：一个大药丸 `GlassCard` 作为导航容器（对应底部的横向药丸）；
/// - 内层：选中项套一个 `GlassCard` 作为指示器（对应底部的 indicator）。
///
/// 材质参数与底部横向栏保持一致，避免平板与手机观感割裂。
class VerticalLiquidGlassDock extends StatelessWidget {
  const VerticalLiquidGlassDock({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.itemExtent,
    required this.duration,
  });

  final List<FrostedGlassDockItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double itemExtent;
  final Duration duration;

  // 刻意不传 `settings` / `indicatorSettings`。
  //
  // 底纱色已在 main.dart 的 `GlassThemeData` 里按 light/dark 设好
  // （`GlassThemeSettings` 是部分覆盖语义：null = 沿用组件自身默认），
  // 所以这里不需要、也不应该再传 `LiquidGlassSettings` ——
  // 组件级 settings 是整体替换，会把库的整套光学预设丢掉。
  //
  // 也不要图省事写个 `=> null` 的 helper 传进去：`indicatorSettings` 参数
  // 要求非空 `LiquidGlassSettings`，传可空值会编译失败（踩过一次）。
  // 「不覆盖」的正确写法就是**整个参数不传**。

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final safeIndex = selectedIndex.clamp(0, items.length - 1);
    final radius = itemExtent / 2;

    return GlassCard(
      shape: LiquidRoundedRectangle(borderRadius: radius),
      quality: GlassQuality.premium,
      // 自建折射层 + 显式 settings：与顶栏时间框、按钮组同一规格。
      // 不自建层时 settings 只是 const 占位，浅色主题下等于透明玻璃
      // （用户反馈「描边不可见」）。数值对齐 Dock 的库预设。
      useOwnLayer: true,
      settings: AppGlass.of(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++)
              _VerticalTab(
                item: items[i],
                selected: i == safeIndex,
                extent: itemExtent,
                duration: duration,
                selectedColor: scheme.primary,
                unselectedColor: scheme.onSurfaceVariant,
                onTap: () => onSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _VerticalTab extends StatelessWidget {
  const _VerticalTab({
    required this.item,
    required this.selected,
    required this.extent,
    required this.duration,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final FrostedGlassDockItem item;
  final bool selected;
  final double extent;
  final Duration duration;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? selectedColor : unselectedColor;

    return GestureDetector(
      onTap: onTap,
      // 选中项套指示器玻璃；未选中项不套，保证透镜滑动时尺寸一致。
      child: Container(
        width: extent,
        height: extent,
        margin: const EdgeInsets.all(4),
        child: selected
            ? GlassCard(
                shape: LiquidRoundedRectangle(borderRadius: extent / 2),
                quality: GlassQuality.premium,
                useOwnLayer: true,
                settings: AppGlass.of(context),
                child: Center(
                  child: _TabContent(item: item, fg: fg),
                ),
              )
            : Center(
                child: _TabContent(item: item, fg: fg),
              ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({required this.item, required this.fg});

  final FrostedGlassDockItem item;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconTheme.merge(
          data: IconThemeData(size: 22, color: fg),
          child: item.icon,
        ),
        const SizedBox(height: 3),
        // 侧边栏标签旋转 90° 竖排显示，避免横向文字被压窄到看不清。
        RotatedBox(
          quarterTurns: 3,
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
