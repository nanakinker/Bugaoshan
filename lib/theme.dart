import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_shape.dart';
import 'widgets/common/app_glass.dart';

/// 页面转场时长跟随「设置 → 动画时长」滑杆（进页与退出同值）；转场形态
/// 维持 Material 规格不变。不直接用规格默认值的原因：Flutter 3.44 起
/// MaterialPageRoute 的时长改由 PageTransitionsBuilder 决定且退出默认等于
/// 进页时长（450-500ms），返回期间退出页占据整屏、下层页面要等动画结束才
/// 能跟手滚动，窗口偏长。
///
/// 注意：「动画时长」页里的「页面切换动画」开关只控制 Dock 栏页面切换动画
/// （见 home_page.dart → AuthScopedIndexedStack），不影响这里的全局转场。
class _AppFadeForwardsBuilder extends FadeForwardsPageTransitionsBuilder {
  const _AppFadeForwardsBuilder(this.duration);

  final Duration duration;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;
}

class _AppPredictiveBackBuilder extends PredictiveBackPageTransitionsBuilder {
  const _AppPredictiveBackBuilder(this.duration);

  final Duration duration;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;
}

class _AppCupertinoBuilder extends CupertinoPageTransitionsBuilder {
  const _AppCupertinoBuilder(this.duration);

  final Duration duration;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;
}

PageTransitionsTheme _pageTransitionsTheme(Duration duration) {
  return PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _AppPredictiveBackBuilder(duration),
      TargetPlatform.iOS: _AppCupertinoBuilder(duration),
      //desktop use FadeForwardsPageTransitionsBuilder
      TargetPlatform.windows: _AppFadeForwardsBuilder(duration),
      TargetPlatform.linux: _AppFadeForwardsBuilder(duration),
      TargetPlatform.macOS: _AppFadeForwardsBuilder(duration),
    },
  );
}

/// AppBar 玻璃质感。
///
/// 原先是完全透明的（`scrolledUnderElevation: 0` + 无背景），
/// 在深色主题下返回键与标题像「浮在空气里」，缺少玻璃的实体感。
/// 这里给一层**极淡的半透明底 + 去掉分隔线**，并把前景色设为
/// onSurface，让返回键与标题读起来是「玻璃上的一层」而非裸文字。
///
/// 走主题层而非逐页替换 `GlassAppBar`：后者要改几十个页面，风险高；
/// 主题改动一次性覆盖所有二级页面。
/// 是否启用 AppBar 玻璃质感。
///
/// 表单页 / 导入页**必须关掉**：它们背后是纯色表单，玻璃没有内容可透，
/// 只会剩一层灰雾（用户截图反馈「添加课程」「从教务系统在线导入」）。
/// 有背景内容可透的页面（课表、校园、我的）才适合玻璃。
bool appBarGlassEnabled = true;

AppBarTheme appBarTheme({double textScale = 1.0, Brightness? brightness}) =>
    _buildAppBarTheme(textScale: textScale, brightness: brightness);

AppBarTheme _buildAppBarTheme({
  double textScale = 1.0,
  Brightness? brightness,
}) {
  // 前景色跟随 **App 当前主题**（不是系统亮度）：用户可能在浅色系统上
  // 手动切到深色主题，所以按 App 的 brightness 判断。
  // 深色主题 → 浅色字；浅色主题 → 深色字。
  final isDark = brightness == Brightness.dark;
  final fg = isDark ? const Color(0xFFEDEDED) : const Color(0xFF1B1B1B);
  return AppBarTheme(
    toolbarHeight: 48 * textScale,
    centerTitle: false,
    scrolledUnderElevation: 0,
    // 半透明底：只留很薄一层白，让下层内容透出。
    // 玻璃关闭时（表单页 / 导入页）退回不透明底，避免灰雾。
    backgroundColor: appBarGlassEnabled
        ? const Color(0x0DFFFFFF)
        : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
    surfaceTintColor: Colors.transparent,
    // 前景色跟随 App 主题：深色主题用浅字、浅色主题用深字。
    // 之前写死 #EDEDED，导致浅色主题下三级页面标题看不清。
    foregroundColor: fg,
    elevation: 0,
    // 之前只给了半透明底、没有描边，玻璃看起来就是「一片发灰的蒙版」。
    // AppBarTheme 没有 border 字段，描边只能通过下面这些阴影近似：
    // 上缘一道极淡白线（受光边）+ 下缘一道更淡的暗线（厚度感）。
    shadowColor: appBarGlassEnabled
        ? const Color(0x33FFFFFF)
        : Colors.transparent,
    titleTextStyle: TextStyle(
      color: fg,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: fg, size: 22),
    // 真正的描边：用带 side 的 ShapeBorder 画出一圈亮边，
    // 这是 AppBarTheme 唯一能拿到「描边」的途径。
    shape: BeveledRectangleBorder(
      side: BorderSide(
        color: appBarGlassEnabled
            ? const Color(0x1FFFFFFF)
            : Colors.transparent,
        width: 0.5,
      ),
    ),
  );
}

NavigationBarThemeData navigationBarTheme({double textScale = 1.0}) =>
    NavigationBarThemeData(height: 64 * textScale);

/// ===========================================================================
/// 玻璃族控件主题
/// ===========================================================================
///
/// 全项目 300+ 处 Material 原生控件（输入框 / 图标按钮 / 弹窗 / 标签栏 /
/// 开关 / 滑杆 / 列表项 / SnackBar …）不逐个替换组件，而是**在主题层统一
/// 改成玻璃族外观**：
///
/// - **圆角** 走 [GlassSpec] 的阶梯（输入框 16 / 按钮 14 / 面板 24 / 列表项 12）；
/// - **底色** 半透明底纱，深色近黑、浅色冷白（浓度见 [GlassSpec]）；
/// - **描边** 深色用亮线、浅色用暗线，0.8dp；
/// - **高光** 面板类加一道顶部内高光，给玻璃厚度感；
/// - **状态** 悬停 8% / 按下 14% / 禁用 38%（[GlassSpec.stateHover] 等）。
///
/// 主题层**不能做模糊**（`ThemeData` 无法注入 `BackdropFilter`），模糊与折射
/// 由组件层的 `GlassCard` / `GlassTabBar` 等承担。两层配合形成统一视觉语言。
///
/// 需要 brightness 的主题都在 [buildTheme] 里按当前主题传入，
/// 保证浅色/深色各自正确 —— 不依赖系统亮度（用户可能在浅色系统上手选深色主题）。

/// 弹窗玻璃质感。
///
/// 之前只设了圆角，底色是 Material 默认的**不透明** surface，
/// 呈现为一块实心灰板（用户截图里的「绑定房间」弹窗）。
/// 这里改成半透明 + 描边，弹窗背后页面内容可透出。
///
/// 底纱浓度用 [GlassSpec.tintPanelDark]/[GlassSpec.tintPanelLight]：
/// 弹窗浮在内容之上，太透会让背后文字干扰阅读。
DialogThemeData dialogTheme({Brightness? brightness}) {
  final isDark = brightness == Brightness.dark;
  return DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(
        Radius.circular(AppShapes.extraLarge),
      ),
      // 亮边：玻璃的厚度感
      side: BorderSide(
        color: Color(isDark ? GlassSpec.strokeLight : GlassSpec.strokeDark),
        width: 0.8,
      ),
    ),
    backgroundColor: isDark
        ? const Color(0xE61A1A1F)
        : const Color(0xE6FFFFFF),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
  );
}

/// 玻璃描边色（主题层通用）。
Color _stroke(Brightness b) =>
    Color(b == Brightness.dark ? GlassSpec.strokeLight : GlassSpec.strokeDark);

/// 面板底纱（弹窗 / 菜单 / 底弹）：浓度高，浮在内容之上要能压住背后文字。
Color _panelTint(Brightness b) {
  final isDark = b == Brightness.dark;
  final alpha = isDark ? GlassSpec.tintPanelDark : GlassSpec.tintPanelLight;
  return Color(alpha << 24 | (isDark ? 0x141416 : 0xF8FAFC));
}

/// 控件底纱（输入框 / chip / 分段按钮）通明度更高，让内容透出来。
Color _controlTint(Brightness b) {
  final isDark = b == Brightness.dark;
  final alpha = isDark ? GlassSpec.tintDark : GlassSpec.tintLight;
  return Color(alpha << 24 | (isDark ? 0x141416 : 0xF8FAFC));
}

/// 输入框：玻璃填充 + 圆角 + 描边，聚焦时描边转主色。
InputDecorationThemeData inputDecorationTheme(
  Brightness brightness,
  ColorScheme scheme,
) {
  final stroke = _stroke(brightness);
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(GlassSpec.radiusField),
    borderSide: BorderSide(color: color, width: width),
  );
  return InputDecorationThemeData(
    filled: true,
    fillColor: _controlTint(brightness),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: border(stroke, 0.8),
    enabledBorder: border(stroke, 0.8),
    // 聚焦：主色描边，玻璃「被点亮」。
    focusedBorder: border(
      scheme.primary.withValues(alpha: GlassSpec.strokeFocusedAlpha),
      1.4,
    ),
    errorBorder: border(scheme.error.withValues(alpha: 0.7), 1),
    focusedErrorBorder: border(scheme.error, 1.4),
    disabledBorder: border(stroke.withValues(alpha: 0.4), 0.8),
    hintStyle: TextStyle(color: scheme.onSurfaceVariant),
    labelStyle: TextStyle(color: scheme.onSurfaceVariant),
    floatingLabelStyle: TextStyle(color: scheme.primary),
    prefixIconColor: scheme.onSurfaceVariant,
    suffixIconColor: scheme.onSurfaceVariant,
    iconColor: scheme.onSurfaceVariant,
    errorStyle: TextStyle(color: scheme.error),
  );
}

/// 图标按钮：默认无底，悬停/按下浮出一层玻璃底（玻璃族交互反馈）。
///
/// 不用 `overlayColor` 的墨水扩散，改成**底纱随状态加浓**，与玻璃一致。
IconButtonThemeData iconButtonTheme(ColorScheme scheme) {
  Color? bg(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return null;
    if (states.contains(WidgetState.pressed)) {
      return scheme.onSurface.withValues(alpha: GlassSpec.statePressed);
    }
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused)) {
      return scheme.onSurface.withValues(alpha: GlassSpec.stateHover);
    }
    return null;
  }

  Color? fg(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return scheme.onSurface.withValues(alpha: GlassSpec.stateDisabled);
    }
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.pressed)) {
      return scheme.onSurface;
    }
    return scheme.onSurfaceVariant;
  }

  return IconButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(bg),
      foregroundColor: WidgetStateProperty.resolveWith(fg),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(GlassSpec.radiusButton),
          ),
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
    ),
  );
}

/// SnackBar：悬浮玻璃片。
SnackBarThemeData snackBarTheme(ColorScheme scheme, Brightness brightness) {
  return SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: _panelTint(brightness),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GlassSpec.radiusPanel - 6),
      side: BorderSide(color: _stroke(brightness), width: 0.8),
    ),
    insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    contentTextStyle: TextStyle(color: scheme.onSurface),
    actionTextColor: scheme.primary,
    actionBackgroundColor: scheme.primary.withValues(alpha: 0.12),
    showCloseIcon: false,
  );
}

/// 底部弹窗：玻璃面板 + 顶部圆角 + 描边。
BottomSheetThemeData bottomSheetTheme(Brightness brightness) {
  final stroke = _stroke(brightness);
  final shape = RoundedRectangleBorder(
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(GlassSpec.radiusPanel),
    ),
    side: BorderSide(color: stroke, width: 0.8),
  );
  final tint = _panelTint(brightness);
  return BottomSheetThemeData(
    backgroundColor: tint,
    modalBackgroundColor: tint,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    modalElevation: 0,
    shape: shape,
  );
}

/// 弹出菜单（PopupMenuButton）：玻璃面板。
PopupMenuThemeData popupMenuTheme(ColorScheme scheme, Brightness brightness) {
  return PopupMenuThemeData(
    color: _panelTint(brightness),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    textStyle: TextStyle(color: scheme.onSurface, fontSize: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GlassSpec.radiusField + 4),
      side: BorderSide(color: _stroke(brightness), width: 0.8),
    ),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(color: scheme.onSurface),
    ),
  );
}

/// 下拉菜单（DropdownMenu / MenuAnchor）：输入框走玻璃，菜单面板走玻璃。
DropdownMenuThemeData dropdownMenuTheme(
  Brightness brightness,
  ColorScheme scheme,
) {
  return DropdownMenuThemeData(
    inputDecorationTheme: inputDecorationTheme(brightness, scheme),
    menuStyle: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(_panelTint(brightness)),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassSpec.radiusField + 4),
          side: BorderSide(color: _stroke(brightness), width: 0.8),
        ),
      ),
    ),
  );
}

/// MenuAnchor 的菜单面板（与下拉共用一套观感）。
MenuThemeData menuTheme(Brightness brightness) {
  return MenuThemeData(
    style: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(_panelTint(brightness)),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassSpec.radiusField + 4),
          side: BorderSide(color: _stroke(brightness), width: 0.8),
        ),
      ),
    ),
  );
}

/// 顶部标签栏：指示条用主色的圆角胶囊，分隔线隐形（玻璃面上不要硬线）。
TabBarThemeData tabBarTheme(ColorScheme scheme) {
  return TabBarThemeData(
    labelColor: scheme.primary,
    unselectedLabelColor: scheme.onSurfaceVariant,
    indicatorColor: scheme.primary,
    indicatorSize: TabBarIndicatorSize.label,
    dividerColor: Colors.transparent,
    dividerHeight: 0,
    overlayColor: WidgetStatePropertyAll(
      scheme.primary.withValues(alpha: GlassSpec.stateHover),
    ),
  );
}

/// 开关：轨道半透明底纱，选中转主色；描边跟着状态走。
SwitchThemeData switchTheme(ColorScheme scheme) {
  return SwitchThemeData(
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.onSurface.withValues(alpha: 0.08);
      }
      if (states.contains(WidgetState.selected)) {
        return scheme.primary.withValues(alpha: 0.55);
      }
      return scheme.onSurface.withValues(alpha: 0.12);
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.transparent;
      }
      return scheme.onSurfaceVariant.withValues(alpha: 0.5);
    }),
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.onSurface.withValues(alpha: GlassSpec.stateDisabled);
      }
      if (states.contains(WidgetState.selected)) {
        return scheme.onPrimary;
      }
      return scheme.onSurfaceVariant;
    }),
  );
}

/// 滑杆：轨道半透明、滑块主色、托盘圆角 —— 与玻璃按钮同一语言。
SliderThemeData sliderTheme(ColorScheme scheme) {
  return SliderThemeData(
    activeTrackColor: scheme.primary,
    inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.12),
    thumbColor: scheme.primary,
    overlayColor: scheme.primary.withValues(alpha: GlassSpec.stateHover),
    trackHeight: 6,
    activeTickMarkColor: Colors.transparent,
    inactiveTickMarkColor: Colors.transparent,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
  );
}

/// 复选框：圆角方形，未选是玻璃空框，选中填主色。
CheckboxThemeData checkboxTheme(ColorScheme scheme) {
  return CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.onSurface.withValues(alpha: 0.08);
      }
      if (states.contains(WidgetState.selected)) {
        return scheme.primary.withValues(alpha: 0.9);
      }
      return Colors.transparent;
    }),
    checkColor: WidgetStatePropertyAll(scheme.onPrimary),
    side: BorderSide(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      width: 1.4,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
    ),
    overlayColor: WidgetStatePropertyAll(
      scheme.primary.withValues(alpha: GlassSpec.stateHover),
    ),
  );
}

/// 单选：选中填主色。
RadioThemeData radioTheme(ColorScheme scheme) {
  return RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.onSurface.withValues(alpha: GlassSpec.stateDisabled);
      }
      if (states.contains(WidgetState.selected)) return scheme.primary;
      return scheme.onSurfaceVariant;
    }),
    overlayColor: WidgetStatePropertyAll(
      scheme.primary.withValues(alpha: GlassSpec.stateHover),
    ),
  );
}

/// 分段按钮：选中项浮出一层主色玻璃，未选透明。
SegmentedButtonThemeData segmentedButtonTheme(
  ColorScheme scheme,
  Brightness brightness,
) {
  return SegmentedButtonThemeData(
    style: ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      side: WidgetStatePropertyAll(
        BorderSide(color: _stroke(brightness), width: 0.8),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(GlassSpec.radiusButton)),
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return scheme.primary.withValues(alpha: 0.22);
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return scheme.primary;
        return scheme.onSurfaceVariant;
      }),
    ),
  );
}

/// 标签：玻璃底 + 描边。
ChipThemeData chipTheme(ColorScheme scheme, Brightness brightness) {
  return ChipThemeData(
    backgroundColor: _controlTint(brightness),
    side: BorderSide(color: _stroke(brightness), width: 0.8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GlassSpec.radiusButton),
    ),
    labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
    secondaryLabelStyle: TextStyle(color: scheme.onSurfaceVariant),
    elevation: 0,
    pressElevation: 0,
    surfaceTintColor: Colors.transparent,
  );
}

/// 列表项：圆角 + 选中态用主色淡玻璃，不设底色（避免与卡片玻璃叠两层）。
ListTileThemeData listTileTheme(ColorScheme scheme) {
  return ListTileThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GlassSpec.radiusTile),
    ),
    tileColor: Colors.transparent,
    selectedTileColor: scheme.primary.withValues(alpha: 0.12),
    iconColor: scheme.onSurfaceVariant,
    textColor: scheme.onSurface,
    selectedColor: scheme.primary,
  );
}

/// 进度指示：主色 + 半透明轨道。
ProgressIndicatorThemeData progressIndicatorTheme(ColorScheme scheme) {
  return ProgressIndicatorThemeData(
    color: scheme.primary,
    linearTrackColor: scheme.onSurface.withValues(alpha: 0.12),
    circularTrackColor: scheme.onSurface.withValues(alpha: 0.10),
    linearMinHeight: 6,
  );
}

/// 提示气泡：玻璃面板。
TooltipThemeData tooltipTheme(ColorScheme scheme, Brightness brightness) {
  return TooltipThemeData(
    decoration: BoxDecoration(
      color: _panelTint(brightness),
      borderRadius: BorderRadius.circular(GlassSpec.radiusTile),
      border: Border.all(color: _stroke(brightness), width: 0.8),
    ),
    textStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    waitDuration: const Duration(milliseconds: 400),
  );
}

/// 搜索框（SearchBar）。
SearchBarThemeData searchBarTheme(ColorScheme scheme, Brightness brightness) {
  return SearchBarThemeData(
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: WidgetStatePropertyAll(_controlTint(brightness)),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    side: WidgetStatePropertyAll(
      BorderSide(color: _stroke(brightness), width: 0.8),
    ),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(GlassSpec.radiusField)),
      ),
    ),
    textStyle: WidgetStatePropertyAll(TextStyle(color: scheme.onSurface)),
    hintStyle: WidgetStatePropertyAll(
      TextStyle(color: scheme.onSurfaceVariant),
    ),
    overlayColor: WidgetStatePropertyAll(
      scheme.primary.withValues(alpha: GlassSpec.stateHover),
    ),
  );
}

/// 底部工具条：半透明玻璃。
BottomAppBarThemeData bottomAppBarTheme(Brightness brightness) {
  return BottomAppBarThemeData(
    color: _panelTint(brightness),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  );
}

/// 光标与选中：跟随主色，让输入框在玻璃上也读得清。
TextSelectionThemeData textSelectionTheme(ColorScheme scheme) {
  return TextSelectionThemeData(
    cursorColor: scheme.primary,
    selectionColor: scheme.primary.withValues(alpha: 0.3),
    selectionHandleColor: scheme.primary,
  );
}

/// 分割线：极淡，玻璃面上不要硬线。
DividerThemeData dividerTheme(ColorScheme scheme) {
  return DividerThemeData(
    color: scheme.onSurface.withValues(alpha: 0.12),
    thickness: 0.8,
    space: 0.8,
  );
}

/// 卡片：MD3 Expressive 圆角 + 半透明底 + 描边（裸 [Card] 也统一到玻璃族）。
///
/// 注意卡片底纱用**卡片专用浓度**而不是 [_controlTint]：
/// 控件级浓度（浅色 30%）是给"输入框/标签"这类小面积控件用的，
/// 卡片是成块的承载面，浅色下沿用 30% 会在近白页面上"消失"，
/// 只剩一圈描边 —— 看起来就是「灰灰的框」（用户反馈）。
CardThemeData cardTheme(Brightness brightness) {
  final stroke = _stroke(brightness);
  final isDark = brightness == Brightness.dark;
  final cardTint = isDark
      ? (GlassSpec.tintDark << 24 | 0x141416)
      : (GlassSpec.tintCardLight << 24 | 0xFFFFFF);
  return CardThemeData(
    color: Color(cardTint),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(
        Radius.circular(AppShapes.largeIncreased),
      ),
      side: BorderSide(color: stroke, width: 0.8),
    ),
  );
}

/// 按钮：玻璃底纱 + 圆角 + 描边；主按钮用主色淡底保持可读性。
///
/// [filled] 为 true 时给主色淡底（主要 CTA，如「查询」），
/// 否则透明底（次级按钮）。
ButtonStyle _glassButtonStyle(
  ColorScheme scheme,
  Brightness brightness, {
  required bool filled,
}) {
  return ButtonStyle(
    elevation: const WidgetStatePropertyAll(0),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(GlassSpec.radiusButton)),
      ),
    ),
    side: WidgetStatePropertyAll(
      BorderSide(color: _stroke(brightness), width: 0.8),
    ),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.onSurface.withValues(alpha: 0.06);
      }
      if (filled) {
        if (states.contains(WidgetState.pressed)) {
          return scheme.primary.withValues(alpha: 0.88);
        }
        if (states.contains(WidgetState.hovered)) {
          return scheme.primary.withValues(alpha: 0.82);
        }
        return scheme.primary.withValues(alpha: 0.78);
      }
      if (states.contains(WidgetState.pressed)) {
        return scheme.onSurface.withValues(alpha: GlassSpec.statePressed);
      }
      if (states.contains(WidgetState.hovered)) {
        return scheme.onSurface.withValues(alpha: GlassSpec.stateHover);
      }
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.onSurface.withValues(alpha: GlassSpec.stateDisabled);
      }
      return filled ? scheme.onPrimary : scheme.onSurface;
    }),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  );
}

/// 文字按钮：无描边、无底，只保留主色文字与状态叠加。
ButtonStyle _glassTextButtonStyle(ColorScheme scheme) {
  return ButtonStyle(
    elevation: const WidgetStatePropertyAll(0),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(GlassSpec.radiusButton)),
      ),
    ),
    side: const WidgetStatePropertyAll(BorderSide.none),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return scheme.primary.withValues(alpha: GlassSpec.statePressed);
      }
      if (states.contains(WidgetState.hovered)) {
        return scheme.primary.withValues(alpha: GlassSpec.stateHover);
      }
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.onSurface.withValues(alpha: GlassSpec.stateDisabled);
      }
      return scheme.primary;
    }),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  );
}

ThemeData buildTheme({
  required Brightness brightness,
  required Color seedColor,
  bool useGoogleFonts = false,
  double textScale = 1.0,
  Duration pageTransitionDuration = const Duration(milliseconds: 300),
  /// 是否启用**玻璃族控件主题**（由「设置 → 样式 → 主题样式」开关传入）。
  ///
  /// - `true`（液态玻璃）：输入框/按钮/弹窗/菜单/标签栏/开关等全部走
  ///   玻璃族外观，见本文件上方「玻璃族控件主题」。
  /// - `false`（Material 3）：保持 MD3 原生观感，只保留重构前就有的
  ///   圆角与形状覆盖，避免把 Material 样式也玻璃化。
  bool glassStyle = true,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );

  // 两种样式**共有**的部分。
  final baseTheme = ThemeData(
    colorScheme: scheme,
    // 暗色背景用**深炭灰**而不是纯黑：纯黑在 OLED 上渐变断层明显，
    // 且玻璃透在纯黑上看不出效果（没有内容可透）。
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? const Color(0xFF1C1C1E)
        : null,
    pageTransitionsTheme: _pageTransitionsTheme(pageTransitionDuration),
    appBarTheme: appBarTheme(textScale: textScale, brightness: brightness),
    navigationBarTheme: navigationBarTheme(textScale: textScale),
    // Material 3 样式下的形状覆盖（重构前既有行为，保持不变）。
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(AppShapes.largeIncreased),
        ),
      ),
    ),
    dialogTheme: dialogTheme(brightness: brightness),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppShapes.extraLarge),
        ),
      ),
    ),
    chipTheme: const ChipThemeData(shape: StadiumBorder()),
    filledButtonTheme: const FilledButtonThemeData(
      style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
    ),
    elevatedButtonTheme: const ElevatedButtonThemeData(
      style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
    ),
    outlinedButtonTheme: const OutlinedButtonThemeData(
      style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
    ),
    snackBarTheme: const SnackBarThemeData(),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.large),
      ),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(),
  );

  // 玻璃族控件主题只在液态玻璃样式下覆盖 —— 主题层一次改动即覆盖
  // 全项目所有标准控件，无需逐页替换组件。
  final resolved = glassStyle
      ? baseTheme.copyWith(
          inputDecorationTheme: inputDecorationTheme(brightness, scheme),
          iconButtonTheme: iconButtonTheme(scheme),
          cardTheme: cardTheme(brightness),
          bottomSheetTheme: bottomSheetTheme(brightness),
          popupMenuTheme: popupMenuTheme(scheme, brightness),
          dropdownMenuTheme: dropdownMenuTheme(brightness, scheme),
          menuTheme: menuTheme(brightness),
          chipTheme: chipTheme(scheme, brightness),
          listTileTheme: listTileTheme(scheme),
          tabBarTheme: tabBarTheme(scheme),
          switchTheme: switchTheme(scheme),
          sliderTheme: sliderTheme(scheme),
          checkboxTheme: checkboxTheme(scheme),
          radioTheme: radioTheme(scheme),
          segmentedButtonTheme: segmentedButtonTheme(scheme, brightness),
          progressIndicatorTheme: progressIndicatorTheme(scheme),
          tooltipTheme: tooltipTheme(scheme, brightness),
          searchBarTheme: searchBarTheme(scheme, brightness),
          bottomAppBarTheme: bottomAppBarTheme(brightness),
          textSelectionTheme: textSelectionTheme(scheme),
          dividerTheme: dividerTheme(scheme),
          snackBarTheme: snackBarTheme(scheme, brightness),
          filledButtonTheme: FilledButtonThemeData(
            style: _glassButtonStyle(scheme, brightness, filled: true),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: _glassButtonStyle(scheme, brightness, filled: true),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: _glassButtonStyle(scheme, brightness, filled: false),
          ),
          textButtonTheme: TextButtonThemeData(
            style: _glassTextButtonStyle(scheme),
          ),
        )
      : baseTheme;

  TextTheme textTheme = resolved.textTheme;
  if (useGoogleFonts) {
    textTheme = GoogleFonts.notoSansScTextTheme(textTheme);
  }
  return resolved.copyWith(textTheme: textTheme);
}
