import 'dart:io';
import 'package:bugaoshan/utils/app_log.dart';

import 'package:flutter/material.dart';
import 'package:bugaoshan/models/background_crop.dart';
import 'package:bugaoshan/widgets/common/image_error_log.dart';

/// 课程页背景图渲染组件：按 [crop] 裁剪参数把原图缩放/平移进容器，超出部分裁掉。
///
/// [crop] 为 null（或等于默认值）时走 `fit: BoxFit.cover` 分支，与旧版渲染
/// 完全一致，保证旧用户没有裁剪参数时背景显示不发生变化。
///
/// 像素尺寸通过监听同一个 `FileImage` 的 [ImageStreamListener] 取得 ——
/// 与 Image widget 内部的解析**共享 ImageCache**，不产生二次解码，
/// 也不会把原图整张解码进内存。拿到尺寸后用
/// [BackgroundCropParams.resolveLayout] 计算布局，课程页与裁剪编辑器共用
/// 同一套渲染数学，保证预览与实际一致。
class BackgroundImageView extends StatefulWidget {
  const BackgroundImageView({
    super.key,
    required this.path,
    required this.overlayOpacity,
    this.crop,
    this.onImageSize,
  });

  final String path;

  /// 白色叠加不透明度（对应原 Image color + BlendMode.modulate 行为）。
  final double overlayOpacity;

  final BackgroundCropParams? crop;

  /// 首帧解码后的图片像素尺寸回调（裁剪编辑器做手势换算用）。
  final ValueChanged<Size>? onImageSize;

  @override
  State<BackgroundImageView> createState() => _BackgroundImageViewState();
}

class _BackgroundImageViewState extends State<BackgroundImageView> {
  static const String _tag = 'BackgroundImageViewState';

  static const Duration _fadeInDuration = Duration(milliseconds: 300);

  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _imageSize;
  final _imageErrors = ImageErrorReporter();

  bool get _hasCustomCrop => widget.crop != null && !widget.crop!.isCover;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  @override
  void didUpdateWidget(covariant BackgroundImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _imageErrors.reset();
      _imageSize = null;
      _resolveImageSize();
    }
  }

  /// 监听同一个 FileImage 缓存条目拿到图片尺寸；Image widget 内部的解析
  /// 与这里共享 ImageCache，不产生二次解码。
  void _resolveImageSize() {
    _removeListener();
    final path = widget.path;
    try {
      final stream = FileImage(
        File(widget.path),
      ).resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener(
        (info, _) {
          if (!mounted) return;
          final size = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
          if (size != _imageSize) {
            setState(() => _imageSize = size);
            widget.onImageSize?.call(size);
          }
        },
        onError: (error, stackTrace) {
          _imageErrors.report(
            path,
            _tag,
            '背景图片解码失败',
            error: error,
            stackTrace: stackTrace,
          );
          // 解码失败保持空显示，与 Image.errorBuilder 行为一致。
          _removeListener();
        },
      );
      _stream = stream;
      _listener = listener;
      stream.addListener(listener);
    } catch (logError, logStackTrace) {
      AppLog.e(
        _tag,
        '_resolveImageSize 失败',
        error: logError,
        stackTrace: logStackTrace,
      );
      // 文件不存在等同步异常：保持空显示。
    }
  }

  void _removeListener() {
    try {
      _stream?.removeListener(_listener!);
    } catch (logError, logStackTrace) {
      AppLog.e(
        _tag,
        '_removeListener 失败',
        error: logError,
        stackTrace: logStackTrace,
      );
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = _imageSize;
        final ready = imageSize != null && !imageSize.isEmpty;
        // 绝不用「解码成功才显示」作为可见性条件：一旦尺寸读取失败，
        // 整张图就永久隐形，且 onError 静默处理、无任何报错（这正是之前
        // release 下背景图空白的直接放大器）。尺寸未知时照常渲染，
        // 走 BoxFit.cover 默认外观。
        return ready && _hasCustomCrop
            ? _buildCroppedImage(imageSize, constraints.biggest)
            : _buildImage(fit: BoxFit.cover);
      },
    );
  }

  /// 按裁剪参数摆放缩放后的图片；Stack 默认 hardEdge 裁剪超出部分。
  Widget _buildCroppedImage(Size imageSize, Size container) {
    final layout = BackgroundCropParams.resolveLayout(
      imageWidth: imageSize.width,
      imageHeight: imageSize.height,
      containerWidth: container.width,
      containerHeight: container.height,
      params: widget.crop!,
    );
    return ClipRect(
      child: Stack(
        children: [
          Positioned(
            left: layout.left,
            top: layout.top,
            width: layout.scaledWidth,
            height: layout.scaledHeight,
            child: _buildImage(fit: BoxFit.fill),
          ),
        ],
      ),
    );
  }

  Widget _buildImage({required BoxFit fit}) {
    // 用 ResizeImage 限制解码目标宽度（注意：Image 部件本身没有 cacheWidth
    // 参数，只有 ResizeImage / FileImage.resize() 这条路）。
    //
    // 背景图只是铺在屏幕后面（还叠了不透明白色遮罩），按原始分辨率解码一张
    // 4000x3000 的照片要占约 48MB 位图，在 release（AOT + Impeller，内存策略
    // 更紧）下容易解码失败；而这条路径失败时 ImageStreamListener.onError
    // 只会静默移除监听，背景图就永久空白。限制解码尺寸后峰值内存降到几 MB，
    // 肉眼无差别但稳定得多。
    //
    // 取屏幕宽度的 2 倍（× devicePixelRatio）作为解码宽度，旋转屏幕留余量。
    final decodeWidth = _targetDecodeWidth();

    var provider = FileImage(File(widget.path)) as ImageProvider;
    if (decodeWidth != null && decodeWidth > 0) {
      provider = ResizeImage(
        provider,
        width: decodeWidth,
        policy: ResizeImagePolicy.fit,
      );
    }

    return Image(
      image: provider,
      fit: fit,
      // 图片渲染由上面的 ResizeImage 限宽解码负责，这里只管叠加与混色。
      color: Colors.white.withAlpha(
        (widget.overlayOpacity.clamp(0.0, 1.0) * 255).round(),
      ),
      colorBlendMode: BlendMode.modulate,
      errorBuilder: (_, error, stackTrace) {
        _imageErrors.report(
          widget.path,
          _tag,
          '背景图片渲染失败',
          error: error,
          stackTrace: stackTrace,
        );
        return const SizedBox.shrink();
      },
    );
  }
}
