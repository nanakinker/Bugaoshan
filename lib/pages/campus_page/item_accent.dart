import 'package:bugaoshan/utils/constants.dart';
import 'package:flutter/material.dart';

/// 校园页功能入口的强调色。
///
/// 每个入口按 dock id 绑定一个固定的强调色，让页面告别清一色的
/// primaryContainer，视觉上更有层次、更易辨识。颜色取自一组兼顾
/// 明暗主题的调和色板。
Color campusItemAccent(String id) => switch (id) {
  dockIdGrades => const Color(0xFF5B8DEF), // 蓝
  dockIdCcyl => const Color(0xFF8B7CF6), // 紫
  dockIdPlanCompletion => const Color(0xFF3FA796), // 青绿
  dockIdFitnessTest => const Color(0xFFF27059), // 橙红
  dockIdExamPlan => const Color(0xFFE86A92), // 品红
  dockIdTrainProgram => const Color(0xFF7C9A4E), // 橄榄绿
  dockIdClassScheduleInquiry => const Color(0xFF4FA3C4), // 天青
  dockIdClassroom => const Color(0xFF6C8CD5), // 靛蓝
  dockIdNetworkDevice => const Color(0xFF5AB8A8), // 湖绿
  dockIdBalanceQuery => const Color(0xFFE8A33D), // 琥珀
  dockIdAcademicCalendar => const Color(0xFFD97757), // 赭橙
  dockIdZysc => const Color(0xFF9A7FD1), // 淡紫
  dockIdLeave => const Color(0xFF6488C4), // 灰蓝
  dockIdGraduateGrades => const Color(0xFF4A7BA6), // 钢蓝
  dockIdGraduateTrainPlan => const Color(0xFF6B5CA5), // 深紫
  dockIdNotice => const Color(0xFFE05D5D), // 朱红
  dockIdDownloadedAttachments => const Color(0xFF8F9BA8), // 蓝灰
  _ => const Color(0xFF5B8DEF),
};

/// 强调色对应的图标容器底色。
///
/// 液态玻璃风格：底色仍带强调色（保留功能类别的可扫读性），
/// 但透明度大幅降低并改为**上下渐变**——顶部略实、底部更透，
/// 模拟玻璃受光面，取代原先「一块均匀实色」的观感。
///
/// 强调色本身的信息量不能丢，所以不改成中性玻璃，只降不透明度 + 加渐变。
Color campusItemAccentContainer(Color accent, Brightness brightness) {
  return accent.withValues(alpha: brightness == Brightness.dark ? 0.16 : 0.10);
}

/// 图标容器的玻璃修饰：顶部高光边 + 底部内阴影。
///
/// 纯色块看起来是「贴纸」，加上高光与内阴影后才有厚度感。
List<BoxShadow> campusItemAccentShadows(Color accent, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return [
    // 顶部高光：模拟玻璃上沿受光
    BoxShadow(
      color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.55),
      blurRadius: 6,
      offset: const Offset(0, -1),
      spreadRadius: -3,
    ),
    // 底部内阴影：给出体积
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
      blurRadius: 5,
      offset: const Offset(0, 2),
      spreadRadius: -3,
    ),
  ];
}
