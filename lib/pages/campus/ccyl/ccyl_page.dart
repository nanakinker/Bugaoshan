import 'package:flutter/material.dart';
import 'package:bugaoshan/widgets/common/liquid_title.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/pages/campus/ccyl/activities_tab.dart';
import 'package:bugaoshan/pages/campus/ccyl/my_activities_tab.dart';
import 'package:bugaoshan/pages/campus/ccyl/ordered_activities_tab.dart';
import 'package:bugaoshan/pages/campus/ccyl/credit_list_page.dart';
import 'package:bugaoshan/pages/campus/ccyl/ccyl_bind_page.dart';
import 'package:bugaoshan/providers/ccyl_provider.dart';
import 'package:bugaoshan/providers/scu_auth_provider.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/widgets/common/loading_widgets.dart';
import 'package:bugaoshan/widgets/common/login_required_widget.dart';

class CcylPage extends StatefulWidget {
  const CcylPage({super.key});

  @override
  State<CcylPage> createState() => _CcylPageState();
}

class _CcylPageState extends State<CcylPage> {
  int _currentIndex = 0;

  // 固定实例，配合 IndexedStack 保持各 Tab 滚动位置与数据
  final _tabs = const [
    ActivitiesTab(),
    MyActivitiesTab(),
    OrderedActivitiesTab(),
    CreditListPage(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: Listenable.merge([
        getIt<ScuAuthProvider>(),
        getIt<CcylProvider>(),
      ]),
      builder: (context, _) {
        final auth = getIt<ScuAuthProvider>();
        final ccyl = getIt<CcylProvider>();

        // 未登录校园账号
        if (!auth.isLoggedIn) {
          if (auth.isAutoLoggingIn) {
            return Scaffold(
              appBar: AppBar(
                title: LiquidTitle(text: l10n.ccylTitle, index: _currentIndex),
              ),
              body: const AutoLoginLoadingWidget(),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: LiquidTitle(text: l10n.ccylTitle, index: _currentIndex),
            ),
            body: const LoginRequiredWidget(),
          );
        }

        // 未绑定第二课堂账号
        if (!ccyl.isLoggedIn) {
          return Scaffold(
            appBar: AppBar(
              title: LiquidTitle(text: l10n.ccylTitle, index: _currentIndex),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.ccylBindRequired, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const CcylBindPage(),
                          ),
                        );
                        // ActivitiesTab 会在绑定成功后的新 IndexedStack 中自行加载
                        // 并保存结果；这里预拉且丢弃返回值只会造成重复请求。
                      },
                      icon: const Icon(Icons.login),
                      label: Text(l10n.ccylDoBind),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 正常态：底部导航
        return Scaffold(
          appBar: AppBar(
            title: LiquidTitle(text: l10n.ccylTitle, index: _currentIndex),
          ),
          // IndexedStack 保持各子页面状态（滚动位置、已加载数据）不因切换丢失
          // 标签行从底部挪到顶部：原先它压在bottom Dock 之上，
          // 两层导航叠加导致底部浑浊、玻璃透光被挡。移到顶部后
          // 底部只剩一层玻璃，透光更干净。
          body: Column(
            children: [
              _buildTopTabBar(),
              Expanded(
                child: IndexedStack(index: _currentIndex, children: _tabs),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 顶部紧凑标签栏。
  ///
  /// 从底部挪上来：原先它压在 bottom Dock 之上，两层导航叠加会让底部
  /// 显得浑浊、玻璃透光被挡。移到顶部后底部只剩一层玻璃。
  /// 高度压到 56（NavigationBar 默认 80），减少对内容的占用。
  Widget _buildTopTabBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final labels = <String>[
      l10n.ccylSearchActivities,
      l10n.ccylMyActivities,
      l10n.ccylOrderedActivities,
      l10n.ccylMyCredits,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: GlassCard(
        shape: const LiquidRoundedRectangle(borderRadius: 16),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: _TopTabItem(
                    label: labels[i],
                    selected: i == _currentIndex,
                    isDark: isDark,
                    onTap: () => _onTabTapped(i),
                    accent: scheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 顶部标签栏的单个标签。
///
/// 选中态用一块**淡色玻璃 + 主色文字**表达，不使用实底色块——
/// 实色块在深色主题下会显得浑浊，破坏整体通透感。
class _TopTabItem extends StatelessWidget {
  const _TopTabItem({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(
                    color: accent.withValues(alpha: isDark ? 0.5 : 0.35),
                  )
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? accent : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
