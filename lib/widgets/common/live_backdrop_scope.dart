import 'package:flutter/widgets.dart';

/// 声明「子树背后是否有**真实可采样的背景内容**（背景图 / 动态画面）」。
///
/// ## 为什么需要它
///
/// 液态玻璃的模糊与折射来自对背后内容的采样。但采样是有代价的：
/// 每个玻璃面每帧都要「保存背景 → 模糊 → 还原」一次整屏合成。
///
/// 而全项目**只有课表页有背景图**（自选壁纸）；其余所有页面背后都是
/// `scaffoldBackgroundColor` 一层**纯色**。对纯色做高斯模糊，结果还是那个
/// 纯色 —— 也就是说这些页面上的实时采样在视觉上是**空操作**，纯属浪费：
/// 校园页一屏 24 张卡 = 每帧 24 次整屏背景采样，这是滑动掉帧、
/// 甚至描边被丢弃（用户反馈「有时候描边都卡没了」）的直接原因。
///
/// ## 用法
///
/// 只有真正画了背景图的页面（课表页）把它标上：
///
/// ```dart
/// LiveBackdropScope(
///   enabled: appConfig.backgroundImagePath.value != null,
///   child: Stack(...),
/// )
/// ```
///
/// [StyledCard] 默认按此判断：**没有标记时用静态绘制的玻璃**（半透明底纱 +
/// 描边 + 高光，像素等价、零滤镜成本），标了才用实时采样。
class LiveBackdropScope extends InheritedWidget {
  const LiveBackdropScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  /// 子树背后是否有真实的背景图 / 动态内容可供采样。
  final bool enabled;

  /// 读取最近的标记；不存在时返回 `false`（视为纯色背景，可用静态玻璃）。
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<LiveBackdropScope>()
          ?.enabled ??
      false;

  @override
  bool updateShouldNotify(LiveBackdropScope oldWidget) =>
      oldWidget.enabled != enabled;
}
