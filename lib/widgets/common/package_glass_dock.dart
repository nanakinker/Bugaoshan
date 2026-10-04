import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'frosted_glass_dock.dart';
import 'vertical_glass_dock.dart';

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
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // 竖排（侧边导航）：包只提供了 GlassTabBar.bottom，没有竖排变体，
    // 这里改用同材质的自组装竖版（VerticalLiquidGlassDock），
    // 避免平板上又退回自绘毛玻璃、与手机观感割裂。
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDarkTheme = theme.brightness == Brightness.dark;

    return GlassContentAwareScope(
      child: GlassTabBar.bottom(
        selectedIndex: safeIndex,
        onTabSelected: onSelected,
        // 固定表面可以用 premium 质量；内容感知亮度让图标在深色背景上自动转亮。
        adaptiveBrightness: true,
        // 标签与图标颜色必须**显式**指定：包有自己的一套默认色（偏浅），
        // 浅色主题下会变成「浅底白字」完全看不见（用户反馈）。
        // 这里的取色规则与自绘版 FrostedGlassDock 保持一致：
        // 选中 primary、未选中 onSurfaceVariant。
        selectedIconColor: scheme.primary,
        unselectedIconColor: scheme.onSurfaceVariant,
        selectedLabelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        // 质量档：**premium**（Impeller 16-shape 完整管线）。
        //
        // 这里从standard 换回 premium，是因为只有 premium 才真正计算
        // 折射与色散——standard 只做基础两阶段，`refractiveIndex` /
        // `chromaticAberration` 这些参数在它下**不生效**，导航条会显得
        // 「干净但平」，没有玻璃的散射感。
        //
        // 代价是滑动时每帧重算 shader。已通过给静态卡片降级
        // （StyledCard / styled_tile 用 minimal + RepaintBoundary）
        // 把滚动开销挪走，导航条这里可以用 premium。
        quality: GlassQuality.premium,
        // 混合强度：默认 10 会把背景拉成「彩虹 smear」，0 则完全失去流动感。
        // 参考图（酷安）是**背景可辨但被玻璃包裹**，取中间值 5。
        blendAmount: 5,
        // 显式传 settings，确保不被组件自身默认覆盖。
        settings: isDarkTheme
            ? const LiquidGlassSettings(
                thickness: 10,
                blur: 4,
                // 近黑纱：把玻璃压到比纯黑背景略浅一档的深灰
                // 底纱更透明（0.78 -> 0.42）：玻璃要"透"而不是"压"，
                // 背景内容能真正透出来。
                glassColor: Color.fromRGBO(14, 14, 14, 0.32),
                lightIntensity: 0.22,
                // 下面三个是把玻璃「发白」的元凶，默认值都会加光：
                //   fresnelStrength 1.0 —— 菲涅尔边缘发光，整圈泛白
                //   glowIntensity 0.75 —— 交互辉光
                //   shadowElevation 1.0 —— 投影抬亮
                fresnelStrength: 0,
                glowIntensity: 0,
                shadowElevation: 0,
                ambientStrength: 0,
                ambientRim: 0,
                rimLight: 0,
                rimShade: 0,
                whitenStrength: 0,
                edgeAbsorption: 0,
                // 折射率与色散是「流光溢彩」的来源：折射率越高，
                // 边缘把背景压缩得越厉害；色散则在压缩处产生红蓝彩边。
                // 折射率与色散：premium 档下这两个才真正生效。
                // 参考图（酷安）的滑动瞬间边缘有明显的红蓝彩边，
                // 所以数值给得比较高；再高会变成刺眼的彩虹。
                // 四周色散提高：折射率与色散都往上推，边缘的彩边更明显。
                refractiveIndex: 1.75,
                saturation: 1.35,
                chromaticAberration: 0.075,
              )
            : const LiquidGlassSettings(
                thickness: 12,
                blur: 3,
                // 亮色同样降透明度、提高色散，与暗色保持一致的玻璃语言
                glassColor: Color.fromRGBO(255, 255, 255, 0.26),
                lightIntensity: 0.5,
                ambientStrength: 0,
                refractiveIndex: 1.5,
                saturation: 1.15,
                chromaticAberration: 0.05,
              ),
        // 选中指示器单独配置。
        //
        // 默认指示器是一颗**亮灰色实心圆 + 白环**，在深色药丸上像「挖了个洞」，
        // 与参考图差别很大。参考图里选中态与药丸**几乎同色**、半透明，
        // 只靠一圈细微的折射彩边区分——靠"透"而不是"亮"来表达选中。
        indicatorColor: isDarkTheme
            ? const Color(0x14FFFFFF)
            : const Color(0x1A000000),
        indicatorSettings: isDarkTheme
            ? const LiquidGlassSettings(
                thickness: 8,
                blur: 2,
                // 暗色模式：指示器要**比药丸更透**，不是更实。
                // 脚本取色实测：药丸 #36353A、指示器 #36353A —— 两者
                // 完全同色，所以看不出边界（用户反馈「又不透明了」）。
                // 这里只留极薄一层墨纱（@0.28），靠透度差 + 边缘高光
                // 把透镜勾出来，而不是靠实色填充。
                glassColor: Color.fromRGBO(10, 10, 12, 0.28),
                lightIntensity: 0.30,
                fresnelStrength: 0.45,
                glowIntensity: 0,
                shadowElevation: 0,
                ambientStrength: 0,
                rimShade: 0,
                whitenStrength: 0,
                edgeAbsorption: 0,
                // 折射率提高 + 色散加强 → 边缘出现细微彩边，这是"液体感"的来源
                // 指示器配套：降饱和（避免纯白发灰）、保留高光与色散
                refractiveIndex: 1.5,
                saturation: 0.9,
                chromaticAberration: 0.055,
              )
            : const LiquidGlassSettings(
                thickness: 8,
                blur: 2,
                // 浅色模式：截图里透镜是**浅灰**（约 #D5D0CE），
                // 不是纯白。纯白在浅色药丸上看不出边界，滑动时更看不清。
                // 用带一点灰的白纱 0.72，既能看见又不显得脏。
                glassColor: Color.fromRGBO(236, 234, 233, 0.72),
                lightIntensity: 0.35,
                fresnelStrength: 0.2,
                glowIntensity: 0,
                shadowElevation: 0,
                refractiveIndex: 1.5,
                saturation: 1.15,
                chromaticAberration: 0.05,
              ),
        tabs: [
          for (var i = 0; i < items.length; i++)
            GlassTab(
              // item.icon 是 Widget（可能带更新红点），包接受任意 Widget。
              //
              // 取色：包会按自己的默认色渲染图标与标签，在课表这类彩色背景上
              // 会显得发灰、读不清。这里显式套IconTheme + DefaultTextStyle，
              // 统一到 app 自己的取色规则——与自绘版 FrostedGlassDock 保持一致：
              // 选中用 primary，未选中用 onSurfaceVariant。
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
      ),
    );
  }
}
