import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/models/course.dart';
import 'package:bugaoshan/pages/course/widgets/grid_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 表头日期用紧凑的 `9/7` 而不是 `9月7日`。
///
/// 低分辨率屏上 5~7 天平摊后每列只剩 45~60px，中文格式会被 FittedBox 压成一团；
/// 详情面板（special_day_sheet）等宽空间仍保留 `9月7日` 的可读格式。
void main() {
  testWidgets('GridHeaderRow 日期为「月/日」数字格式', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: GridHeaderRow(
              config: ScheduleConfig(
                semesterStartDate: DateTime(2026, 9, 7), // 周一
                semesterName: '2026-2027-1',
              ),
              displayWeek: 1,
              hasBackground: false,
              showWeekend: false,
              sectionWidth: 24,
            ),
          ),
        ),
      ),
    );

    // 周一~周五 = 9/7 ~ 9/11（教学周以周日为首日成行）。
    for (final label in ['9/7', '9/8', '9/9', '9/10', '9/11']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.textContaining('月'), findsNothing);
    expect(find.textContaining('年'), findsNothing);
  });
}
