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
        // 覆盖包的暗色变体：默认 dark 是 glassColor 白纱 0.08 + saturation 1.2，
        // 在本应用纯黑背景上会明显发白（像磨砂塑料）。这里把白纱压到 0.03、
        // 饱和与高光都调低，让玻璃回到「透」而不是「亮」。
        // 参考酷安：玻璃本身**几乎不染色**，靠背景透出 + 一圈亮边体现。
        //   暗色：黑色半透明纱（不是白纱！白纱会让纯黑背景发灰发白）
        //   浅色：极薄白纱 + 高饱和，让背景色彩透出来
        theme: const GlassThemeData(
          dark: GlassThemeVariant(
            settings: GlassThemeSettings(
              thickness: 10.0,
              blur: 3.0,
              // 玻璃底纱跟着背景调到同一档深炭灰（#1C1C1E 附近），
              // 透明度 0.55 —— 比背景略深一点，玻璃才有「实体」感，
              // 又不至于盖住背景内容。
              glassColor: Color.fromRGBO(28, 28, 30, 0.55),
              lightAngle: 2.356,
              // 打光：之前压到 0.18，玻璃只剩描边没有受光感、像贴纸。
              // 0.45 是「有光但不刺眼」的中间值。
              lightIntensity: 0.45,
              // 边缘光：给玻璃一圈受亮边，是「有厚度」的关键。
              // 注意 GlassThemeSettings 没有 fresnel 字段，
              // 只有 LiquidGlassSettings 才有；此处用主题层能设的上限。
              ambientStrength: 0.10,
              refractiveIndex: 1.2,
              saturation: 1.35,
              chromaticAberration: 0.008,
            ),
          ),
          light: GlassThemeVariant(
            settings: GlassThemeSettings(
              thickness: 12.0,
              blur: 3.0,
              // 浅色只留很薄一层白，背景色彩才能透出来
              glassColor: Color.fromRGBO(255, 255, 255, 0.34),
              lightAngle: 2.356,
              lightIntensity: 0.45,
              // 亮色玻璃同样需要一点环境光，否则只有描边没有体积
              ambientStrength: 0.12,
              refractiveIndex: 1.2,
              // 饱和度拉高，透出来的课表彩色块更鲜明
              saturation: 1.6,
              chromaticAberration: 0.012,
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
