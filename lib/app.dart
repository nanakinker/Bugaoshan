import 'dart:async';

// 这个库是为了在iOS上使用CupertinoPageTransitionsBuilder，flutter新版已经分离出来了，不要删
// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/pages/home_page.dart';
import 'package:bugaoshan/pages/wizard/eula_gate_page.dart';
import 'package:bugaoshan/pages/wizard/wizard_page.dart';
import 'package:bugaoshan/providers/app_config_provider.dart';
import 'package:bugaoshan/services/background_cache_service.dart';
import 'package:bugaoshan/services/reminder/live_activity_coordinator.dart';
import 'package:bugaoshan/services/reminder/reminder_service.dart';
import 'package:bugaoshan/theme.dart';
import 'package:bugaoshan/widgets/common/adaptive_widgets.dart';
import 'package:bugaoshan/widgets/common/session_expired_listener.dart';
import 'package:bugaoshan/widgets/eula_content.dart';
import 'package:bugaoshan/widgets/route/mouse_back_handler.dart';
import 'package:bugaoshan/widgets/route/router_utils.dart';
import 'package:system_theme/system_theme.dart';
import 'l10n/app_localizations.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AppConfigProvider _appConfig = getIt<AppConfigProvider>();
  late final BackgroundCacheService _bgCache = getIt<BackgroundCacheService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bgCache.precache();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgCache.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 应用恢复前台时重新触发排期：处理系统设置中的权限变更以及覆盖时间窗口滚动的更新场景。
    if (state != AppLifecycleState.resumed) return;
    // 校验异步单例就绪状态（isReadySync）：避免在冷启动或注册未完成的异步间隙中直接调用
    // `getIt<ReminderService>()` 引发 StateError。
    if (getIt.isReadySync<ReminderService>()) {
      unawaited(getIt<ReminderService>().reschedule());
    }
    // 实时活动必须在前台启动，前台唤醒是核心触发节点；同时用于对齐课间与下一节课程的状态转换。
    if (getIt.isReadySync<LiveActivityCoordinator>()) {
      unawaited(getIt<LiveActivityCoordinator>().tick());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _appConfig.locale,
        _appConfig.themeColor,
        _appConfig.themeColorMode,
        _appConfig.themeMode,
        _appConfig.useGoogleFonts,
        // 页面转场时长跟随设置变化，需要重建 MaterialApp 使新主题生效
        // （「页面切换动画」开关只控制 Dock 栏切换，不进全局主题）
        _appConfig.cardSizeAnimationDuration,
      ]),
      builder: (context, _) => ValueListenableBuilder<bool>(
        // 主题样式（Material 3 / 液态玻璃）变化时重建 MaterialApp，
        // 让 AdaptiveButton / AdaptiveSearchBar 等封装组件同步切换。
        valueListenable: _appConfig.usePackageGlassDock,
        builder: (context, _, __) => MaterialApp(
          navigatorKey: navigatorKey,
          locale: _appConfig.locale.value,
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.bugaoshan,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: _buildTheme(Brightness.light, context),
          darkTheme: _buildTheme(Brightness.dark, context),
          themeMode: _appConfig.themeMode.value,
          builder: (context, child) {
            final scale = MediaQuery.textScalerOf(context).scale(1.0);
            final clamped = scale.clamp(1.0, 2.0);
            return AppConfigScope(
              usePackageGlassDock: _appConfig.usePackageGlassDock.value,
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(clamped)),
                child: MouseBackHandler(
                  // liquid_glass_widgets 不提供 Material 祖先。若树中没有
                  // Material，部分 Text 会显示调试黄色下划线。补一层透明 Material。
                  child: Material(
                    type: MaterialType.transparency,
                    child: SessionExpiredListener(
                      child: child ?? const SizedBox(),
                    ),
                  ),
                ),
              ),
            );
          },
          home: ValueListenableBuilder<int>(
            valueListenable: _appConfig.acceptedEulaVersion,
            builder: (_, eulaVersion, _) {
              if (eulaVersion < currentEulaVersion) {
                return const EulaGatePage();
              }
              return ValueListenableBuilder<bool>(
                valueListenable: _appConfig.firstLaunchWizardCompleted,
                builder: (_, completed, _) =>
                    completed ? const HomePage() : const WizardPage(),
              );
            },
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness, BuildContext context) {
    final seedColor = _appConfig.themeColorMode.value == ThemeColorMode.system
        ? SystemTheme.accentColor.accent
        : _appConfig.themeColor.value;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    return buildTheme(
      brightness: brightness,
      seedColor: seedColor,
      useGoogleFonts: _appConfig.useGoogleFonts.value,
      textScale: textScale,
      pageTransitionDuration: _appConfig.cardSizeAnimationDuration.value,
      // 「设置 → 样式 → 主题样式」开关：液态玻璃样式下，输入框 / 按钮 /
      // 弹窗 / 菜单 / 标签栏 / 开关等标准控件统一改用玻璃族外观（主题层
      // 一次覆盖全项目，无需逐页替换组件）；Material 3 样式保持 MD3 原生。
      // 该 switch 由上方 ValueListenableBuilder 监听，切换时立即重建主题。
      glassStyle: _appConfig.usePackageGlassDock.value,
    );
  }
}
