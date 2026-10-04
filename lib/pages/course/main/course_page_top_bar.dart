import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:bugaoshan/widgets/common/adaptive_widgets.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/models/course.dart';
import 'package:bugaoshan/providers/app_config_provider.dart';
import 'package:bugaoshan/theme_shape.dart';

/// 顶栏玻璃参数（时间框与右侧按钮组共用同一套）。
///
/// 之前时间框写死白色玻璃、按钮组跟随明暗，两者在深色下深浅不一（用户反馈
/// 「时间表的颜色和旁边 3 个控件的玻璃框颜色不是很搭配」）。
/// 这里统一成**跟随明暗**：暗色用近黑纱、亮色用白纱，
/// 都保持「薄玻璃只留高光」的观感，不给底色。
LiquidGlassSettings _topBarGlass(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return LiquidGlassSettings(
    thickness: 8,
    blur: 2,
    // 透明度与 Dock 栏看齐：Dock 暗色底纱是 0.42，这里同值；
    // 亮色 0.26 与 Dock 亮色一致。三者（Dock / 时间框 / 按钮组）
    // 必须用同一套数值，否则深色下会深浅不一（用户反馈）。
    glassColor: isDark
        ? const Color.fromRGBO(20, 20, 22, 0.24)
        : const Color.fromRGBO(255, 255, 255, 0.20),
    lightIntensity: isDark ? 0.40 : 0.55,
    ambientStrength: 0.10,
    fresnelStrength: 0.35,
    glowIntensity: 0,
    shadowElevation: 0,
    refractiveIndex: 1.3,
    saturation: 1.1,
    chromaticAberration: 0.012,
  );
}

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
              // 单独配settings：这是浮在背景图之上的薄玻璃层，
              // 自身不该有色，只留高光与折射（否则在浅色背景上是突兀色块）。
              // 圆角与右侧按钮组统一（都是 16），否则并排看描边不一致。
              shape: const LiquidRoundedRectangle(borderRadius: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              clipBehavior: Clip.antiAlias,
              settings: _topBarGlass(context),
              child: GestureDetector(
                onTap: onGoToCurrentWeek,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
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
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
                    size: 24,
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
