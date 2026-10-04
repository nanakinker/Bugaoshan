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
  static const double thickness = 30;
  static const double blur = 3;
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

  /// 深色底纱：近黑，0xB3 ≈ 70% 不透明。
  ///
  /// 深色下必须够实才能读出「药丸浮在内容之上」；又留三成让课表背景透出，
  /// 避免变成一块死黑板。
  static const Color darkTint = Color(0xB3141416);

  /// 浅色底纱：冷白 0x8C ≈ 55%。
  ///
  /// 不用纯白：纯白在浅色背景上会显脏。略偏冷的浅灰白
  /// （248/250/252）在高亮度彩色背景（课表图）上也能看出玻璃边界。
  static const Color lightTint = Color(0x8CF8FAFC);
}
