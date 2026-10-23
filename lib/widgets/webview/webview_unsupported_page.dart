import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/widgets/route/router_utils.dart';
import 'package:flutter/material.dart';
import 'package:os_type/os_type.dart';

/// 当前平台是否没有可用的原生 WebView 后端。
///
/// Linux 侧的 `flutter_inappwebview` 只解析到纯 Dart 占位实现（无任何原生代码），
/// 任何 `InAppWebView` 都会在运行时抛 `UnimplementedError`。
bool get hasNoWebViewBackend => OS.isLinux;

/// Placeholder page shown when the current platform cannot host a WebView.
class WebViewUnsupportedPage extends StatelessWidget {
  const WebViewUnsupportedPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n?.close,
          onPressed: () {
            if (logicRootContext.mounted) {
              Navigator.of(logicRootContext).pop();
            }
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.browser_not_supported_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.featureNotSupported ?? '当前平台不支持此功能',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
