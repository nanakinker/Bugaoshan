import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 全应用统一的玻璃参数。
///
/// ## 为什么要集中在这里
///
/// 之前每处玻璃各自写一套 `LiquidGlassSettings`，很快出现了三种不一致：
///
/// | 位置 | 浅色底纱 | 问题 |
/// |---|---|---|
/// | Dock | `0x3DFFFFFF`（24% 白） | 基准 |
/// | 顶栏时间框 / 三控件 / 侧边栏 | `0x8CF8FAFC`（55% 冷白） | 明显比 Dock 黑、比 Dock 厚 |
///
/// 用户反馈「顶栏玻璃背景有点太黑了」正是这个不一致的结果。
/// 现在统一成一份，四处按主题取同一组值。
///
/// ## 参数来源
///
/// 光学参数逐项复刻库的 `kBottomBarGlassDefaults`
/// （`lib/src/widgets/surfaces/tab_bar_bottom_internal.dart:47`）——那份常量在
/// `src/` 下，官方 Rule 3 禁止 import，公开入口也未导出，只能照抄数值。
///
/// 之所以要照抄而不是只传颜色：组件级 `settings` 是**整体替换**而非合并
/// （见 `tab_bar_bottom_layout.dart:256`），传一个只带颜色的
/// `LiquidGlassSettings` 会把 thickness / blur / 折射 / 色散全丢掉。
///
/// 仅**底纱色**一项按主题切换——这是唯一需要为可读性调整的量。
class AppGlass {
  const AppGlass._();

  /// 库预设的光学参数。四个玻璃件共用，保证质感完全一致。
  ///
  /// 在库默认值基础上降低了几档折射与模糊（库默认 thickness 30 / blur 3），
  /// 配合更低的底纱浓度一起达到「更透明、背景更能透出来」的效果：
  /// - `thickness` 决定折射强度（源码注释：thicker surfaces refract more
  ///   intensely），30 → 18 让边缘折射不那么厚；
  /// - `blur` 是霜化半径，3 → 2 减少背景被抹糊的程度。
  static const double thickness = 18;
  static const double blur = 2;
  static const double chromaticAberration = 0.3;
  static const double lightIntensity = 0.6;
  static const double refractiveIndex = 1.59;
  static const double saturation = 0.7;
  static const double ambientStrength = 1;
  static const double lightAngle = 0.75 * 3.141592653589793;

  /// 按主题取玻璃参数。
  ///
  /// [isDark] 为 true 时用近黑纱，浅色时用冷白纱。
  static LiquidGlassSettings of(BuildContext context) {
    return resolve(
      Theme.of(context).brightness == Brightness.dark,
    );
  }

  /// 取**面板级**玻璃参数：底纱浓度更高（深色 0xD9 / 浅色 0xE6）。
  ///
  /// 为什么面板要单独一档：弹出菜单、下拉面板、底部弹窗是**承载文字的浮层**，
  /// 压在内容之上。若沿用控件级的低浓度底纱（42%/30%），背后页面的文字会
  /// 透上来与菜单文字重叠，直接损害可读性（用户截图：下拉菜单里能看见
  /// 底下的「查询」按钮和课程列表）。
  ///
  /// 控件（按钮 / 输入框）反过来 —— 它们面积小、只承载短语，透一些更有
  /// 玻璃感；面板面积大且承载长文本，优先保证可读。
  static LiquidGlassSettings panelOf(BuildContext context) {
    return resolvePanel(Theme.of(context).brightness == Brightness.dark);
  }

  /// 按明暗直接取面板级玻璃参数。
  static LiquidGlassSettings resolvePanel(bool isDark) {
    return LiquidGlassSettings(
      thickness: thickness,
      blur: blur,
      chromaticAberration: chromaticAberration,
      lightIntensity: lightIntensity,
      refractiveIndex: refractiveIndex,
      saturation: saturation,
      ambientStrength: ambientStrength,
      lightAngle: lightAngle,
      glassColor: isDark ? panelDarkTint : panelLightTint,
    );
  }

  /// 面板底纱：深色 0xD9 ≈ 85%，浅色 0xE6 ≈ 90%。
  ///
  /// 与 [GlassSpec.tintPanelDark] / [GlassSpec.tintPanelLight] 同值 ——
  /// 主题层的弹窗/菜单/底弹用的是那两个常量，此处保持一致，
  /// 保证「组件层的玻璃下拉」与「主题层的玻璃弹窗」浓度看起来一样。
  static const Color panelDarkTint = Color(0xD9141416);
  static const Color panelLightTint = Color(0xE6F8FAFC);

  /// 按明暗直接取玻璃参数（不需要 context 时用）。
  static LiquidGlassSettings resolve(bool isDark) {
    return LiquidGlassSettings(
      thickness: thickness,
      blur: blur,
      chromaticAberration: chromaticAberration,
      lightIntensity: lightIntensity,
      refractiveIndex: refractiveIndex,
      saturation: saturation,
      ambientStrength: ambientStrength,
      lightAngle: lightAngle,
      glassColor: isDark ? darkTint : lightTint,
    );
  }

  /// 深色底纱：近黑，0x6B ≈ 42% 不透明。
  ///
  /// 深色下要够实才读得出「药丸浮在内容之上」，但用户要求**更透明**
  /// —— 底下的课表内容要能透出来。历次调整：0xB3(70%) → 0x6B(42%)。
  static const Color darkTint = Color(0x6B141416);

  /// 浅色底纱：冷白 0x4D ≈ 30%（库默认 `0x3DFFFFFF` 是 24%）。
  ///
  /// 不用纯白：纯白在浅色背景上会显脏。略偏冷的浅灰白
  /// （248/250/252）在高亮度彩色背景（课表图）上也能看出玻璃边界。
  /// 历次调整：0x8C(55%) → 0x4D(30%)，接近库默认的通透度。
  static const Color lightTint = Color(0x4DF8FAFC);
}

/// 液态玻璃**视觉规范**（单一真源）。
///
/// 全项目的玻璃观感都从这一组常量派生：切换主题、调整浓度、改圆角，
/// 都只动这里。分两层：
///
/// | 层 | 能力 | 覆盖方式 |
/// |---|---|---|
/// | **主题层** [decoration] | 圆角 + 半透明底纱 + 描边 + 高光（无模糊） | 一次改动覆盖全项目所有标准控件 |
/// | **组件层** [AppGlass.of] | 真实折射 + 色散 + 模糊（fragment shader） | 用于导航栏、顶栏、卡片等关键控件 |
///
/// 为什么主题层没有模糊：Flutter 的 `ThemeData` 只能给颜色与形状，
/// **无法注入 `BackdropFilter`** —— 模糊必须由组件层承担。
/// 主题层用「半透明 + 描边 + 高光」逼近玻璃观感，保证 300+ 处
/// Material 原生控件在不逐个替换的前提下也统一到同一视觉语言。
class GlassSpec {
  const GlassSpec._();

  // ==========================================================================
  // 圆角
  // ==========================================================================

  /// 输入框 / 次级卡片。
  static const double radiusField = 16;

  /// 按钮、图标按钮、chip。
  static const double radiusButton = 14;

  /// 弹窗、底部弹窗、菜单面板。
  static const double radiusPanel = 24;

  /// 单行列表项。
  static const double radiusTile = 12;

  // ==========================================================================
  // 底纱浓度（alpha 0x00~0xFF）
  // ==========================================================================

  /// 深色：近黑纱。
  static const int tintDark = 0x6B;

  /// 浅色：冷白纱。
  static const int tintLight = 0x4D;

  /// 面板类（弹窗/菜单/底弹）浓度更高：它们浮在内容之上，
  /// 太透会让背后文字干扰阅读。
  static const int tintPanelDark = 0xD9;
  static const int tintPanelLight = 0xE6;

  /// 浅色主题下**卡片**的底纱浓度：90% 纯白。
  ///
  /// 比控件级的 [tintLight]（30%）高得多 —— 控件只承载短语、透一些更有
  /// 玻璃感；卡片是成块的承载面，浅色下若沿用 30% 会让卡片在近白页面上
  /// 「消失」，只剩描边（用户反馈「浅色卡片框里面灰灰的」）。
  ///
  /// 深色卡片继续复用 [tintDark]：深色页面上近黑纱本身就有足够的「身体」，
  /// 不需要再单开一档 —— 这也正是浅色必须单独给值的原因（深浅色不对称）。
  ///
  /// ⚠️ 曾经把同名常量误放在 [AppGlass] 里，而 [decoration] 与 `theme.dart`
  /// 都按 [GlassSpec] 取，直接编译不过。卡片浓度属于「主题层装饰」，
  /// 只能待在 [GlassSpec]。
  static const int tintCardLight = 0xE6;

  // ==========================================================================
  // 描边与高光
  // ==========================================================================

  /// 描边：深色下用亮线（玻璃受光边），浅色下用暗线。
  static const int strokeLight = 0x1FFFFFFF; // 深色主题
  static const int strokeDark = 0x14000000; // 浅色主题

  /// 聚焦/选中描边（跟随主色，由调用方传入 primary 后再调 alpha）。
  static const double strokeFocusedAlpha = 0.75;

  /// 顶部高光：给玻璃厚度感的一道内高光。
  /// 深色主题下的顶部高光：白 8%。深色底上亮线对比明显，是玻璃厚度的主要来源。
  static const int highlightLight = 0x14FFFFFF;

  /// 浅色主题下的顶部高光：白 65%。
  ///
  /// ⚠️ **浅色主题的高光也必须是「亮」的**。这里曾经叫 [highlightDark]、
  /// 值是 0x45000000（27% 黑）—— 在浅色背景上那不是高光而是一圈**灰晕**，
  /// 直接把卡片糊成「灰灰的框」（用户反馈）。浅色下要表现厚度，靠的是
  /// 「更白的卡片 + 纯白高光 + 很淡的向下投影」，不是黑影。
  static const int highlightOnLight = 0xA6FFFFFF;

  /// 浅色主题下的下投影：黑 6%，只负责让卡片浮起来。
  ///
  /// 必须低透明度且向下偏移；大模糊的黑影会在卡片周围形成灰晕。
  static const int liftShadow = 0x0F000000;

  // ==========================================================================
  // 模糊（仅组件层可用）
  // ==========================================================================

  /// 主题层无法模糊，此处仅登记组件层的取值，避免两处不一致。
  static const double blurSigma = 2;

  // ==========================================================================
  // 状态透明度
  // ==========================================================================

  /// 悬停叠加。
  static const double stateHover = 0.08;

  /// 按下叠加。
  static const double statePressed = 0.14;

  /// 禁用透明度。
  static const double stateDisabled = 0.38;

  // ==========================================================================
  // 主题层可直接使用的装饰
  // ==========================================================================

  /// 生成主题层的玻璃装饰：半透明底纱 + 描边 + 顶部高光。
  ///
  /// [isDark] 决定底纱与描边配色；[radius] 见本类顶部圆角阶梯；
  /// [panel] 为 true 时使用更高的底纱浓度（弹窗/菜单等浮层）。
  static BoxDecoration decoration(
    bool isDark, {
    double radius = radiusField,
    bool panel = false,
  }) {
    // 深浅色**分开构造**。此前浅色复用了深色那套思路，导致两个问题：
    //
    // 1. 底纱只有 30%（tintLight），色值又是近白的 #F8FAFC —— 铺在同样
    //    近白的页面背景上几乎等于没有填充，卡片没有「身体」；
    // 2. 「高光」在浅色下传的是深色那支（**27% 黑**，见 [highlightOnLight] 注释），
    //    模糊 6px。在浅色背景上它不是高光，而是一圈**灰蒙蒙的晕**。
    //
    // 两者叠加就是用户看到的「浅色卡片框里面灰灰的」。下面按主题分开给值。
    if (isDark) {
      final alpha = panel ? tintPanelDark : tintDark;
      return BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Color(alpha << 24 | 0x141416),
        border: Border.all(color: Color(strokeLight), width: 0.8),
        boxShadow: const [
          // 深色下高光=亮线，对比明显，是玻璃厚度的主要来源。
          BoxShadow(
            color: Color(highlightLight),
            blurRadius: 6,
            offset: Offset(0, -1),
            spreadRadius: -3,
          ),
        ],
      );
    }

    // 浅色：**纯白卡片**。
    //
    // 底纱提到 90%（面板 90%）且用纯白 #FFFFFF —— 在近白的页面上读起来是
    // 一张清晰的白玻璃卡片，而不是「没有填充 + 一圈灰边」。
    // 高光改成纯白（与深色同一语义，只是浅色下对比更弱），
    // 另外补一层**很淡、向下偏移**的投影负责「浮起来」——
    // 投影必须低透明度且向下，绝不能用大模糊的黑影（那就是灰晕的成因）。
    final alpha = panel ? tintPanelLight : tintCardLight;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: Color(alpha << 24 | 0xFFFFFF),
      border: Border.all(color: Color(strokeDark), width: 0.8),
      boxShadow: const [
        // 顶部高光：纯白，给玻璃厚度。
        BoxShadow(
          color: Color(highlightOnLight),
          blurRadius: 6,
          offset: Offset(0, -1),
          spreadRadius: -3,
        ),
        // 下投影：仅负责让卡片浮起，不参与填充观感。
        BoxShadow(
          color: Color(liftShadow),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    );
  }
}
