import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:bugaoshan/widgets/common/adaptive_widgets.dart';
import 'package:bugaoshan/widgets/common/app_glass.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/models/course.dart';
import 'package:bugaoshan/providers/app_config_provider.dart';
import 'package:bugaoshan/theme_shape.dart';

/// 切换课表菜单里「管理课表」项的哨兵值，不会与课表 id 冲突。
const _kScheduleManagementMenuValue = '__management__';

class CoursePageTopBar extends StatelessWidget {
  final int visibleWeek;
  final int totalWeeks;
  final int actualWeek;
  final bool isViewingVacation;
  final bool isTodayOnVacation;
  final bool isNotStarted;
  final bool canGoPrevious;
  final bool canGoNext;
  final Duration animationDuration;

  final VoidCallback onPreviousWeek;
  final VoidCallback? onNextWeek;
  final VoidCallback onGoToCurrentWeek;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onAddCourse;

  /// 课表快捷切换：多于一份课表时在右侧按钮区最前显示弹窗菜单。
  final List<ScheduleConfig> schedules;
  final String? currentScheduleId;
  final ValueChanged<String> onSwitchSchedule;
  final VoidCallback onOpenScheduleManagement;

  const CoursePageTopBar({
    super.key,
    required this.visibleWeek,
    required this.totalWeeks,
    required this.actualWeek,
    this.isViewingVacation = false,
    this.isTodayOnVacation = false,
    this.isNotStarted = false,
    this.canGoPrevious = false,
    this.canGoNext = false,
    required this.animationDuration,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onGoToCurrentWeek,
    required this.onImport,
    required this.onExport,
    required this.onAddCourse,
    this.schedules = const [],
    this.currentScheduleId,
    required this.onSwitchSchedule,
    required this.onOpenScheduleManagement,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCurrentCalendarWeek = visibleWeek == actualWeek;

    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month}/${now.day}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: GlassCard(
              // 时间/周次区包一层玻璃，与右侧按钮组视觉呼应。
              // 不覆写 quality —— 走库的默认档，由它自己按场景选。
              // （曾经在这里写过 quality: minimal，结果该档在部分设备上
              //   渲成黑块；现在交给库默认反而稳定。）
              // 圆角与右侧按钮组统一（都是 16），否则并排看描边不一致。
              shape: const LiquidRoundedRectangle(borderRadius: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              clipBehavior: Clip.antiAlias,
              // premium：GlassCard 默认 standard，没有色散与真实折射。
              // 顶栏属于官方指定的 hero surface（导航/控件层），用 premium
              // 才与右侧按钮组、底部 Dock 的玻璃质感一致。
              quality: GlassQuality.premium,
              // useOwnLayer: true —— 自建折射层，**切断**向祖先 glass 层
              // 的 settings 继承。
              //
              // 原因（`adaptive_glass.dart:176-204`）：grouped 模式（默认）下
              // 组件的 `settings` 只是一个 const 占位，真实参数取自
              // `inherited.settings`（最近的祖先 LiquidGlassLayer）。
              // 本组件位于课表页内，很可能继承到外层某个浓度不同的层，
              // 于是顶栏玻璃与当前主题不符 —— 浅色主题下看不到描边
              // （用户反馈「怀疑不在图层最顶层」，实际是继承了错的层）。
              //
              // 自建层后走 `useExplicitSettings = true` 分支，
              // 才真正用上主题里设的 glassColor。
              useOwnLayer: true,
              // useOwnLayer: true 时必须**同时**给 settings（库的官方示例
              // 就是这么写的，见 glass_card.dart 的 Standalone Mode）：
              // 自建层不再向上继承，settings 为空就等于`LiquidGlassSettings()`
              // 的完全透明玻璃 —— 浅色主题下等于没有玻璃，描边自然看不见。
              //
              // 数值对齐 Dock 的库预设（thickness 30 / blur 3），两者质感统一。
              settings: AppGlass.of(context),
              // 刻意不传 settings：组件级 settings 是整体替换语义，会丢掉
              // 库的一整套光学预设。底纱色由 main.dart 的 `GlassThemeData`
              // 按 light/dark 部分覆盖（`GlassThemeSettings`），
              // 这里与 Dock、右侧按钮组自动保持同一套材质。
              child: GestureDetector(
                onTap: onGoToCurrentWeek,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        // 玻璃底纱本身是半透的，文字若用低对比语义色会显得
                        // 「发灰发透」（用户反馈「字体透明度有点大」）。
                        // 显式用 onSurface 提到最高对比。
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: canGoPrevious ? onPreviousWeek : null,
                          child: Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: canGoPrevious
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).disabledColor,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: AnimatedSize(
                            duration: animationDuration,
                            curve: appCurve,
                            child: Text(
                              isViewingVacation
                                  ? l10n.onVacation
                                  : l10n.currentWeek(visibleWeek),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    // 同上：onSurfaceVariant 在玻璃上偏淡，
                                    // 改用 onSurface 保证可读。
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: canGoNext ? onNextWeek : null,
                          child: Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: canGoNext
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).disabledColor,
                          ),
                        ),
                        const SizedBox(width: 3),
                        if (isNotStarted)
                          // 未开学：主标签正常显示周数，旁边以徽章标注「未开学」。
                          const _NotStartedBadge()
                        else if (isTodayOnVacation)
                          const _VacationBadge()
                        else
                          _WeekBadge(
                            isCurrentCalendarWeek: isCurrentCalendarWeek,
                            // 无放假页时学期过末 actualWeek 会超过 totalWeeks，
                            // clamp 避免徽章显示越界周数。
                            actualCurrentWeek: actualWeek.clamp(1, totalWeeks),
                            animationDuration: animationDuration,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              if (schedules.length > 1)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.swap_horiz, size: 20),
                  tooltip: l10n.switchSchedule,
                  // padding 6 + 20px 图标 = 32×32，与旁边 IconButton 的
                  // constraints 对齐（constraints 参数约束的是菜单不是按钮）。
                  padding: const EdgeInsets.all(6),
                  onSelected: (id) {
                    if (id == _kScheduleManagementMenuValue) {
                      onOpenScheduleManagement();
                    } else {
                      onSwitchSchedule(id);
                    }
                  },
                  itemBuilder: (context) => [
                    ...schedules.map(
                      (schedule) => PopupMenuItem<String>(
                        value: schedule.id,
                        child: Row(
                          children: [
                            if (schedule.id == currentScheduleId)
                              Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              )
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                schedule.semesterName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: _kScheduleManagementMenuValue,
                      child: Row(
                        children: [
                          // 缩进与上方课表项文字对齐（图标 20 + 间距 8）。
                          const SizedBox(width: 28),
                          Expanded(child: Text(l10n.scheduleManagement)),
                        ],
                      ),
                    ),
                  ],
                ),
              // 三个操作按钮成组：Material 3 下是普通图标按钮，液态玻璃下
              // 包裹进同一块玻璃容器，视觉上是一个整体。
              AdaptiveIconButtonGroup(
                // 图标 21 + spacing 10：比左侧时间框（titleSmall/bodySmall，
                // 约 14/12）**大一点点**，同时三个控件之间不挤
                // （用户反馈「3 个控件整体有点小了」+「太挤」）。
                iconSize: 21,
                spacing: 10,
                horizontalPadding: 9,
                children: [
                  AdaptiveIconAction(
                    icon: Icons.download_rounded,
                    onPressed: onImport,
                    tooltip: l10n.importSchedule,
                  ),
                  AdaptiveIconAction(
                    icon: Icons.share_rounded,
                    onPressed: onExport,
                    tooltip: l10n.exportSchedule,
                  ),
                  AdaptiveIconAction(
                    icon: Icons.add_circle_rounded,
                    onPressed: onAddCourse,
                    tooltip: l10n.addCourse,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekBadge extends StatelessWidget {
  final bool isCurrentCalendarWeek;
  final int actualCurrentWeek;
  final Duration animationDuration;

  const _WeekBadge({
    required this.isCurrentCalendarWeek,
    required this.actualCurrentWeek,
    required this.animationDuration,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isCurrent = isCurrentCalendarWeek;
    final text = isCurrent
        ? l10n.thisWeek
        : l10n.actualCurrentWeek(actualCurrentWeek);

    final textWidget = Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: isCurrent
            ? scheme.onPrimaryContainer
            : scheme.onSecondaryContainer,
        fontWeight: FontWeight.w600,
        fontSize: 9,
      ),
    );

    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isCurrent ? scheme.primaryContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppShapes.full),
      ),
      child: AnimatedSize(
        duration: animationDuration,
        curve: appCurve,
        child: textWidget,
      ),
    );
    return body;
  }
}

class _NotStartedBadge extends StatelessWidget {
  const _NotStartedBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppShapes.full),
      ),
      child: Text(
        l10n.notStarted,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _VacationBadge extends StatelessWidget {
  const _VacationBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppShapes.full),
      ),
      child: Text(
        l10n.vacationBadge,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onTertiaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}
