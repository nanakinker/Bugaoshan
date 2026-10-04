import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_shape.dart';

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

/// MD3 Expressive 组件形状覆盖
const cardTheme = CardThemeData(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppShapes.largeIncreased)),
  ),
);

/// 弹窗玻璃质感。
///
/// 之前只设了圆角，底色是 Material 默认的**不透明**surface，
/// 呈现为一块实心灰板（用户截图里的「绑定房间」弹窗）。
/// 这里改成半透明 + 描边，弹窗背后页面内容可透出。
DialogThemeData dialogTheme({Brightness? brightness}) {
  final isDark = brightness == Brightness.dark;
  return DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(
        Radius.circular(AppShapes.extraLarge),
      ),
      // 亮边：玻璃的厚度感
      side: BorderSide(
        color: isDark ? const Color(0x26FFFFFF) : const Color(0x1F000000),
        width: 0.5,
      ),
    ),
    backgroundColor: isDark ? const Color(0xF21A1A1F) : const Color(0xF2FFFFFF),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
  );
}

const bottomSheetTheme = BottomSheetThemeData(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppShapes.extraLarge),
    ),
  ),
);

const chipTheme = ChipThemeData(shape: StadiumBorder());

const filledButtonTheme = FilledButtonThemeData(
  style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
);

const elevatedButtonTheme = ElevatedButtonThemeData(
  style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
);

const outlinedButtonTheme = OutlinedButtonThemeData(
  style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
);

const textButtonTheme = TextButtonThemeData(
  style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
);

const snackBarTheme = SnackBarThemeData();

final listTileTheme = ListTileThemeData(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppShapes.large),
  ),
);

final dropdownMenuTheme = DropdownMenuThemeData();

ThemeData buildTheme({
  required Brightness brightness,
  required Color seedColor,
  bool useGoogleFonts = false,
  double textScale = 1.0,
  Duration pageTransitionDuration = const Duration(milliseconds: 300),
}) {
  final baseTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ),
    // 暗色背景用**深炭灰**而不是纯黑。
    //
    // 纯黑（#000000）有两个问题：一是 OLED 上渐变断层明显；
    // 二是**玻璃透在纯黑上看不出效果**——没有背景内容可透，
    // 玻璃和纯黑底色对比度太低，看起来像「什么都没画」。
    // 深炭灰（#1C1C1E）让玻璃的透光与边缘高光都能被看见。
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? const Color(0xFF1C1C1E)
        : null,
    pageTransitionsTheme: _pageTransitionsTheme(pageTransitionDuration),
    appBarTheme: appBarTheme(textScale: textScale, brightness: brightness),
    navigationBarTheme: navigationBarTheme(textScale: textScale),
    // MD3 Expressive 组件形状覆盖
    cardTheme: cardTheme,
    dialogTheme: dialogTheme(brightness: brightness),
    bottomSheetTheme: bottomSheetTheme,
    chipTheme: chipTheme,
    filledButtonTheme: filledButtonTheme,
    elevatedButtonTheme: elevatedButtonTheme,
    outlinedButtonTheme: outlinedButtonTheme,
    textButtonTheme: textButtonTheme,
    snackBarTheme: snackBarTheme,
    listTileTheme: listTileTheme,
    dropdownMenuTheme: dropdownMenuTheme,
  );

  TextTheme textTheme = baseTheme.textTheme;
  if (useGoogleFonts) {
    textTheme = GoogleFonts.notoSansScTextTheme(textTheme);
  }
  return baseTheme.copyWith(textTheme: textTheme);
}
