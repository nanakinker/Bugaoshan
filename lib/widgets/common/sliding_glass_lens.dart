import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 在 Dock 各项目之间流动的共享玻璃透镜。
///
/// 形态参考 Android 液态玻璃 Dock（酷安客户端），材质取向为毛玻璃：
/// 选中态不是「旧位置消失 +
/// 新位置出现」，而是**一个玻璃体在两格之间流动**，滑动途中被拉长、
/// 圆角变大，停下后回弹。
///
/// ## 定位：格子中心，按真实像素算
///
/// 用 [LayoutBuilder] 拿到 Dock 的真实宽度，然后 `cellWidth * (index + 0.5)`
/// 求格子中心——**不做分数对齐、不做端点钳制**。这两点都踩过坑：
/// - 分数对齐（`Alignment(-1 + 2*t)`，t=(i+0.5)/count）数学上正确，但外层
///   ClipRRect 的 padding 会让 Stack 宽度与 Dock 宽度不一致，产生可见偏移；
/// - 端点钳制（`clamp(inset + half, w - inset - half)`）会把最外侧格子的中心
///   强行拉回（4 项、inset=36 时约 16px），同样是偏移。而外层 ClipRRect 已把
///   内容裁成药丸形，透镜物理上不可能越界，根本不需要钳制。
///
/// ## 形变：体积守恒的挤压拉伸
///
/// 单纯拉宽像"橡皮筋"，不像液体。这里让**宽度增加时高度按比例收缩**
/// （宽度增量的 `squash` 倍），近似保持面积不变——果冻/水滴动效的核心手法。
/// 同时圆角随拉伸显著变大，形状从"圆角方形"过渡到"胶囊"。
///
/// ## 流畅度
///
/// - 位置 `easeOutCubic`：起步快、收尾稳，全程无折返。
/// - 形变 `easeOutBack`：仅末端一次轻微过冲。**不要用 `elasticOut`**——
///   它在前 40% 时间里来回折返多次，肉眼即卡顿。
/// - 只保留**一个**低模糊阴影：形状每帧都在变，而 `BoxShadow` 的模糊
///   光栅化很贵，两个模糊阴影等于每帧重算两次，这是滑动掉帧的主因。
/// - 外包 [RepaintBoundary]：重绘不扩散到 Dock 其他部分。
/// - 透镜是纯装饰、不含任何子组件，因此不可能触发布局溢出。
class SlidingGlassLens extends StatefulWidget {
  const SlidingGlassLens({
    super.key,
    required this.itemCount,
    required this.index,
    required this.itemExtent,
    required this.duration,
    required this.isDarkTheme,
    this.baseWidthFactor = 0.66,
    this.stretchPerCell = 0.16,
    this.squash = 0.45,
  });

  final int itemCount;
  final int index;

  /// Dock 单格的高度（也是药丸的直径）。
  final double itemExtent;
  final Duration duration;
  final bool isDarkTheme;

  /// 静止时透镜宽度占单格的比例。
  final double baseWidthFactor;

  /// 每跨一格的拉伸量。越大越"液态"，也越容易显得夸张。
  final double stretchPerCell;

  /// 高度收缩系数（相对宽度的增量），保持面积近似不变。
  final double squash;

  @override
  State<SlidingGlassLens> createState() => _SlidingGlassLensState();
}

class _SlidingGlassLensState extends State<SlidingGlassLens>
    with SingleTickerProviderStateMixin {
  /// 动画时长下限。
  ///
  /// `cardSizeAnimationDuration` 来自用户设置，允许被调成 0（关闭动画）。
  /// 但那会让"玻璃流动"这个核心观感完全消失——透镜瞬移、没有形变，
  /// 看起来像 bug 而非极简。所以这里给一个下限。
  static const Duration _minDuration = Duration(milliseconds: 160);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _minDuration,
  );

  late Animation<double> _t;
  late Animation<double> _morph;

  int _fromIndex = 0;

  Duration get _duration {
    final d = widget.duration;
    return d < _minDuration ? _minDuration : d;
  }

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.index;
    _c.duration = _duration;
    _build();
  }

  void _build() {
    _t = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    final cells = (widget.index - _fromIndex).abs().toDouble();
    _morph = Tween<double>(
      begin: 0,
      end: cells,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(covariant SlidingGlassLens old) {
    super.didUpdateWidget(old);
    // 时长可能随全局设置变化，controller 的 duration 需同步。
    if (_c.duration != _duration) {
      _c.duration = _duration;
    }
    if (old.index != widget.index || old.itemCount != widget.itemCount) {
      _fromIndex = old.index;
      _build();
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= 0) {
      return const SizedBox.shrink();
    }
    final isDark = widget.isDarkTheme;
    final restWidth = widget.itemExtent * widget.baseWidthFactor;
    final restHeight = widget.itemExtent * 0.84;

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          if (w <= 0 || h <= 0) {
            return const SizedBox.shrink();
          }
          // 格子中心：按真实宽度算，不做分数对齐、不做端点钳制。
          final cellWidth = w / widget.itemCount;
          final fromX = cellWidth * (_fromIndex + 0.5);
          final toX = cellWidth * (widget.index + 0.5);

          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final p = _t.value.clamp(0.0, 1.0);
              final grow = widget.stretchPerCell * _morph.value;

              // 体积守恒的挤压拉伸：宽涨多少、高就收多少。
              final width = restWidth * (1 + grow);
              final height = restHeight * (1 - widget.squash * grow);
              final x = fromX + (toX - fromX) * p;

              // 形状：静止是圆角方形，拉伸后过渡到胶囊。
              final radius = 20.0 + 30.0 * grow.clamp(0.0, 1.0);

              return Stack(
                children: [
                  Positioned(
                    left: x - width / 2,
                    top: (h - height) / 2,
                    width: width,
                    height: height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          math.min(radius, 999),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  Colors.white.withValues(alpha: 0.16),
                                  Colors.white.withValues(alpha: 0.05),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.82),
                                  Colors.white.withValues(alpha: 0.44),
                                ],
                        ),
                        // 亮边很淡。参考图里透镜几乎没有发光圈，
                        // 玻璃感来自"透"和背景被折射，而不是一圈白光。
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.20)
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                        // 只保留一个低模糊阴影，理由见类注释。
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.42 : 0.14,
                            ),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
