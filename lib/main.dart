import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bugaoshan/app.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/pages/startup_error_app.dart';
import 'package:bugaoshan/services/window_state_service.dart';
import 'package:system_theme/system_theme.dart';
import 'package:bugaoshan/services/update_service.dart';

Future<void> main() async {
  try {
    await _initializeApp();
    // liquid_glass_widgets 要求用 wrap 包住应用根节点；MaterialApp 需显式
    // 提供 brightnessResolver，否则玻璃层拿不到当前主题亮度。
    runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      // 官方文档推荐 adaptiveQuality: true，但包源码里它标注为
      // **experimental**（默认 false），会按设备光栅预算自动下调质量档 ——
      // 而导航栏/顶栏的 premium（折射+色散）正是本应用刻意要的，自动降级
      // 会把它退回 standard，观感又变成「干净但平」。故保持关闭，由各组件
      // 显式声明质量档。
      adaptiveQuality: false,
      // 自动读取系统「减弱动态效果 / 增强对比度」并降级无障碍表现。
      respectSystemAccessibility: true,
        // 全局玻璃主题：**只覆盖 glassColor，其余光学参数全部交回库默认值**。
        //
        // 玻璃的「像不像玻璃」由 thickness / blur / fresnel / 折射 / 高光决定，
        // 这些交给库的原生默认即可（fresnelStrength 1.0、thickness 20、blur 5、
        // refractiveIndex 1.2、saturation 1.5、glowIntensity 0.75）。
        //
        // 唯一必须覆盖的是 glassColor —— 库的默认是**完全透明**
        //（ARGB(0,255,255,255)），在本应用近乎纯黑的深色背景上会读不出玻璃感，
        // 所以给一层与背景同档的深炭灰薄纱，让玻璃「透」出来而不是「亮」起来。
        // 注意浓度要低：0.5 以上会让玻璃变成不透明的灰色板，直接盖住底下的内容。
        theme: const GlassThemeData(
          dark: GlassThemeVariant(
            settings: GlassThemeSettings(
              // 深色玻璃底纱：深炭灰，浓度 0.62。
              //
              // 为什么必须在**全局主题**里改，而不是给每个组件传
              // `GlassTabBar(settings: LiquidGlassSettings(...))`：
              //
              // 1. 包内部 `kBottomBarGlassDefaults`硬编码
              //    `glassColor: Color(0x3DFFFFFF)`（~24% 白）且不随主题变化
              //    → 深色模式下 Dock 药丸会变成「浅白色塑料」。
              // 2. 但 `tab_bar_bottom_layout.dart:256` 是
              //    `widget.settings ?? _defaultGlassSettings` ——
              //    组件级 `settings` 是**整体替换**语义，一旦传入，
              //    thickness 30 / blur 3 / refractiveIndex 1.59 /
              //    chromaticAberration 0.3 / lightAngle 0.75π 全部丢失。
              // 3. `GlassThemeSettings` 才是**部分覆盖**语义
              //    （`null` = 沿用组件自身默认，见 glass_theme_settings.dart
              //    开头的说明），且light/dark 自动分流。
              //
              // 所以：底纱色交给主题，光学参数一律不碰 —— 玻璃质感与官方
              // demo 完全一致，只在深色下把白纱换成黑纱。
              //
              // 深炭灰而非纯黑：与 lib/theme.dart 的 scaffoldBackgroundColor
              // 0xFF1C1C1E 同档，玻璃靠背景透出与边缘菲涅尔高光表达质感。
              //
              // 浓度 0.82：早期用 0.62 时，玻璃下方的课表背景（图片）透得太
              // 明显，视觉上像是「背景图压在顶栏之上」而不是顶栏浮在背景之上
              // （用户反馈「好像不是在图层的最上方」「透明度有点高」）。
              // 提到 0.82 后底纱足够实，顶栏读起来是明确的一层；
              // 折射与色散仍由库预设计算，不受影响。
              glassColor: Color.fromRGBO(20, 20, 22, 0.82),
            ),
          ),
          light: GlassThemeVariant(
            settings: GlassThemeSettings(
              // 浅色：0.55 的白纱（原 0.30 太薄）。
              //
              // 0.30 在课表这种**高亮度彩色背景**上几乎看不出玻璃边界 ——
              // 用户反馈「描边不可见，看不出来有玻璃质感」。玻璃需要足够
              // 浓度才能在亮背景上「浮起来」，但纯白在浅色下又会显脏，
              // 所以用略偏冷的浅灰白（248/250/252）而不是纯白。
              glassColor: Color.fromRGBO(248, 250, 252, 0.55),
            ),
          ),
        ),
        child: const MyApp(),
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('Startup error: $error\n$stackTrace');
    runApp(StartupErrorApp(errorMessage: stackTrace.toString()));
  }
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    DartPluginRegistrant.ensureInitialized();
    if (_isDesktopPlatform) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
  configureDependencies();
  await ensureBasicDependencies();

  // 清理下载的安装包（首次打开或更新后）。
  unawaited(getIt<UpdateService>().cleanupOldPackages());

  // 桌面端记住窗口位置和大小，下次启动时恢复
  if (!kIsWeb && _isDesktopPlatform) {
    await WindowStateService.create(getIt<SharedPreferences>());
  }

  // 获取系统主题颜色
  SystemTheme.fallbackColor = Colors.blue;
  await SystemTheme.accentColor.load();

  // 启动时不再在 main 进行图片解码或等待；预加载交由 app 层在 post-frame 时处理，以避免重复加载与启动阻塞。
  //
  // liquid_glass_widgets 的 shader 预热必须放在 runApp 之前。该调用只做
  // 磁盘到内存的异步 I/O，不会在首帧前触发 GPU 绘制。
  // 预热失败不应阻断启动——导航条会退化为无 shader 的降级渲染。
  try {
    await LiquidGlassWidgets.initialize();
  } catch (error) {
    debugPrint('Liquid glass shader warm-up skipped: $error');
  }
}

bool get _isDesktopPlatform {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}
