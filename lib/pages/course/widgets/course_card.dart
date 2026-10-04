import 'package:flutter/material.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/models/course.dart';
import 'package:bugaoshan/providers/app_config_provider.dart';
import 'package:bugaoshan/theme_shape.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final ScheduleConfig config;
  final int displayWeek;
  final bool showAllWeeks;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CourseCard({
    super.key,
    required this.course,
    required this.config,
    required this.displayWeek,
    this.showAllWeeks = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final appConfig = getIt<AppConfigProvider>();
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: Listenable.merge([
        appConfig.colorOpacity,
        appConfig.courseCardFontSize,
        appConfig.showLocation,
        appConfig.showTeacherName,
        appConfig.showCourseWeeks,
      ]),
      builder: (context, _) {
        final isActive = showAllWeeks || course.isActiveInWeek(displayWeek);
        final color = isActive
            ? course.color.withValues(alpha: appConfig.colorOpacity.value)
            : _greyscale(course.color).withValues(alpha: 0.12);
        final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
        final effectiveBg = Color.alphaBlend(color, scaffoldBg);
        final textColor = effectiveBg.computeLuminance() > 0.45
            ? Colors.black87
            : Colors.white;
        final fontSize = appConfig.courseCardFontSize.value;
        final smallFontSize = (fontSize * 0.85).clamp(8.0, 16.0);
        final details =
            <({String text, int preferredMaxLines, int renderMaxLines})>[
              if (appConfig.showLocation.value && course.location.isNotEmpty)
                (
                  text: course.location,
                  preferredMaxLines: 1,
                  renderMaxLines: 4,
                ),
              if (appConfig.showTeacherName.value && course.teacher.isNotEmpty)
                (text: course.teacher, preferredMaxLines: 1, renderMaxLines: 2),
              if (appConfig.showCourseWeeks.value)
                (
                  text: course.formatWeeks(l10n),
                  preferredMaxLines: 1,
                  renderMaxLines: 4,
                ),
            ];

        return GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              final detailLineBudget = switch (height) {
                < 56 => 0,
                < 100 => 3,
                _ => 5,
              };
              final visibleDetails =
                  <
                    ({String text, int preferredMaxLines, int renderMaxLines})
                  >[];
              var usedDetailLines = 0;
              for (final detail in details) {
                final nextUsedLines =
                    usedDetailLines + detail.preferredMaxLines;
                if (nextUsedLines > detailLineBudget) {
                  continue;
                }
                visibleDetails.add(detail);
                usedDetailLines = nextUsedLines;
              }
              final titleMaxLines = 6;

              return ClipRRect(
                borderRadius: BorderRadius.circular(AppShapes.small),
                child: Container(
                  decoration: BoxDecoration(
                    // 有色玻璃：保留课程色（保证可扫读）但明显通透。
                    // 透明度 0.62 —— 背景图/课表网格能透过来，
                    // 高光与内阴影提供厚度，呈现为「一块有颜色的玻璃」。
                    // 不用 0.3 以下：那样文字会与背景混在一起反而更难读。
                    color: color.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(AppShapes.small),
                    border: isActive
                        ? null
                        : Border.all(
                            color: textColor.withAlpha(50),
                            width: 0.5,
                          ),
                    // 玻璃质感：**底色保持不透明**。课表需要快速扫读颜色
                    // 判断课程归属，若改成半透明会显著降低可读性。
                    // 这里只加「顶部高光 + 底部内阴影」制造厚度，
                    // 让色块从平面贴纸变成有体积的玻璃块。
                    boxShadow: [
                      // 顶部高光：模拟玻璃上沿受光
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.40),
                        blurRadius: 7,
                        offset: const Offset(0, -2),
                        spreadRadius: -2,
                      ),
                      // 底部内阴影：给出厚度
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: SizedBox.expand(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isActive
                                  ? course.name
                                  : '${l10n.notThisWeek} ${course.name}',
                              maxLines: titleMaxLines,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: fontSize,
                                    color: textColor,
                                    height: 1.1,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (visibleDetails.isNotEmpty)
                              const SizedBox(height: 2),
                            ...visibleDetails.map(
                              (detail) => _buildIconText(
                                detail.text,
                                smallFontSize,
                                textColor,
                                maxLines: detail.renderMaxLines,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildIconText(
    String text,
    double fontSize,
    Color color, {
    int maxLines = 1,
  }) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: fontSize,
            color: color.withAlpha(230),
            height: 1.1,
          ),
        ),
      ),
    );
  }

  static Color _greyscale(Color color) {
    final grey = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b).clamp(
      0.0,
      1.0,
    );
    return Color.from(green: grey, blue: grey, red: grey, alpha: 1.0);
  }
}
