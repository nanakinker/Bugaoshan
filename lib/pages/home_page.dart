import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
                          duration: appConfig.cardSizeAnimationDuration.value,
                          enableAnimation:
                              appConfig.enableDockSwitchAnimation.value,
                          axis: showRail ? Axis.vertical : Axis.horizontal,
                          pageBuilder: (id) => campusItemConfigById(id).page(),
                        );
                      },
                    );
                    return Scaffold(
                      // 让 body 延伸到 Dock 底下，Dock 的 BackdropFilter 才有
                      // 内容可以折射。缺这一行时 body 到 Dock 上沿就截止，
                      // Dock 背后是空背景，玻璃看起来就是一块实心灰板——
                      // 这正是「透不出课表内容」的原因。
                      extendBody: true,
                      body: Row(
                        children: [
                          Offstage(
                            offstage: !showRail,
                            child: SizedBox(
                              width: _railExtent,
                              child: FrostedGlassDock(
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
                          ),
                          // Page content.
                          //
                          // 底部不加 SafeArea：它会与 FrostedGlassDock 自己的
                          // SafeArea 叠加，在 Dock 下方压出一条空白带
                          // （表现为"多一层黑底"），同时挤小可用高度、
                          // 引发 RenderFlex overflow。Dock 内部已处理底部安全区。
                          // 顶部仍需避让状态栏/刘海。
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: MediaQuery.paddingOf(context).top,
                              ),
                              child: pageContent,
                            ),
                          ),
                        ],
                      ),
                      bottomNavigationBar: showBar
                          ? FrostedGlassDock(
                              itemExtent: _barItemExtent,
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
