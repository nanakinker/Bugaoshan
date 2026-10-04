import 'package:flutter/material.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/providers/app_config_provider.dart';

/// 主题样式设置页：Material 3 / 液态玻璃。
///
/// 切换后立即生效并持久化。
///
/// 两种实现的分工：
/// - **Material 3**：导航条沿用系统原生观感，不做模糊；
/// - **液态玻璃**：导航条为半透明毛玻璃，背景内容可透出，
///   选中态是一枚在项目之间滑动的玻璃透镜。
///
/// 两者共用同一份导航项配置与无障碍语义，切换不影响功能。
class SetThemeStylePage extends StatelessWidget {
  const SetThemeStylePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appConfig = getIt<AppConfigProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.themeStyleSetting)),
      body: ValueListenableBuilder<bool>(
        valueListenable: appConfig.usePackageGlassDock,
        builder: (context, useLiquidGlass, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _StyleCard(
              selected: !useLiquidGlass,
              icon: Icons.dashboard_customize_outlined,
              title: l10n.themeStyleMaterial3,
              subtitle: l10n.themeStyleMaterial3Desc,
              onTap: () => appConfig.usePackageGlassDock.value = false,
            ),
            const SizedBox(height: 12),
            _StyleCard(
              selected: useLiquidGlass,
              icon: Icons.blur_on,
              title: l10n.themeStyleLiquidGlass,
              subtitle: l10n.themeStyleLiquidGlassDesc,
              onTap: () => appConfig.usePackageGlassDock.value = true,
            ),
            const SizedBox(height: 20),
            // 说明两种风格并存时的差异，便于用户预期。
            Text(
              l10n.themeStyleMaterial3Desc,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? scheme.primary : scheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selected
                            ? scheme.onPrimaryContainer.withValues(alpha: 0.8)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.check_circle, color: scheme.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
