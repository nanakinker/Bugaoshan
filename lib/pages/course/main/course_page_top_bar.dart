import 'package:flutter/material.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/models/course.dart';
import 'package:bugaoshan/providers/app_config_provider.dart';
import 'package:bugaoshan/theme_shape.dart';
import 'package:bugaoshan/widgets/common/adaptive_widgets.dart';
import 'package:bugaoshan/widgets/common/app_glass.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 切换课表菜单里「管理课表」项的哨兵值，不会与课表 id 冲突。
const _kScheduleManagementMenuValue = '__management__';

/// 顶栏操作按钮的边长（含点击区）。
///
/// IconButton 在 M3 下默认被 `MaterialTapTargetSize.padded` 撑到 48×48，`constraints`
/// 参数拦不住它 —— 4 个按钮要吃 192px，窄屏上会把「第 N 周」挤成「第 …」，320px 下
/// 甚至直接 RenderFlex 溢出。这里显式固定为紧凑尺寸（图标仍居中，热区 40×40）。
const double _kActionSize = 40;

/// 单行布局所需的最小宽度（会按文字缩放放大）。
///
/// 低于该宽度时改为「日期 + 操作按钮」一行、「周次导航」独占一行，
/// 保证「第 N 周」永远拿得到整行宽度，不再被省略号截断。
const double _kSingleRowMinWidth = 360;

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
    // 大文字缩放时同样需要更多宽度：阈值随缩放放大，避免「第 N 周」被压缩。
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    final weekNav = _buildWeekNav(context, l10n);
    final actions = _buildActions(context, l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 日期长度跟着宽度走：窄屏省掉年份只留「10/18」，
          // 宽屏保留「2026/10/18」。
          final narrow =
              constraints.maxWidth < _kSingleRowMinWidth * textScale;
          final date = _buildDate(context, l10n, compact: narrow);

          // 时间 / 周次区整块玻璃（本分支材质）。
          //
          // 与上游的差异：上游在窄屏把「周次导航」拆到单独一行、露在玻璃之外；
          // 这里改为**日期与周次始终同处一块玻璃**，纵向叠放。玻璃是本分支的
          // 核心视觉，拆行会让周次脱离玻璃面；纵向叠放所需宽度取两者较宽者
          // （周次行约 144dp），加上动作组在 320dp 窄屏上仍放得下。
          final timeBox = GlassCard(
            // 圆角与右侧按钮组统一（都是 16），否则并排看描边不一致。
            shape: const LiquidRoundedRectangle(borderRadius: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            clipBehavior: Clip.antiAlias,
            // premium：GlassCard 默认 standard，没有色散与真实折射。
            // 顶栏属于官方指定的 hero surface（导航/控件层），用 premium
            // 才与右侧按钮组、底部 Dock 的玻璃质感一致。
            quality: GlassQuality.premium,
            // useOwnLayer: true —— 自建折射层，切断向祖先 glass 层的
            // settings 继承；同时**必须**显式给 settings，否则等于
            // LiquidGlassSettings() 的完全透明玻璃（浅色下看不见描边）。
            useOwnLayer: true,
            settings: AppGlass.of(context),
            child: GestureDetector(
              onTap: onGoToCurrentWeek,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [date, const SizedBox(height: 1), weekNav],
              ),
            ),
          );

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(child: timeBox),
              actions,
            ],
          );
        },
      ),
    );
  }


  /// 左上角日期：窄屏 `10/18`，宽屏 `2026/10/18`（年份不值得占用窄屏那点宽度）。
  Widget _buildDate(
    BuildContext context,
    AppLocalizations l10n, {
    required bool compact,
  }) {
    final now = DateTime.now();
    return Text(
      compact
          ? l10n.dateMonthDayCompact(now.month, now.day)
          : l10n.dateYearMonthDay(now.year, now.month, now.day),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  /// 「‹ 第 N 周 ›」+ 本周/未开学/放假徽章。
  Widget _buildWeekNav(BuildContext context, AppLocalizations l10n) {
    final isCurrentCalendarWeek = visibleWeek == actualWeek;
    return Row(
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                // 玻璃底纱是半透的，onSurfaceVariant 在玻璃上偏淡
                // （用户反馈「字体透明度有点大」），改用 onSurface。
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
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
    );
  }

  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
    // 显式收掉 IconButton 默认的 48×48 padded 触控尺寸（见 _kActionSize 注释）。
    // style 的优先级高于 IconButton/PopupMenuButton 自身的同名参数。
    final actionStyle = IconButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      fixedSize: const Size.square(_kActionSize),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (schedules.length > 1)
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz, size: 20),
            tooltip: l10n.switchSchedule,
            style: actionStyle,
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
          // 图标 24 + spacing 12：比左侧时间框明显大一号，玻璃容器也随之
          // 更宽，在顶栏上有足够的视觉重量（用户反馈「再调大一点」）。
          iconSize: 24,
          spacing: 12,
          horizontalPadding: 11,
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
