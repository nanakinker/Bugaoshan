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
    return scope ?? const AppConfigScope._fallback();
  }

  const AppConfigScope._fallback()
    : usePackageGlassDock = false,
      super(key: null, child: SizedBox.shrink());

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

    // 玻璃风格：包的 GlassButton 统一承载，按钮层级通过参数表达。
    return GlassButton(
      onPressed: onPressed,
      title: label,
      icon: icon == null ? null : Icon(icon, size: 18),
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
    return GlassSearchBar(
      controller: controller,
      onChanged: onChanged,
      hintText: hintText,
      leading: leading,
    );
  }
}
