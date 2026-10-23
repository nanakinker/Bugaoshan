import 'dart:async';

import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/models/academic_calendar.dart';
import 'package:bugaoshan/pages/campus/academic_calendar/academic_calendar_page.dart';
import 'package:bugaoshan/widgets/common/adaptive_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  testWidgets('ignores list and interactive responses after disposal', (
    tester,
  ) async {
    final listResponse = Completer<http.Response>();
    final interactiveResponse = Completer<AcademicCalendarData>();
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      _testApp(
        AcademicCalendarPage(
          httpGet: (_) => listResponse.future,
          interactiveDataLoader: () => interactiveResponse.future,
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(_testApp(const SizedBox.shrink()));
    listResponse.complete(
      http.Response('<a href="info/1101/123.htm">2025-2026</a>', 200),
    );
    interactiveResponse.complete(AcademicCalendarData(semesters: const []));
    await tester.pump();

    expect(errors, isEmpty);
  });

  testWidgets('keeps the selected detail when an older response arrives last', (
    tester,
  ) async {
    final firstDetail = Completer<http.Response>();
    final secondDetail = Completer<http.Response>();
    final requestedPaths = <String>[];

    Future<http.Response> httpGet(Uri uri) {
      requestedPaths.add(uri.path);
      if (uri.path.endsWith('/cdxl.htm')) {
        return Future.value(
          http.Response(
            '<a href="info/1101/100.htm">2024-2025</a>'
            '<a href="info/1101/200.htm">2025-2026</a>',
            200,
          ),
        );
      }
      if (uri.path.endsWith('/100.htm')) return firstDetail.future;
      if (uri.path.endsWith('/200.htm')) return secondDetail.future;
      throw StateError('Unexpected request: $uri');
    }

    await tester.pumpWidget(
      _testApp(
        AcademicCalendarPage(
          httpGet: httpGet,
          interactiveDataLoader: () async =>
              AcademicCalendarData(semesters: const []),
          officialImageBuilder: (_, url) => Text(url, key: ValueKey(url)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(requestedPaths, ['/cdxl.htm', '/info/1101/100.htm']);

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    tabBar.controller!.animateTo(1, duration: Duration.zero);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final dropdownFinder = find.byWidgetPredicate(
      (widget) => widget is AdaptiveGlassDropdown,
      skipOffstage: false,
    );
    expect(dropdownFinder, findsOneWidget);
    // 本分支已换成泛型组件 AdaptiveGlassDropdown<T>，测试里不再写死 T：
    // 若强转成 <dynamic>，其 onChanged 为 ValueChanged<T?>?，函数参数逆变
    // 会导致运行期 "_TypeError: (CalendarEntry?) => void is not a subtype
    // of ((dynamic) => void)?"。用 dynamic 取字段即可。
    // tester.widget<T> 的 T 必须 extends Widget，不能直接写 dynamic；
    // 先按 Widget 取出再赋给 dynamic 变量，靠动态派发读 items/onChanged，
    // 绕开泛型逆变（否则 ValueChanged<CalendarEntry?> 与 ValueChanged<dynamic>
    // 不兼容，运行期抛 _TypeError）。
    final dynamic dropdown = tester.widget<Widget>(dropdownFinder);
    final secondEntry =
        ((dropdown.items as List).last as DropdownMenuItem).value;
    // 不做显式 cast：函数参数逆变会让 `as void Function(dynamic)?` 本身
    // 抛 TypeError。dropdown 是 dynamic，直接动态调用即可（只校验实参类型）。
    dropdown.onChanged!(secondEntry);
    await tester.pump();

    const secondUrl = 'https://jwc.scu.edu.cn/__local/second.png';
    secondDetail.complete(
      http.Response('<img src="/__local/second.png">', 200),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey(secondUrl), skipOffstage: false),
      findsOneWidget,
    );

    const firstUrl = 'https://jwc.scu.edu.cn/__local/first.png';
    firstDetail.complete(http.Response('<img src="/__local/first.png">', 200));
    await tester.pump();

    expect(
      find.byKey(const ValueKey(secondUrl), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(firstUrl), skipOffstage: false),
      findsNothing,
    );
  });
}

Widget _testApp(Widget home) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
