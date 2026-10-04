import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/models/campus_item_config.dart';
import 'package:bugaoshan/models/student_type.dart';
import 'package:bugaoshan/providers/app_config_provider.dart';
import 'package:bugaoshan/providers/app_info_provider.dart';
import 'package:bugaoshan/providers/scu_auth_provider.dart';
import 'package:bugaoshan/providers/update_provider.dart';
import 'package:bugaoshan/utils/app_log.dart';
import 'package:bugaoshan/services/auth/auth_coordinator.dart';
import 'package:bugaoshan/services/widget_update_service.dart';
import 'package:bugaoshan/utils/constants.dart';
import 'package:bugaoshan/widgets/common/auth_scoped_indexed_stack.dart';
import 'package:bugaoshan/widgets/common/frosted_glass_dock.dart';
import 'package:bugaoshan/widgets/common/package_glass_dock.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForUpdateInBackground();
    _attemptAutoLogin();
  }

  Future<void> _attemptAutoLogin() async {
    try {
      await getIt.isReady<ScuAuthProvider>();
      final authProvider = getIt<ScuAuthProvider>();
      if (authProvider.isLoggedIn) {
        unawaited(getIt<AuthCoordinator>().warmUpAll());
        return;
      }
      await authProvider.autoLogin();
    } catch (e) {
      AppLog.w('HomePage', 'Auto login attempt error: $e');
    }
  }

  Future<void> _checkForUpdateInBackground() async {
    try {
      await Future.wait([
        getIt.isReady<AppInfoProvider>(),
        getIt.isReady<UpdateProvider>(),
        getIt.isReady<AppConfigProvider>(),
      ]);
      final updateProvider = getIt<UpdateProvider>();
      final appConfig = getIt<AppConfigProvider>();
      final result = await updateProvider.checkForUpdate();
      if (result.hasUpdate) {
        appConfig.hasUpdateNotification.value = true;
      }
    } catch (e) {
      AppLog.w('HomePage', 'CheckForUpdateInBackground error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateWidget();
    }
  }

  Future<void> _updateWidget() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      try {
        await getIt<WidgetUpdateService>().updateWidgetData();
      } catch (e) {
        AppLog.e('HomePage', 'Widget update failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainScreen();
  }

  Widget _buildUpdateBadge({required Widget child, required bool showBadge}) {
    if (!showBadge) return child;
    return Badge(child: child);
  }

  Widget _buildMainScreen() {
    final appConfig = getIt<AppConfigProvider>();
    final authProvider = getIt<ScuAuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<List<String>>(
      valueListenable: appConfig.visibleDockIds,
      builder: (context, savedIds, _) {
        // dock 中不属于当前学生身份的功能项临时隐藏，
        // 不改动 visibleDockIds 里保存的配置，切回身份后恢复。
        return ValueListenableBuilder<StudentType>(
          valueListenable: appConfig.studentType,
          builder: (context, studentType, _) {
            final visibleIds = [
              for (final id in savedIds)
                if (campusItemVisibleForStudentType(
                  campusItemConfigById(id),
                  studentType,
                ))
                  id,
            ];
            _clampCurrentIndex(visibleIds);

            return ValueListenableBuilder<bool>(
              valueListenable: appConfig.hasUpdateNotification,
              builder: (context, hasUpdate, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final theme = Theme.of(context);
                    final isWide = constraints.maxWidth >= 600;
                    final showRail = isWide && visibleIds.length >= 2;
                    final showBar = !isWide && visibleIds.length >= 2;
                    final pageContent = ListenableBuilder(
                      listenable: Listenable.merge([
                        appConfig.cardSizeAnimationDuration,
                        appConfig.enableDockSwitchAnimation,
                      ]),
                      builder: (context, _) {
                        return AuthScopedIndexedStack(
                          authListenable: authProvider,
                          isAuthenticated: () => authProvider.isLoggedIn,
                          visibleIds: visibleIds,
                          selectedIndex: _currentIndex,
                          // 页面切换改为**瞬时**（用户要求）：课表 / 校园 / 我的 /
                          // 电费 之间直接跳变，不做横向滑动。
                          // 动效只保留在底部 Dock 的玻璃透镜上，由
                          // PackageGlassDock 内部的 liquid morph 实现。
                          // 原因：页面滑动时整个子页（含课表格子 / 卡片列表）
                          // 要重新布局与光栅化，是掉帧的主要来源；
                          // 而 Dock 只是一个固定的小部件，动画开销极低。
                          duration: Duration.zero,
                          enableAnimation: false,
                          axis: showRail ? Axis.vertical : Axis.horizontal,
                          pageBuilder: (id) => campusItemConfigById(id).page(),
                        );
                      },
                    );
                    // ── GlassScaffold 而非 Material Scaffold ──
                    //
                    // 玻璃要折射出颜色，背后必须有一个**受控的背景源**。
                    // 官方文档明确要求：带玻璃导航栏的页面必须用
                    // `GlassScaffold`，它负责背景源、渲染层、z-order、
                    // 边缘淡出与安全区。用 Material `Scaffold` 塞
                    // `GlassTabBar` 时这些全都缺失 —— 玻璃没有东西可折射，
                    // 观感与官方 demo 明显不同。
                    //
                    // `extendBody` 在 GlassScaffold 里默认为 true，body 会
                    // 延伸到导航条下方并自动加顶部占位，取代原先手写的
                    // extendBody + SizedBox 安全区。
                    return GlassScaffold(
                      extendBody: true,
                      // 内容感知亮度：官方用它把 body 包进
                      // GlassContentAwareContent，让导航栏图标/标签按**背后
                      // 内容的实际明暗**自动翻转（深色内容转亮色图标）。
                      // 课表页是彩色格子 + 可选背景图，明暗变化大，开关后
                      // 滑到深色课程上时图标不会糊成一片。
                      contentAwareBrightness: true,
                      // 状态栏图标按主题自动取色：深色背景用浅色图标，浅色
                      // 背景用深色图标。
                      //
                      // 默认值是 `GlassStatusBarStyle.none` —— 完全不干预，
                      // 状态栏图标颜色由系统决定。深色背景下用系统默认的
                      // 深色图标会「隐形」（用户截图：左上角时间几乎看不见）。
                      statusBarStyle: GlassStatusBarStyle.auto,
                      // 背景色同时用作边缘淡出的目标色。用容器深炭灰而非
                      // 依赖 CupertinoTheme 默认值（后者在 Material 深色
                      // 主题下会带一层不预期的暗色wash）。
                      backgroundColor: theme.scaffoldBackgroundColor,
                      // 关掉边缘渐变。
                      //
                      // `GlassScaffold` 的 edge fade 会用 `backgroundColor`
                      // 作为渐变**目标色**（源码注释明确写了：设了 `background`
                      // 时这是 backgroundColor 唯一的可见作用）。本应用深浅色
                      // 共用同一个 `scaffoldBackgroundColor`（浅色下是近白），
                      // 于是底部导航条上方会渐变出一层与主题不符的色带 ——
                      // 浅色主题下表现为「最底部包了一层黑色东西」
                      // （用户截图），深色下则是一道突兀的深色横条。
                      //
                      // 本应用的导航条是悬浮药丸，本就不需要 iOS 那种
                      // 内容淡出效果，关闭更干净。
                      edgeFade: false,
                      body: Row(
                        children: [
                          // 宽屏侧边栏：**窄屏时完全不创建**，而不是用
                          // Offstage 隐藏。
                          //
                          // Offstage 只跳过布局与绘制，但 `GlassCard` 会把
                          // 自己注册进 GlassScaffold 的合成层并申请 shader
                          // 图层；被压到 84px 宽的竖排 Dock 仍会在页面左侧
                          // 渲染出一块溢出的玻璃碎片（用户截图：左上角出现
                          // 尖角括号框 + 圆角框的残影）。
                          // 窄屏压根不构建这条分支，干净。
                          if (showRail)
                            SizedBox(
                              width: _railExtent,
                              child: PackageGlassDock(
                                axis: Axis.vertical,
                                itemExtent: _railExtent,
                                duration:
                                    appConfig.cardSizeAnimationDuration.value,
                                items: _buildDockItems(
                                  visibleIds,
                                  hasUpdate,
                                  l10n,
                                ),
                                selectedIndex: _currentIndex,
                                onSelected: (index) {
                                  setState(() => _currentIndex = index);
                                },
                              ),
                            ),
                          Expanded(
                            child: Padding(
                              // 顶部不加安全区：加了会把子页整体下推，
                              // 导致课表背景图铺不到状态栏（用户反馈）。
                              padding: EdgeInsets.zero,
                              child: pageContent,
                            ),
                          ),
                        ],
                      ),
                      // 导航栏只保留液态玻璃（社区包 liquid_glass_widgets）。
                      bottomBar: showBar
                          ? PackageGlassDock(
                              itemExtent: _barItemExtent,
                              duration:
                                  appConfig.cardSizeAnimationDuration.value,
                              items: _buildDockItems(
                                visibleIds,
                                hasUpdate,
                                l10n,
                              ),
                              selectedIndex: _currentIndex,
                              onSelected: _onDockSelected,
                              axis: Axis.horizontal,
                            )
                          : null,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _onDockSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _clampCurrentIndex(List<String> ids) {
    if (ids.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= ids.length) {
      _currentIndex = ids.length - 1;
    }
  }

  /// 侧边 Dock 的固定宽度。
  static const double _railExtent = 84;

  /// 底部 Dock 单个 item 的高度（即药丸形 Dock 的总高度）。
  ///
  /// 取 72 而非原`NavigationBar` 的 64：药丸形两端为半圆，需要更多纵向空间
  /// 才不会显得拥挤，同时给标签留出呼吸感。
  // 导航条单格高度。曾因误读截图（以为是 Dock 挤压）临时加到 84，
  // 实际用户反馈的是「我的」页信息区太挤，与 Dock 无关，故保持原值。
  static const double _barItemExtent = 72;

  /// 把可见的 Dock 项转换为毛玻璃导航条所需的 item 列表。
  ///
  /// 底部与侧边共用这一份构建逻辑，仅呈现方向不同。更新提示的 `Badge`
  /// 挂在个人中心项上，与原实现保持一致。
  List<FrostedGlassDockItem> _buildDockItems(
    List<String> visibleIds,
    bool hasUpdate,
    AppLocalizations l10n,
  ) {
    return visibleIds.map((id) {
      final config = campusItemConfigById(id);
      final isProfile = id == dockIdProfile;
      return FrostedGlassDockItem(
        icon: isProfile
            ? _buildUpdateBadge(showBadge: hasUpdate, child: Icon(config.icon))
            : Icon(config.icon),
        selectedIcon: isProfile
            ? _buildUpdateBadge(
                showBadge: hasUpdate,
                child: Icon(config.selectedIcon),
              )
            : Icon(config.selectedIcon),
        label: config.dockLabel(l10n),
        semanticLabel: config.dockFullLabel(l10n),
      );
    }).toList();
  }
}
