import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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

  /// 与 `PackageGlassDock` 的横向栏同一套参数。
  static LiquidGlassSettings _surface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LiquidGlassSettings(
      thickness: 10,
      blur: 3,
      glassColor: isDark
          ? const Color.fromRGBO(28, 28, 30, 0.55)
          : const Color.fromRGBO(255, 255, 255, 0.26),
      lightIntensity: isDark ? 0.22 : 0.45,
      ambientStrength: 0.10,
      fresnelStrength: 0.35,
      glowIntensity: 0,
      shadowElevation: 0,
      refractiveIndex: 1.75,
      saturation: 1.35,
      chromaticAberration: 0.075,
    );
  }

  /// 选中指示器：与横向栏同逻辑，靠「透度差 + 边缘光」勾出边界，
  /// 而不是靠实色填充。
  static LiquidGlassSettings _indicator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LiquidGlassSettings(
      thickness: 8,
      blur: 2,
      glassColor: isDark
          ? const Color.fromRGBO(10, 10, 12, 0.28)
          : const Color.fromRGBO(236, 234, 233, 0.72),
      lightIntensity: isDark ? 0.30 : 0.50,
      ambientStrength: 0.10,
      fresnelStrength: 0.45,
      glowIntensity: 0,
      shadowElevation: 0,
      refractiveIndex: 1.5,
      saturation: 0.9,
      chromaticAberration: 0.055,
    );
  }

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
      quality: GlassQuality.standard,
      settings: _surface(context),
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
                indicatorSettings: _indicator(context),
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
    required this.indicatorSettings,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final FrostedGlassDockItem item;
  final bool selected;
  final double extent;
  final Duration duration;
  final LiquidGlassSettings indicatorSettings;
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
                quality: GlassQuality.standard,
                settings: indicatorSettings,
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
