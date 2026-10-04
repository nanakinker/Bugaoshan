import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 全局「是否使用液态玻璃材质」的读取入口。
///
/// 供各类封装组件在运行时决定渲染 Material 组件还是包的玻璃组件。
/// 这样切换主题样式后所有已封装的组件会一起变化，无需重启。
bool useLiquidGlass(BuildContext context) =>
    AppConfigScope.of(context).usePackageGlassDock;

/// 把主题样式开关暴露到 InheritedWidget 里，供 [useLiquidGlass] 读取。
///
/// 放在根部可确保所有封装组件都能访问，且配置变化时依赖它的组件会重建。
class AppConfigScope extends InheritedWidget {
  const AppConfigScope({
    super.key,
    required this.usePackageGlassDock,
    required super.child,
  });

  final bool usePackageGlassDock;

  /// 从最近的 [AppConfigScope] 读取配置；不存在时回退为 `false`（Material 风格）。
  static AppConfigScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppConfigScope>();
    return scope ?? _fallback;
  }

  // 静态常量而不是 const 构造：`InheritedWidget` 的 const 构造里不能
  // 传 `super.child`，Dart 会报「Constant expression expected」。
  static final AppConfigScope _fallback = AppConfigScope(
    usePackageGlassDock: false,
    child: const SizedBox.shrink(),
  );

  @override
  bool updateShouldNotify(AppConfigScope oldWidget) =>
      oldWidget.usePackageGlassDock != usePackageGlassDock;
}

/// 会根据当前主题样式切换外观的按钮。
///
/// - Material 3 风格：退化为对应的 Material 按钮，观感与原生一致；
/// - 液态玻璃风格：使用包的 `GlassButton`，带折射与形变。
///
/// 封装的目的：避免在 170+ 处调用点逐一改造，也让后续升级包 API 时只改这一处。
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.filled = true,
    this.outlined = false,
    this.text = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// 实心（对应 `FilledButton`）
  final bool filled;

  /// 描边（对应 `OutlinedButton`）
  final bool outlined;

  /// 无背景（对应 `TextButton`）
  final bool text;

  @override
  Widget build(BuildContext context) {
    if (!useLiquidGlass(context)) {
      final child = Text(label);
      if (text) {
        return TextButton(onPressed: onPressed, child: child);
      }
      if (outlined) {
        return OutlinedButton(onPressed: onPressed, child: child);
      }
      return FilledButton(
        onPressed: onPressed,
        child: icon == null ? child : Text(label),
      );
    }

    // 玻璃风格：包的 GlassButton。注意它的参数名与类型都和 Material 按钮不同——
    //   `onTap`（不是 onPressed）且**非空** VoidCallback；
    //   `label` 是非空 String；`icon` 必填。
    // 按钮禁用时回落到 Material 的禁用态，避免包不接受 null。
    // 赋给局部变量：公开字段（public property）不做类型提升，
    // 空检查后仍被视为 VoidCallback?，无法传给要求非空的 onTap。
    final handler = onPressed;
    if (handler == null) {
      return TextButton(onPressed: null, child: Text(label));
    }
    return GlassButton(
      onTap: handler,
      label: label,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
    );
  }
}

/// 会根据当前主题样式切换外观的搜索框。
///
/// Material 3 风格用 [SearchBar]，液态玻璃风格用包的 `GlassSearchBar`。
class AdaptiveSearchBar extends StatelessWidget {
  const AdaptiveSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText,
    this.leading,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    if (!useLiquidGlass(context)) {
      return SearchBar(
        controller: controller,
        onChanged: onChanged,
        hintText: hintText,
        leading: leading,
      );
    }
    // 玻璃风格：包的 GlassSearchBar 用**非空** `placeholder`（不是 hintText），
    // 且没有 `leading` 参数（搜索图标由组件内置）。
    return GlassSearchBar(
      controller: controller,
      onChanged: onChanged,
      placeholder: hintText ?? '',
    );
  }
}

/// 会根据当前主题样式切换外观的图标按钮组。
///
/// 多个图标按钮**成组包裹**在同一块玻璃里（共享一个圆角容器），视觉上是一个
/// 整体而不是几个散落的按钮。液态玻璃风格下用单块 [GlassCard] 承载，
/// Material 3 风格下退化为普通 [IconButton] 依次排列。
class AdaptiveIconButtonGroup extends StatelessWidget {
  const AdaptiveIconButtonGroup({
    super.key,
    required this.children,
    this.spacing = 4,
    this.borderRadius = 16,
    this.horizontalPadding = 3,
  });

  final List<AdaptiveIconAction> children;
  final double spacing;

  /// 整块玻璃的圆角半径。
  final double borderRadius;

  /// 玻璃块左右内边距，决定整组的大小。
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    if (!useLiquidGlass(context)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            IconButton(
              onPressed: children[i].onPressed,
              icon: Icon(children[i].icon, size: children[i].size),
              tooltip: children[i].tooltip,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      );
    }

    // 玻璃风格：**单块玻璃 + 纯图标**。
    //
    // 不使用包自带的按钮组 / 图标按钮 —— 它们会给每个按钮自带
    // 圆形底层，多个并排就会出现「圆底 + 缝合线」，很脏（用户反馈）。
    // 这里用一块 GlassCard 承载整组图标，内部只放 InkWell，视觉上是一整块玻璃。
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return GlassCard(
      shape: LiquidRoundedRectangle(borderRadius: borderRadius),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      clipBehavior: Clip.antiAlias,
      // 性能：按钮组是**静态内容**（不做形变），用 minimal 档不跑自定义
      // fragment shader。顶栏常驻课表页，高档位会持续耗电发热。
      // 注意：quality 是**组件级**参数，不在 LiquidGlassSettings 里。
      quality: GlassQuality.minimal,
      // 单独指定玻璃参数：默认走全局暗色主题（深炭灰），压在浅色背景上
      // 就是一个突兀的深色块。这里让玻璃**接近无色**——按钮组是浮在内容
      // 之上的薄玻璃层，本身不该有色，只留高光与折射。
      settings: LiquidGlassSettings(
        thickness: 8,
        blur: 2,
        // 与课表顶栏时间框同一套参数（见 course_page_top_bar.dart 的
        // _topBarGlass），保证两者在深/浅色下都完全一致。
        // 与 Dock 栏、时间框同一套数值（暗 0.42 / 亮 0.26）
        glassColor: isDark
            ? const Color.fromRGBO(20, 20, 22, 0.24)
            : const Color.fromRGBO(255, 255, 255, 0.20),
        lightIntensity: isDark ? 0.40 : 0.55,
        ambientStrength: 0.10,
        fresnelStrength: 0.35,
        glowIntensity: 0,
        shadowElevation: 0,
        refractiveIndex: 1.3,
        saturation: 1.1,
        chromaticAberration: 0.012,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Tooltip(
              message: children[i].tooltip ?? '',
              child: InkWell(
                onTap: children[i].onPressed,
                borderRadius: BorderRadius.circular(borderRadius / 2),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    children[i].icon,
                    size: children[i].size,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// [AdaptiveIconButtonGroup] 的单项。
class AdaptiveIconAction {
  const AdaptiveIconAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 20,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
}

/// 会根据当前主题样式切换外观的输入框。
///
/// Material 3 风格用 [TextField]（配合调用方的 decoration），
/// 液态玻璃风格用包的 [GlassTextField]。
///
/// 与 [AdaptiveSearchBar] 的区别：后者是搜索栏（自带搜索图标与提交行为），
/// 本组件是通用单行输入框，prefix/suffix 由调用方决定。
class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    if (!useLiquidGlass(context)) {
      return TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(),
        ),
      );
    }
    return GlassTextField(
      controller: controller,
      placeholder: hintText ?? '',
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      maxLines: maxLines ?? 1,
    );
  }
}
