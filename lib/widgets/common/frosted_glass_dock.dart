import 'package:flutter/material.dart';

import 'package:bugaoshan/theme_shape.dart';
import 'package:bugaoshan/widgets/common/frosted_glass.dart';
import 'package:bugaoshan/widgets/common/sliding_glass_lens.dart';

/// 毛玻璃风格的导航条，横向用于手机底部 Dock，纵向用于宽屏侧边 Dock。
///
/// 形态参考 Android 液态玻璃 Dock（如酷安客户端），但材质取向是**毛玻璃**：
/// 磨砂柔化为主，不做液态玻璃那种明显的折射位移与形变。要点：
/// - **全药丸形**：横向 Dock 圆角取高度的一半，两端呈半圆；
/// - **共享滑动透镜**：选中态不是"旧位置消失 + 新位置出现"，而是**一个
///   玻璃体在格子之间流动**，滑动途中按体积守恒挤压拉伸、圆角变大，停下后回弹；
/// - **强透光**：`BackdropFilter` + 低色调层 + **低模糊半径**，背景明显透出。
///
/// 之所以不用 `NavigationBar` / `NavigationRail`，是因为这两者都带有 Material
/// 3 的实心 `indicator` 与不透明背景，无法叠加 `BackdropFilter` 做玻璃折射。
/// 这里手写导航条以获得完整的视觉控制权，同时保留原有两个组件的关键行为：
///
/// - **选中态**：图标在 `icon` / `selectedIcon` 之间切换（带淡入淡出过渡）；
/// - **无障碍**：`Semantics` 的 `selected` / `button` 语义，与原组件一致；
/// - **触控热区**：每个 item 四周留有内边距，实测高度大于 48dp；
/// - **文字缩放**：标签使用 `labelSmall` + `FittedBox`，长文案缩放而非溢出。
class FrostedGlassDock extends StatelessWidget {
  /// 导航项。顺序即显示顺序。
  final List<FrostedGlassDockItem> items;

  /// 当前选中索引。
  final int selectedIndex;

  /// 选中变化回调。
  final ValueChanged<int> onSelected;

  /// 排列方向。
  final Axis axis;

  /// 单个item 的高度（横向 Dock 即药丸直径）。
  final double itemExtent;

  /// 标签的横向最大宽度。
  final double labelExtent;

  /// 动效时长。
  final Duration duration;

  const FrostedGlassDock({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.axis = Axis.horizontal,
    this.itemExtent = 72,
    this.labelExtent = 64,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    final isHorizontal = axis == Axis.horizontal;

    return SafeArea(
      top: !isHorizontal,
      bottom: isHorizontal,
      left: false,
      right: false,
      child: Padding(
        // 悬浮感的关键：玻璃不贴边。左右边距按屏宽 5.5% 给（夹在 16~40dp），
        // 固定值在按钮变多时会被挤没，比例值能保证任何数量下都留得住。
        padding: isHorizontal
            ? EdgeInsets.fromLTRB(
                (MediaQuery.sizeOf(context).width * 0.055).clamp(16.0, 40.0),
                8,
                (MediaQuery.sizeOf(context).width * 0.055).clamp(16.0, 40.0),
                14,
              )
            : const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: SizedBox(
          height: isHorizontal ? itemExtent : null,
          width: isHorizontal ? null : itemExtent,
          child: FrostedGlass(
            // 横向底部 Dock 用**全药丸形**（radius = 高度的一半），两端呈半圆。
            // 纵向侧边 Dock 很高，用大圆角即可，避免变成细长胶囊。
            borderRadius: isHorizontal ? itemExtent / 2 : AppShapes.extraLarge,
            child: isHorizontal
                ? _buildHorizontal(context)
                : _buildVertical(context),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontal(BuildContext context) {
    // 共享滑动透镜：它在各格之间流动，滑动途中挤压拉伸、圆角变大，停下回弹。
    //
    // 结构要点（都是踩过的坑）：
    // - 透镜层用 [Positioned.fill] + [IgnorePointer]，只绘制不参与布局，
    //   因此不会给下面的 Row 施加额外约束（早期版本曾因此报
    //   RenderFlex overflow）。
    // - 透镜内部没有任何子组件，纯装饰，不可能溢出。
    final count = items.length;
    if (count == 0) {
      return const SizedBox.shrink();
    }
    final safeIndex = selectedIndex.clamp(0, count - 1);

    return Stack(
      children: [
        // 底层：共享滑动透镜
        Positioned.fill(
          child: IgnorePointer(
            child: SlidingGlassLens(
              itemCount: count,
              index: safeIndex,
              itemExtent: itemExtent,
              duration: duration,
              isDarkTheme: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ),
        // 上层：各格图标与标签
        Row(
          children: [
            for (var i = 0; i < count; i++)
              Expanded(
                child: _DockItemView(
                  item: items[i],
                  isSelected: i == safeIndex,
                  axis: Axis.horizontal,
                  labelExtent: labelExtent,
                  extent: itemExtent,
                  duration: duration,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildVertical(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: _DockItemView(
                item: items[i],
                isSelected: i == selectedIndex,
                axis: Axis.vertical,
                labelExtent: itemExtent,
                extent: itemExtent,
                duration: duration,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

/// 导航项。
///
/// [icon] / [selectedIcon] 是 **Widget** 而不是 IconData：调用方需要在图标上
/// 叠加更新红点（`_buildUpdateBadge`），因此必须能传任意 Widget。
@immutable
class FrostedGlassDockItem {
  const FrostedGlassDockItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.semanticLabel,
  });

  /// 未选中图标。
  final Widget icon;

  /// 选中图标。为空时复用 [icon]。
  final Widget? selectedIcon;

  /// 标签文本。
  final String label;

  /// 无障碍朗读文本。为空时用 [label]。
  final String? semanticLabel;
}

/// 单个 Dock 项。
class _DockItemView extends StatelessWidget {
  final FrostedGlassDockItem item;
  final bool isSelected;
  final Axis axis;
  final double labelExtent;

  /// Dock 单格的高度（横向）或宽度（纵向），用于给选中透镜定宽。
  final double extent;
  final Duration duration;
  final VoidCallback onTap;

  const _DockItemView({
    required this.item,
    required this.isSelected,
    required this.axis,
    required this.labelExtent,
    required this.extent,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHorizontal = axis == Axis.horizontal;
    final isDarkTheme = theme.brightness == Brightness.dark;

    // 选中态用主题主色，未选中用 onSurfaceVariant。
    final effectiveColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    // AnimatedSwitcher 只比较直接子组件的 runtimeType 与 key，
    // 因此 KeyedSubtree 必须挂在它的直接子层。
    final icon = AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(isSelected),
        // item.icon 是 Widget（可能已带红点徽章），只需用 IconTheme 施加
        // 尺寸与颜色，不需要再包一层 Icon。
        child: IconTheme.merge(
          data: IconThemeData(
            size: isHorizontal ? 24 : 22,
            color: effectiveColor,
          ),
          child: isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
        ),
      ),
    );

    final label = SizedBox(
      width: isHorizontal ? labelExtent : double.infinity,
      height: isHorizontal ? null : 14,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: effectiveColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );

    // 横向 Dock 的透镜由 [SlidingGlassLens] 作为**共享层**绘制在
    // Stack 底层；这里若再画一份就会出现两层玻璃叠加。
    // 纵向侧边 Dock 每格独立，仍然自带透镜。
    final lensRadius = BorderRadius.circular(22);
    final lens = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(
        maxWidth: isHorizontal ? extent * 0.86 : double.infinity,
      ),
      decoration: BoxDecoration(
        borderRadius: lensRadius,
        gradient: isSelected && !isHorizontal
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkTheme
                    ? [
                        Colors.white.withValues(alpha: 0.13),
                        Colors.white.withValues(alpha: 0.04),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.80),
                        Colors.white.withValues(alpha: 0.42),
                      ],
              )
            : null,
        border: isSelected && !isHorizontal
            ? Border.all(
                color: isDarkTheme
                    ? Colors.white.withValues(alpha: 0.34)
                    : Colors.white.withValues(alpha: 0.90),
              )
            : null,
      ),
      child: isHorizontal
          ? Column(
              // mainAxisSize.min + Flexible：Dock 高度固定，而图标 + 标签
              // 可能超出，必须按内容收缩并居中，否则底部溢出
              // （曾报 OVERFLOWED BY 27 PIXELS）。
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: icon),
                const SizedBox(height: 3),
                Flexible(child: label),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [icon, const SizedBox(height: 4), label],
            ),
    );

    return Semantics(
      selected: isSelected,
      button: true,
      label: item.semanticLabel ?? item.label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: lensRadius,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isHorizontal ? 3 : 6,
              vertical: isHorizontal ? 4 : 6,
            ),
            child: Center(child: lens),
          ),
        ),
      ),
    );
  }
}
