import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:bugaoshan/widgets/common/adaptive_widgets.dart';
import 'package:bugaoshan/widgets/common/app_glass.dart';
import 'package:bugaoshan/widgets/common/live_backdrop_scope.dart';
import 'package:bugaoshan/theme_shape.dart';

/// 统一卡片样式外壳。
///
/// 只负责"卡片样式"这一件事：背景、圆角、描边、裁剪、可选的整体点击
/// 水波纹。不负责内容组织（分组、分隔线等），那是上层组件（如 InfoCard）
/// 的职责——上层组件把拼好的内容作为 [child] 传进来即可。
///
/// 视觉规范对齐 InfoCard（"about page" 风格）：
/// - 背景 `colorScheme.surface`
/// - 圆角 [AppShapes.largeIncreased]
/// - 描边 `dividerColor.withValues(alpha: 0.08)`，宽度 1
/// - `Container` 提供描边与圆角裁剪，`Material` 提供不透明背景以承载
///   `InkWell` 水波纹
/// - 无 elevation
///
/// [padding] / [margin] 默认为 null，由调用方显式控制，避免和子内容
/// （如分组 tile）自带的 padding 冲突。
class StyledCard extends StatelessWidget {
  /// 卡片内容。
  final Widget child;

  /// 内边距。默认不施加，由调用方控制。
  final EdgeInsetsGeometry? padding;

  /// 外边距。默认不施加。
  final EdgeInsetsGeometry? margin;

  /// 点击回调。非 null 时整体包裹 `InkWell`。
  final VoidCallback? onTap;

  /// 圆角半径，默认 [AppShapes.largeIncreased]。
  final double borderRadius;

  final Color? backgroundColor;

  final Color? borderColor;

  /// 玻璃渲染档位（仅玻璃模式下生效）。
  ///
  /// 默认 [GlassQuality.standard] —— 包文档明确建议：**可滚动列表里用
  /// standard**（轻量 shader，「5-10x faster than BackdropFilter」且
  /// 「works correctly during scrolling」）；[GlassQuality.premium] 只适用
  /// 于「静态、不可滚动的布局」，用在列表卡片上**每帧每张卡都会调用一次
  /// 全量 shader**，是滚动掉帧的主因（用户反馈「页面滑动非常卡顿」）。
  ///
  /// 一屏内玻璃卡特别多（如校园页 20+ 个功能入口）时，传
  /// [GlassQuality.minimal]：零 shader，成本与卡片数无关。
  final GlassQuality quality;

  /// 是否走**静态玻璃**（不采样背景，直接以半透明底纱 + 描边 + 高光绘制）。
  ///
  /// 适用条件：卡片背后是**不随滚动变化的纯色背景**（如校园页 —— 页面
  /// 背景就是 `scaffoldBackgroundColor`，没有背景图）。
  ///
  /// 为什么此时可以且应该去掉滤镜：**对纯色做高斯模糊，结果还是那个纯色** ——
  /// `BackdropFilter` 在此页面上视觉上是**空操作**，但每张卡仍要付出
  /// 「保存背景 → 模糊 → 还原」的整屏合成开销。校园页一屏 24 张卡，
  /// 即每帧 24 次整屏背景采样，这是滑动掉帧、甚至描边被丢弃（用户反馈
  /// 「有时候描边都卡没了」）的直接原因。
  ///
  /// 改为静态绘制后：每张卡的成本降到「一个圆角矩形填充 + 一圈描边」，
  /// 与普通卡片相同；因为背后的纯色被模糊后本来就是同一个色，
  /// **观感与带滤镜版本完全一致**。
  ///
  /// 背后有背景图的页面（如带自选壁纸的课表页）不要开这个开关 ——
  /// 那里的模糊是真实可见的。
  /// `null` = **自动**：无 [LiveBackdropScope] 标记时用静态玻璃
  /// （全项目只有课表页有背景图，其余页面背后都是纯色）；标了才用实时采样。
  final bool? staticGlass;

  const StyledCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = AppShapes.largeIncreased,
    this.backgroundColor,
    this.borderColor,
    this.quality = GlassQuality.standard,
    this.staticGlass,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = backgroundColor ?? theme.colorScheme.surfaceContainerLow;
    final border = borderColor ?? theme.dividerColor.withValues(alpha: 0.1);

    // 液态玻璃风格：改用**真实液态玻璃卡片**（`GlassCard`）。
    //
    // StyledCard 被全项目 40+ 个页面复用，这里一处改动即全局生效。
    // 调用方显式指定了 backgroundColor 时视为「刻意要实底」，不套玻璃。
    //
    // 历史：这里曾经是自绘的「描边 + 顶部高光」Container（当时的理由是
    // 卡片属静态内容、用 minimal 档省性能）。但 minimal 不跑 shader、
    // 也没有底纱填充，只画了一圈描边 —— 在校园页等功能入口密集的页面上
    // 呈现为「空心的描边框」，用户反馈「自绘描边风格框太丑」。
    //
    // 现在改为 `GlassCard(useOwnLayer: true)`：底纱、折射、描边、高光
    // 全部由包统一提供，与顶部时间框、Dock、玻璃输入框的材质一致。
    // 性能上仍可控：`GlassCard` 的底纱与折射在 premium 档一次光栅化，
    // 卡片不做形变，实测与 minimal 档的滚动开销相当。
    // 自动判定：没有 LiveBackdropScope 标记（即背后是纯色）时用静态玻璃。
    final bool useStaticGlass =
        staticGlass ?? !LiveBackdropScope.of(context);

    // 静态玻璃：背后是纯色时用「画出来的玻璃」代替「滤镜算出来的玻璃」。
    // 像素等价（纯色模糊后还是纯色），成本从「整屏背景采样」降到
    // 「一个圆角矩形」，是校园页这类 20+ 卡片页面消除掉帧的关键。
    if (useStaticGlass && useLiquidGlass(context) && backgroundColor == null) {
      final isDark = theme.brightness == Brightness.dark;
      Widget staticChild = child;
      if (padding != null) {
        staticChild = Padding(padding: padding!, child: staticChild);
      }
      if (onTap != null) {
        staticChild = InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: staticChild,
        );
      }
      return RepaintBoundary(
        child: Container(
          margin: margin,
          clipBehavior: Clip.antiAlias,
          // GlassSpec.decoration：与真玻璃同一套底纱浓度 / 描边 / 顶部高光，
          // 所以静态版与滤镜版在同一屏里看不出差别。
          decoration: GlassSpec.decoration(
            isDark,
            radius: borderRadius,
          ),
          child: staticChild,
        ),
      );
    }

    if (useLiquidGlass(context) && backgroundColor == null) {
      Widget glassChild = child;
      if (onTap != null) {
        glassChild = InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: child,
        );
      }
      // RepaintBoundary：卡片内容在滚动时**相对自身不变**，把它的绘制
      // 结果缓存成独立图层，滚动帧就不必重新绘制卡片内部的文字与图标，
      // 只需重采样玻璃背景。配合 standard 档（无全量 shader）后，
      // 滚动时每张卡的成本降到「一次轻量背景采样 + 一次图层合成」。
      return RepaintBoundary(
        child: GlassCard(
          margin: margin,
          padding: padding ?? EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          quality: quality,
          // useOwnLayer: true —— 自建折射层。项目内没有祖先玻璃层，
          // grouped 模式下会拿不到 settings（等于完全透明玻璃）。
          useOwnLayer: true,
          settings: AppGlass.of(context),
          shape: LiquidRoundedRectangle(borderRadius: borderRadius),
          child: glassChild,
        ),
      );
    }

    Widget body = child;
    if (padding != null) {
      body = Padding(padding: padding!, child: body);
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? body
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: body,
              ),
      ),
    );
  }
}

Widget titleText(String text) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
    child: Text(
      text,
      textScaler: const TextScaler.linear(1.3),
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
  );
}

class CardWithTitle extends StatelessWidget {
  final String title;
  final Widget? icon;
  final Widget? child;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final void Function()? onTap;

  /// 是否在标题后显示红色必填标记 `*`（办事大厅动态表单用）。
  final bool requiredMark;
  const CardWithTitle({
    super.key,
    required this.title,
    this.icon,
    this.child,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.requiredMark = false,
  });

  @override
  Widget build(BuildContext context) {
    return StyledCard(
      backgroundColor: backgroundColor,
      onTap: onTap,
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expanded 让长标题（如 337 返校校区的完整说明）换行而非溢出
                Expanded(
                  child: requiredMark
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: title),
                                TextSpan(
                                  text: ' *',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            textScaler: const TextScaler.linear(1.3),
                          ),
                        )
                      : titleText(title),
                ),
                icon ?? Container(),
              ],
            ),
            child ?? Container(),
          ],
        ),
      ),
    );
  }
}
