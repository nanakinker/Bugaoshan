import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app_glass.dart';
import 'frosted_glass_dock.dart';
import 'vertical_glass_dock.dart';

/// 基于社区包 [liquid_glass_widgets] 的导航条实现。
///
/// ## 设计原则（对齐官方 SKILL.md）
///
/// 官方把玻璃定位为「浮在内容之上的导航层」，主模式是
/// `GlassScaffold(background: ..., bottomBar: GlassTabBar.bottom(...))`。
/// `GlassScaffold` 负责三件我们自己做不出来的事：
/// 1. 提供**背景采样源**（`background` + `enableBackgroundSampling`）——
///    折射/色散必须有可采样的东西behind 才能算出来，没有它玻璃就是一块死色；
/// 2. 保证 z-order（内容不会盖住导航栏）；
/// 3. 自动边缘淡出与安全区内边距。
///
/// 所以**这里刻意不传 `settings`**，用库自带的深浅色默认值：
/// 之前的实现把 fresnel / glow / ambient / rim / whiten 等十几个参数
/// 全部手动置 0，等于把渲染管线掏空，只剩一层纯色半透明 —— 那不是液态玻璃。
/// 「让效果和库上一致」的正确做法就是**别覆盖它的默认值**。
///
/// 仅保留两类覆盖：
/// - **颜色**：图标/标签配色跟随 app 主题（否则浅色主题下变成浅底白字）。
///   这是内容可读性，不是玻璃外观。
/// - **quality: premium**：官方 Rule 5 明确 premium 专供常驻导航栏，
///   只有它才真正计算折射与色散。
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
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // 竖排（侧边导航）：包只提供 GlassTabBar.bottom，没有竖排变体，
    // 这里用同材质的自组装竖版，避免平板上退回自绘毛玻璃、与手机观感割裂。
    if (axis == Axis.vertical) {
      return VerticalLiquidGlassDock(
        items: items,
        selectedIndex: selectedIndex,
        onSelected: onSelected,
        itemExtent: itemExtent,
        duration: duration,
      );
    }

    final safeIndex = selectedIndex.clamp(0, items.length - 1);
    final scheme = Theme.of(context).colorScheme;

    return GlassContentAwareScope(
      child: GlassTabBar.bottom(
        selectedIndex: safeIndex,
        onTabSelected: onSelected,
        tabs: [
          for (var i = 0; i < items.length; i++)
            GlassTab(
              icon: IconTheme.merge(
                data: IconThemeData(
                  size: 24,
                  color: i == safeIndex
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                child: items[i].icon,
              ),
              label: items[i].label,
            ),
        ],
        // 内容感知亮度：让玻璃在浅色背景上自动压暗描边、深色背景上提亮，
        // 不用手工按主题切两套数值。
        adaptiveBrightness: true,
        // 官方 Rule 5：premium 专供常驻导航栏（色散 + 真实折射 + 动态高光）。
        // GlassScaffold 也会自动把它的 bar 提升到 premium。
        quality: GlassQuality.premium,
        // 配色跟随 app 主题，保证可读性。
        selectedIconColor: scheme.primary,
        unselectedIconColor: scheme.onSurfaceVariant,
        selectedLabelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        // 玻璃参数：全部走 [AppGlass]，与其他三处玻璃件共用同一份数值。
        //
        // 此前这里是唯一自己写死 settings 的地方，浅色用 24% 白而顶栏用
        // 55% 冷白，导致「顶栏玻璃背景有点太黑」（用户反馈）。
        // 抽到 AppGlass 后四处完全一致。
        //
        // 之所以必须显式传：组件级 settings 是**整体替换**而非合并
        // （`tab_bar_bottom_layout.dart:256`），传一个只带颜色的
        // LiquidGlassSettings 会把 thickness / blur / 折射 / 色散全丢掉。
        settings: AppGlass.of(context),
      ),
    );
  }
}
