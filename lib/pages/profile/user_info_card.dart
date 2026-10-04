import 'package:flutter/material.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/providers/user_info_provider.dart';
import 'package:bugaoshan/widgets/common/styled_card.dart';

class UserInfoCard extends StatelessWidget {
  const UserInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = getIt<UserInfoProvider>();
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) => _buildContent(context, provider),
    );
  }

  Widget _buildContent(BuildContext context, UserInfoProvider provider) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final primaryColor = theme.colorScheme.primary;

    // 未登录或尚未获取，不显示
    if (!provider.hasData && !provider.loading && !provider.error) {
      return const SizedBox.shrink();
    }

    Widget child;
    VoidCallback? onTap;

    if (provider.loading) {
      child = _buildLoadingContent(theme, localizations);
      onTap = null;
    } else if (provider.error) {
      child = _buildErrorContent(theme, localizations, primaryColor);
      onTap = provider.retry;
    } else {
      final labels = provider.labels;
      if (labels == null || labels.isEmpty) {
        return const SizedBox.shrink();
      }
      child = _buildLabelsContent(theme, primaryColor, localizations, labels);
      onTap = provider.retry;
    }

    return StyledCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      onTap: onTap,
      child: child,
    );
  }

  Widget _buildLoadingContent(ThemeData theme, AppLocalizations localizations) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            localizations.userInfoLoading,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(
    ThemeData theme,
    AppLocalizations localizations,
    Color primaryColor,
  ) {
    return Row(
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 20,
          color: theme.colorScheme.error,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            localizations.userInfoLoadFailed,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          localizations.userInfoRetry,
          style: theme.textTheme.bodySmall?.copyWith(color: primaryColor),
        ),
      ],
    );
  }

  Widget _buildLabelsContent(
    ThemeData theme,
    Color primaryColor,
    AppLocalizations localizations,
    List<Map<String, dynamic>> labels,
  ) {
    String localizeLabel(String apiName) {
      return switch (apiName) {
        '图书借阅量' => localizations.labelBookBorrowCount,
        '校园卡余额' => localizations.labelCampusCardBalance,
        '网费余额' => localizations.labelNetworkFeeBalance,
        _ => apiName,
      };
    }

    return Row(
      children: labels.map((label) {
        final apiName = label['name'] as String? ?? '';
        final name = localizeLabel(apiName);
        final value = label['value'];
        final valueStr = value is num ? value.toString() : value.toString();
        final isLast = label == labels.last;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: Column(
              children: [
                // 上下留白：整块外边距 14、标签下方再加 14，
                // 使「图书借阅量 / 校园卡余额 / 网费余额」这块**上下等宽**
                // （用户反馈：上边够宽了、下边还不够）。
                const SizedBox(height: 14),
                Text(
                  valueStr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                // 与上方等宽，使这块信息区上下留白一致
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
