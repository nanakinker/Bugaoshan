import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:bugaoshan/widgets/common/app_glass.dart';

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
/// 液态玻璃风格下改为库原生的 [GlassIconButton] 依次排列（官方 demo 即如此），
/// Material 3 风格下退化为普通 [IconButton] 依次排列。
class AdaptiveIconButtonGroup extends StatelessWidget {
  const AdaptiveIconButtonGroup({
    super.key,
    required this.children,
    // 三个图标挤在一块玻璃里时，间距太小会显得糊成一片（用户反馈
    // 「3 个控件有点太挤」）。8 与左右各 6 的内边距给出明确的呼吸感。
    this.spacing = 8,
    this.borderRadius = 16,
    this.horizontalPadding = 6,
    this.iconSize = 20,
  });

  final List<AdaptiveIconAction> children;
  final double spacing;

  /// 整组统一图标尺寸；单项可用 [AdaptiveIconAction.size] 覆盖。
  final double iconSize;

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
              // size 现在可空（null = 沿用整组 iconSize），Icon.size 要求非空。
              icon: Icon(
                children[i].icon,
                size: children[i].size ?? iconSize,
              ),
              tooltip: children[i].tooltip,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      );
    }

    // 玻璃风格：**一整块**玻璃包住三个图标按钮。
    //
    // 为什么不是三个独立 `GlassIconButton`：官方 Rule 2 明确禁止在
    // `GlassCard` / `GlassContainer` 里嵌套带折射层的玻璃控件（会造成
    // 双重折射、裁切动画）。若要「一整块玻璃 + 纯图标」，正确做法是
    // `GlassCard` 里放**非玻璃**的图标按钮 —— 玻璃由容器一层提供，
    // 按钮只负责点击与图标。
    //
    // 这与左侧时间框（`GlassCard`）形态一致，顶栏左右两块的玻璃语言统一。
    //
    // 玻璃由外层 GlassCard 一层提供（见上方说明）。
    //
    // 刻意不传 `settings`：组件级 settings 是**整体替换**语义，会丢掉库
    // 的整套光学预设。底纱色由 main.dart 的 `GlassThemeData` 按 light/dark
    // 部分覆盖（`GlassThemeSettings`，null = 沿用组件默认）。
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      quality: GlassQuality.premium,
      // useOwnLayer: true —— 自建折射层，切断向祖先 glass 层的 settings
      // 继承。原因见 course_page_top_bar.dart 里的注释：
      // grouped 模式下组件的 settings 只是 const 占位，真实参数取自最近祖先
      // LiquidGlassLayer 的 inherited.settings；不切断就拿不到主题设的
      // glassColor，浅色主题下会看不见描边。
      useOwnLayer: true,
      // useOwnLayer: true 时必须同时给 settings（见 glass_card.dart 的
      // Standalone Mode 示例）：自建层不继承，settings 为空就是完全透明
      // 玻璃。数值与顶栏时间框、Dock 的库预设一致。
      settings: AppGlass.of(context),
      shape: LiquidRoundedRectangle(borderRadius: borderRadius),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Tooltip(
              message: children[i].tooltip ?? '',
              child: Semantics(
                button: true,
                label: children[i].tooltip,
                child: InkResponse(
                  onTap: children[i].onPressed,
                  // 触摸热区撑满整块高度，玻璃层由外层 GlassCard 提供，
                  // 这里**不用** GlassIconButton（避免嵌套折射层）。
                  child: Padding(
                    // 垂直内边距决定玻璃容器的**高度**。图标放大到 24 后，
                    // 4 的留白让容器显得比图标矮一截、比例失调；
                    // 提到 7 后容器高 ≈ 24 + 14 = 38，接近方形，
                    // 与左侧时间框（两行文字 + padding）视觉重量相当。
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Icon(
                      children[i].icon,
                      // 整组默认 iconSize；单项给了 size 则以单项为准。
                      size: children[i].size ?? iconSize,
                      color: scheme.onSurface,
                    ),
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
    this.size,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// 覆盖 [AdaptiveIconButtonGroup.iconSize]；null 表示沿用整组尺寸。
  final double? size;
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
