import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:bugaoshan/theme_shape.dart';

/// 毛玻璃（Frosted Glass）表面。
///
/// 视觉参数由两套参考来源推导：
///
/// 1. [`dhbxs/liquid-glass-dock`](https://github.com/dhbxs/liquid-glass-dock)
///    —— 网页版实现，四层结构：
///    - **边缘折射环**：`backdrop-filter: url(#liquid_glass_filter)`，滤镜为
///      `feDisplacementMap scale="30"`，再用 `mask-composite: exclude`
///      把作用范围裁成外圈 5px 的环。**只有边缘一圈发生位移**，这是玻璃折射
///      最标志性的特征；
///    - **底色层**：`blur(2px)` + `rgba(0, 0, 0, 0.12)`；
///    - **镜面描边**：`inset 1px 1px 0 rgba(255,255,255,.5)` +
///      `inset -1px -1px 0 rgba(255,255,255,.6)`；
///    - **内反射**：`inset 2px 2px 6px 2px rgba(255,255,255,.2)` +
///      `inset -2px -2px 4px -1px rgba(255,255,255,.2)`。
/// 2. `AndroidLiquidGlassView`（liquidglass.qmdeve.com）—— 原生组件库，
///    参数维度为：折射高度 / 折射偏移 / 色散 / 模糊半径 / 色调 / 色调可见度 /
///    弹性 / 高光。
///
/// ### 与参考实现的差异（Flutter 能力所限，如实说明）
/// - **真实位移折射做不到**：Flutter 的 `ImageFilter` 没有 `feDisplacementMap`，
///   也没有自定义 fragment shader 采样背景的能力。这里的「折射环」改用
///   **边缘内发光**近似，观感接近但物理机制不同。
/// - **色散（dispersion）**用极淡的冷暖双边描边近似，非真实色散。
/// - **底色**跟随明暗主题（亮色白纱 / 暗色黑纱），而非参考实现恒定的
///   `rgba(0,0,0,.12)`——本项目是 Material 3 主题体系，恒定暗色会让亮色主题下
///   前景对比度不足。
///
/// 之所以拆成独立组件而不是把样式写进 Dock，是为了让底部 Dock、宽屏侧边
/// Dock、设置页预览三处共用同一套参数，保证视觉完全一致。
///
/// 性能注意：`BackdropFilter` 会对**裁剪区域内**的内容做逐帧模糊，属于重开销。
/// 本组件只保留**一个** `BackdropFilter`（单测据此断言），其余装饰层全部由
/// `CustomPaint` 在一次绘制里完成，避免叠加额外 layer。
class FrostedGlass extends StatelessWidget {
  /// 玻璃内部内容。
  final Widget child;

  /// 圆角半径，默认 [AppShapes.extraLarge]（28dp）。
  /// 参考实现的 dock 圆角为 26dp，本项目取 28 以贴合 `AppShapes` 体系。
  final double borderRadius;

  /// 模糊强度（`sigma`）。默认 5。
  ///
  /// 不宜过大：模糊越强，背景细节越糊，"透"的感觉就越弱。
  /// 酷安那种通透感来自**看得清背景内容的同时被玻璃包裹**，
  /// 所以这里用中等模糊，保留背景可辨识度。
  final double blurSigma;

  /// 色调层不透明度。默认 0.04。
  ///
  /// 这是通透感的关键参数：色调层越厚，玻璃越像磨砂塑料。
  /// 参考实现用 `rgba(0,0,0,.12)`，在本机深色背景下显得过重，
  /// 压到 0.06 让背景能真正透出来。颜色跟随主题：亮色白纱、暗色黑纱。
  final double tintOpacity;

  /// 高光层强度（顶部渐变，模拟镜面反射）。默认 0.35。
  final double highlightOpacity;

  /// 玻璃上方投射到内容上的阴影强度。默认 0.12。
  final double shadowOpacity;

  /// 是否绘制镜面高光层。默认 true。
  ///
  /// 极窄空间（可用宽度 < 200dp）下可关掉以省一次绘制，但通常无需调整。
  final bool showHighlight;

  /// 边缘折射环强度。默认 0.28，0 表示关闭。
  ///
  /// 对应参考实现的「折射高度」与 AndroidLiquidGlassView 的
  /// `refractionHeight` / `refractionOffset`。
  final double refractionOpacity;

  /// 色散强度（边缘冷暖分离）。默认 0.10，0 表示关闭。
  ///
  /// 对应 AndroidLiquidGlassView 的「色散参数」。
  final double dispersionOpacity;

  const FrostedGlass({
    super.key,
    required this.child,
    this.borderRadius = AppShapes.extraLarge,
    this.blurSigma = 5,
    this.tintOpacity = 0.04,
    this.highlightOpacity = 0.35,
    this.shadowOpacity = 0.12,
    this.showHighlight = true,
    this.refractionOpacity = 0.16,
    this.dispersionOpacity = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 亮色主题：白纱压背景；暗色主题：黑纱压背景。
    final tintColor = isDark ? Colors.black : Colors.white;

    final radius = BorderRadius.circular(borderRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        // 玻璃悬浮在内容之上，用较柔和的外阴影把它"托"起来。
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: CustomPaint(
            // 底色 / 高光 / 折射环 / 内反射 / 色散 / 镜面描边 —— 一次绘制完成。
            painter: _FrostedGlassPainter(
              tintColor: tintColor,
              tintOpacity: tintOpacity,
              highlightOpacity: showHighlight ? highlightOpacity : 0,
              refractionOpacity: refractionOpacity,
              dispersionOpacity: dispersionOpacity,
              borderRadius: borderRadius,
              isDark: isDark,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 毛玻璃的复合背景绘制。
///
/// 拆成单个 [CustomPainter] 而非嵌套多个 [Container]，是因为这些层都是纯装饰
/// 性的，合成一次绘制比多个 widget 少建若干 layer。
class _FrostedGlassPainter extends CustomPainter {
  final Color tintColor;
  final double tintOpacity;
  final double highlightOpacity;
  final double refractionOpacity;
  final double dispersionOpacity;
  final double borderRadius;
  final bool isDark;

  const _FrostedGlassPainter({
    required this.tintColor,
    required this.tintOpacity,
    required this.highlightOpacity,
    required this.refractionOpacity,
    required this.dispersionOpacity,
    required this.borderRadius,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final path = Path()..addRRect(rrect);

    // 1. 底色层：均匀铺一层中性色，保证前景文字可读。
    if (tintOpacity > 0) {
      canvas.drawPath(
        path,
        Paint()..color = tintColor.withValues(alpha: tintOpacity),
      );
    }

    // 2. 高光层：顶部最亮，约 45% 处衰减为 0。
    if (highlightOpacity > 0) {
      final topStrength = isDark ? highlightOpacity * 0.5 : highlightOpacity;
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: topStrength),
              Colors.white.withValues(alpha: topStrength * 0.25),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0, 0.55, 1],
          ).createShader(rect),
      );
    }

    // 3. 折射环：贴近边缘的一圈亮光。
    //
    // 参考实现用 feDisplacementMap 让边缘像素真实位移；Flutter 做不到位移，
    // 这里改用「裁剪到形状内 + 描边 + 模糊」产生沿内缘扩散的亮环来近似。
    //
    // 强度刻意压得很低：早期版本这里 0.55 叠加上第 4 步两道 0.20 的内反射，
    // 以及描边的 0.32/0.38，三层白光叠加后在药丸边缘形成一圈明显的"发光条"，
    // 看起来像加了泛光特效，而不像玻璃。参考图里边缘几乎看不见亮线，
    // 玻璃感来自「透」和「厚」，不来自「亮」。
    if (refractionOpacity > 0) {
      _drawInsetGlow(
        canvas,
        path,
        color: Colors.white.withValues(alpha: refractionOpacity * 0.16),
        width: 5,
        blur: 4,
      );
    }

    // 4. 内反射：左上与右下两道 inset 阴影，对应参考实现的两条 inset box-shadow。
    //    同样压到几乎不可见，只在边缘留一丝厚度提示。
    _drawInsetGlow(
      canvas,
      path,
      color: Colors.white.withValues(alpha: 0.05),
      dx: 2,
      dy: 2,
      width: 5,
      blur: 4,
    );
    _drawInsetGlow(
      canvas,
      path,
      color: Colors.white.withValues(alpha: 0.04),
      dx: -2,
      dy: -2,
      width: 4,
      blur: 3,
    );

    // 5. 色散：边缘极淡的冷暖分离，暗示玻璃的棱镜效应。
    if (dispersionOpacity > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF7FD8FF).withValues(alpha: dispersionOpacity),
              Colors.white.withValues(alpha: 0),
              const Color(0xFFFFB37F).withValues(alpha: dispersionOpacity),
            ],
            stops: const [0, 0.5, 1],
          ).createShader(rect),
      );
    }

    // 6. 镜面描边：1px 亮线。参考实现是「左上 .5 / 右下 .6」的双 inset，
    //    这里用一条斜向渐变描边同时表达两侧差异——中间段刻意压低，
    //    让上下两端的亮线更突出，这是玻璃"有厚度"的关键。
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.13 : 0.55),
            Colors.white.withValues(alpha: isDark ? 0.02 : 0.06),
            Colors.white.withValues(alpha: isDark ? 0.16 : 0.60),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
  }

  /// 绘制内发光／内阴影。
  ///
  /// 原理：先把画布裁剪到形状内部，再绘制比形状更宽的描边——超出形状的部分
  /// 被裁掉，只留下内侧的一半；叠加模糊后形成向内扩散的柔光。
  void _drawInsetGlow(
    Canvas canvas,
    Path path, {
    required Color color,
    double dx = 0,
    double dy = 0,
    required double width,
    required double blur,
  }) {
    canvas.save();
    canvas.clipPath(path);
    if (dx != 0 || dy != 0) canvas.translate(dx, dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FrostedGlassPainter oldDelegate) {
    return oldDelegate.tintColor != tintColor ||
        oldDelegate.tintOpacity != tintOpacity ||
        oldDelegate.highlightOpacity != highlightOpacity ||
        oldDelegate.refractionOpacity != refractionOpacity ||
        oldDelegate.dispersionOpacity != dispersionOpacity ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.isDark != isDark;
  }
}
