import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'frosted_glass_dock.dart';

/// 基于社区包 [liquid_glass_widgets] 的导航条实现。
///
/// 与仓库内自绘的 [FrostedGlassDock] 的差异：
/// - 自绘版：只有一个 `BackdropFilter` + `CustomPainter`，做磨砂与边缘勾边，
///   选中态是一枚在项目间流动的透镜（`SlidingGlassLens`）；
/// - 本版：把折射、色散、镜面高光交给包的 fragment shader 与 morph 引擎，
///   选中态由 `GlassTabBar` 内建处理。
///
/// 两版通过 [AppConfigProvider.dockImplementation] 切换，便于对比观感与性能。
///
/// ## 已知限制
///
/// 包只提供**底部**导航条，宽屏下的侧边导航仍由自绘版处理
/// （`GlassTabBar` 没有 vertical 变体）。因此 `axis == Axis.vertical` 时
/// 本组件会回退到 [FrostedGlassDock]。
class PackageGlassDock extends StatelessWidget {
  const PackageGlassDock({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.axis,
    required this.itemExtent,
    required this.duration,
  });

  final List<FrostedGlassDockItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Axis axis;
  final double itemExtent;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    // 包暂不支持侧边形态，回退到自绘版保证功能完整。
    if (axis == Axis.vertical || items.isEmpty) {
      return FrostedGlassDock(
        items: items,
        selectedIndex: selectedIndex,
        onSelected: onSelected,
        axis: axis,
        itemExtent: itemExtent,
        duration: duration,
      );
    }

    final safeIndex = selectedIndex.clamp(0, items.length - 1);

    return GlassContentAwareScope(
      child: GlassTabBar.bottom(
        selectedIndex: safeIndex,
        onTabSelected: onSelected,
        // 固定表面可以用 premium 质量；内容感知亮度让图标在深色背景上自动转亮。
        adaptiveBrightness: true,
        tabs: [
          for (final item in items)
            GlassTab(
              // item.icon 是 Widget（可能带更新红点），包接受任意 Widget。
              icon: item.icon,
              label: item.label,
            ),
        ],
      ),
    );
  }
}
