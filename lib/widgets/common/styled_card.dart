import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:bugaoshan/widgets/common/adaptive_widgets.dart';
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

  const StyledCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = AppShapes.largeIncreased,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = backgroundColor ?? theme.colorScheme.surfaceContainerLow;
    final border = borderColor ?? theme.dividerColor.withValues(alpha: 0.1);

    // 液态玻璃风格：改用玻璃卡片，卡片内容随背景折射。
    // StyledCard 被全项目 80+ 处复用，因此这里一处改动即可全局生效。
    // 调用方显式指定了 backgroundColor 时视为「刻意要实底」，不套玻璃。
    if (useLiquidGlass(context) && backgroundColor == null) {
      // 性能：卡片是**静态内容**（不做形变），用 minimal 档——它不跑自定义
      // fragment shader，只做 BackdropFilter。全项目 80+ 处复用，若每张卡
      // 都跑完整 shader，滚动时几十个实例同时光栅化，是掉帧与发热主因。
      //
      // minimal 档不跑 shader，**描边与高光要自己给**，否则深色模式下
      // 玻璃卡会「消失」（用户反馈：描边不清晰、啥都看不见）。
      final isDark = theme.brightness == Brightness.dark;
      Widget glassChild = child;
      if (onTap != null) {
        glassChild = InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: child,
        );
      }
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          // 深色下描边必须更亮才看得见——深灰玻璃配深色描边会糊成一片。
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.10),
            width: 1,
          ),
          boxShadow: [
            // 顶部高光，给玻璃厚度
            BoxShadow(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.45),
              blurRadius: 6,
              offset: const Offset(0, -1),
              spreadRadius: -3,
            ),
          ],
        ),
        child: glassChild,
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
