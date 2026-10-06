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

/// 自适应下拉选择：液态玻璃模式下是玻璃字段 + [GlassMenu] 弹出菜单，
/// Material 3 模式下回退为 [DropdownButtonFormField]。
///
/// ## 为什么需要这个组件
///
/// 项目里 15+ 个页面直接用 [DropdownButtonFormField] / [DropdownButton]，
/// 它们的弹出菜单是 Material 默认样式（截图：深色实底面板，无玻璃质感），
/// 与重构后的液态玻璃界面割裂。本组件把「下拉」统一收编：
///
/// - **玻璃模式**：触发器是一块 [GlassCard] 风格的字段（圆角、底纱、
///   右侧下拉箭头），点击后从包的 [GlassMenu] 展开菜单项，长列表
///   自动限高滚动（`glowOnTapOnly` 遵循包对可滚动菜单的约定）。
/// - **Material 模式**：完全走 [DropdownButtonFormField]，外观与
///   重构前一致。
///
/// ## 迁移方式
///
/// 调用点只需把 `DropdownButtonFormField<T>(...)` /
/// `DropdownButton<T>(...)` 换成 `AdaptiveGlassDropdown<T>(...)`，
/// `value` / `items` / `onChanged` / `hint` / `decoration` /
/// `isExpanded` 参数原样保留。
/// 玻璃字段（输入框 / 下拉触发器）的统一高度。
///
/// 输入的 [GlassTextField] 默认 44、下拉触发器由内边距决定高度，两者不写死
/// 就会**一米七一米八**：用户截图里「课程名」比「全部」高一截，
/// 玻璃框圆角与描边看着也不是一套。统一 48 后两类控件完全等高。
const double _fieldHeight = 48;

/// 字段的统一水平内边距（与 [GlassTextField] 内部的 16 对齐）。
const double _fieldPaddingH = 16;

/// 玻璃下拉菜单的单行高度。44 是「15sp 文字 + 上下各 14dp」的舒适值，
/// 比包默认（约 52）更紧凑，一屏能多看两条。
const double _menuItemHeight = 44;

/// 玻璃下拉菜单的宽度下限。
///
/// 项目里筛选栏多为「两列并排」，触发器只有半屏宽（≈160dp）。若菜单跟随
/// 触发器宽，「文学与新闻学院」会被截成「文学与…」。菜单是浮层，允许比
/// 触发器宽 —— 300dp 配合 15sp 字号可一行放下 13 个汉字。
const double _menuMinWidth = 300;

class AdaptiveGlassDropdown<T> extends StatelessWidget {
  const AdaptiveGlassDropdown({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.decoration,
    this.isExpanded = false,
    this.style,
    this.menuMaxHeight,
  });

  /// 当前选中的值；null 表示未选中（显示 [hint]）。
  final T? value;

  /// 选项列表，与 [DropdownButtonFormField.items] 同构，
  /// 迁移时原样传入现有的 `DropdownMenuItem` 列表即可。
  final List<DropdownMenuItem<T>> items;

  /// 选中回调；null 表示禁用。
  final ValueChanged<T?>? onChanged;

  /// 未选中时显示的提示。
  final Widget? hint;

  /// 字段外观。玻璃模式下只取 `contentPadding` / `labelText` /
  /// `hintText`，其余（border 等）由玻璃字段自己决定。
  final InputDecoration? decoration;

  /// 是否撑满可用宽度（菜单宽度跟随）。
  final bool isExpanded;

  /// 触发器文字样式。
  final TextStyle? style;

  /// 菜单最大高度；null 时按条数自动限高（>8 条时限高 9 条并滚动）。
  final double? menuMaxHeight;

  bool get _enabled => onChanged != null;

  /// 从 DropdownMenuItem 的子 widget 提取文字标签。
  ///
  /// 项目里所有选项的 child 都是 `Text`，直接取 `data`；
  /// 非 Text 时退化用 toString，保证不崩。
  static String _labelOf(Widget child) {
    if (child is Text) return child.data ?? '';
    return child.toStringShort();
  }

  @override
  Widget build(BuildContext context) {
    if (!useLiquidGlass(context)) {
      return DropdownButtonFormField<T>(
        // 传 initialValue 而非已弃用的 value（SDK v3.33 起 value 标记
        // @Deprecated，用它会刷警告）。
        initialValue: value,
        decoration: decoration ?? const InputDecoration(),
        isExpanded: isExpanded,
        hint: hint,
        items: items,
        onChanged: onChanged,
        style: style,
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // 玻璃模式下**忽略 decoration.contentPadding**，改用与输入框统一的
    // 尺寸规范（高 48 / 水平内边距 16 / 圆角 GlassSpec.radiusField）——
    // 否则「全部」下拉比「课程名」输入框矮一截、圆角也不同（用户反馈
    // 「三个输入框与'全部'选项框视觉风格和尺寸不统一」）。
    final pad = EdgeInsets.symmetric(horizontal: _fieldPaddingH);

    final selected = items.where((i) => i.value == value).firstOrNull;
    // 兜底成 TextStyle，避免后面 `!` 在极端情况下崩（DefaultTextStyle 要求
    // style 非空）。
    final TextStyle labelStyle =
        style ?? theme.textTheme.bodyMedium ?? const TextStyle();
    final hintStyle = labelStyle.copyWith(color: scheme.onSurfaceVariant);

    // 长列表自动限高滚动（包约定：含滚动内容的菜单 glowOnTapOnly=true，
    // 否则拖动时高光会残留在列表上）。
    //
    // 高度上限取「屏高 55%」与「9 行」的较小者：此前固定 9 行 × 46 = 414，
    // 在 754dp 逻辑高度的手机上从筛选栏（页面顶部）展开会直接顶出屏幕底部
    // （用户截图：最后一个选项被裁掉）。
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double maxMenuHeight = screenHeight * 0.55;
    final double nineRows = 9 * _menuItemHeight;
    final double autoCap = nineRows < maxMenuHeight ? nineRows : maxMenuHeight;
    final double? effectiveMenuHeight = menuMaxHeight ?? autoCap;

    // 空列表：不挂 GlassMenu（点开也没东西），只渲染禁用态字段。
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (decoration?.labelText != null) ...[
            Text(
              decoration!.labelText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Opacity(
            opacity: 0.5,
            child: GlassCard(
              quality: GlassQuality.standard,
              useOwnLayer: true,
              settings: AppGlass.of(context),
              shape: const LiquidRoundedRectangle(
                borderRadius: GlassSpec.radiusField,
              ),
              height: _fieldHeight,
              padding: pad,
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle(
                      style: hintStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: hint ?? Text(decoration?.hintText ?? ''),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 菜单至少与触发器等宽；窄触发器（周次/节次选择）给 140 下限，
        // 避免「第 12 节」这类文本被挤掉。
        // 字面量必须是 140.0：写 140（int）会让三元表达式推导出 num，
        // 而 GlassMenu.menuWidth 要的是 double。
        // 触发器宽度；父级没给约束（Row / 对话框）时 maxWidth 是 infinity，
        // 直接传给 menuWidth 会崩 —— 退到 200。
        final triggerWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 200.0;
        // 菜单宽度**不跟随触发器宽**。
        //
        // 项目里大量「两列并排」的筛选栏（课程课表 / 班级课表 / 培养方案），
        // 触发器只有半屏宽（≈160dp），跟随会让长选项被截成「文学与…」
        // 「国际关…」（用户截图反馈可读性差）。菜单是浮层，可以比触发器宽：
        //   - 下限 [_menuMinWidth]=300：容纳「文学与新闻学院」这类 7 字选项
        //   - 上限 屏宽 - 32：左右各留 16dp 安全边距，不贴边
        final double screenWidth = MediaQuery.sizeOf(context).width;
        final double maxMenuWidth = screenWidth - 32.0;
        final double wider = triggerWidth < _menuMinWidth
            ? _menuMinWidth
            : triggerWidth;
        final double menuWidth = wider > maxMenuWidth ? maxMenuWidth : wider;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (decoration?.labelText != null) ...[
              Text(
                decoration!.labelText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
            ],
            GlassMenu(
              menuWidth: menuWidth,
              menuHeight: effectiveMenuHeight,
              menuPadding: const EdgeInsets.all(8),
              glowOnTapOnly: effectiveMenuHeight != null,
              // standard 而不是 premium：菜单可滚动，包文档明确 premium
              // 「may not render correctly in scrollable contexts」。
              quality: GlassQuality.standard,
              // **面板级**底纱（深 85% / 浅 90%），不是控件级的 42%/30%：
              // 菜单里是成列的文字，背后页面的文字若透上来会与菜单文字
              // 叠在一起（用户截图：菜单里能看见底下的「查询」按钮和课程
              // 列表）。承载文字的浮层优先保证可读性。
              settings: AppGlass.panelOf(context),
              items: [
                for (final item in items)
                  GlassMenuItem(
                    title: _labelOf(item.child),
                    onTap: () => onChanged?.call(item.value),
                    isSelected: item.value == value,
                    enabled: _enabled,
                    // 字号压到 15sp（包默认约 20sp，在 300dp 宽的菜单里
                    // 一行只放得下 6 个汉字，长学院名会被省略号截断）。
                    // 15sp ≈ 一行 13 个汉字，配合 300dp 宽度可完整显示
                    // 「文学与新闻学院」「马克思主义学院」。
                    titleStyle: TextStyle(
                      fontSize: 15,
                      color: scheme.onSurface,
                      fontWeight: item.value == value
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    height: _menuItemHeight,
                    maxLines: 1,
                  ),
              ],
              triggerBuilder: (context, toggleMenu) {
                return GestureDetector(
                  onTap: _enabled ? toggleMenu : null,
                  child: Opacity(
                    opacity: _enabled ? 1 : 0.5,
                    child: GlassCard(
                      quality: GlassQuality.standard,
                      useOwnLayer: true,
                      settings: AppGlass.of(context),
                      // 圆角与输入框同值：GlassSpec.radiusField(16)，
                      // 此前写死 12 与输入框的 16 不一致。
                      shape: const LiquidRoundedRectangle(
                        borderRadius: GlassSpec.radiusField,
                      ),
                      height: _fieldHeight,
                      padding: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: pad,
                        child: Row(
                          children: [
                            Expanded(
                              child: selected != null
                                  ? DefaultTextStyle(
                                      style: labelStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      child: selected.child,
                                    )
                                  : DefaultTextStyle(
                                      style: hintStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      child: hint ??
                                          Text(
                                            decoration?.hintText ?? '',
                                          ),
                                    ),
                            ),
                            // 箭头 18（原 20）+ 内边距收紧：窄触发器
                            // （半屏 ≈160dp）里多让出约 10dp 给文字。
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// 自适应输入框：液态玻璃模式下用包原生的 [GlassTextField]（真实折射 +
/// 聚焦发光描边），Material 3 模式下回退为 [TextField]。
///
/// ## 为什么需要它
///
/// 项目里 28 处 `TextField` / `TextFormField` 直接吃主题层给的外观 ——
/// 主题层只能给「半透明 + 描边」，做不了模糊与折射（`ThemeData` 无法注入
/// `BackdropFilter`）。需要真实玻璃质感的输入框（如课程课表查询页）走本组件。
///
/// 视觉规则见 [GlassSpec]：圆角 [GlassSpec.radiusField]、底纱浓度、
/// 聚焦描边透明度。
///
/// ## 与 [GlassTextField] 的差异
///
/// 包用 `placeholder` 表示占位文字，本组件沿用项目习惯的 `hint`，
/// 并在玻璃模式下自动套 [AppGlass] 的参数，避免每个调用点重复传 settings。
class AdaptiveGlassTextField extends StatelessWidget {
  const AdaptiveGlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint,
    this.style,
    this.hintStyle,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.height,
    this.decoration,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// 占位文字（玻璃模式映射到 `placeholder`，Material 模式映射到 `hintText`）。
  final String? hint;

  /// 输入文字样式。
  final TextStyle? style;

  /// 占位文字样式；不传时用 `onSurfaceVariant`。
  final TextStyle? hintStyle;

  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// 固定高度；null 时用 [_fieldHeight]（与玻璃下拉触发器同高）。
  /// 多行输入不要传。
  final double? height;

  /// Material 模式下的完整装饰（玻璃模式下忽略，外观由 [AppGlass] 决定）。
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyle = style ?? theme.textTheme.bodyMedium;
    final placeholderStyle =
        hintStyle ?? textStyle?.copyWith(color: scheme.onSurfaceVariant);

    if (!useLiquidGlass(context)) {
      return TextField(
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        maxLines: maxLines,
        enabled: enabled,
        readOnly: readOnly,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration:
            decoration ??
            InputDecoration(hintText: hint, hintStyle: placeholderStyle),
      );
    }

    return GlassTextField(
      controller: controller,
      focusNode: focusNode,
      placeholder: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      onSuffixTap: onSuffixTap,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textStyle: textStyle,
      placeholderStyle: placeholderStyle,
      // 与下拉触发器统一取 _fieldHeight(48)：包默认 44，会比下拉矮 4dp，
      // 两列并排时肉眼可辨（用户反馈「尺寸大小不统一」）。
      height: height ?? _fieldHeight,
      // 与 AppGlass 其余玻璃件同一套参数：底纱浓度、折射、色散一致。
      settings: AppGlass.of(context),
      // standard：输入框常出现在可滚动表单里，用轻量 shader；
      // premium 只留给顶栏、Dock 这类静态/形变控件。
      quality: GlassQuality.standard,
      useOwnLayer: true,
      shape: const LiquidRoundedRectangle(
        borderRadius: GlassSpec.radiusField,
      ),
    );
  }
}
