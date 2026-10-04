import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:bugaoshan/models/background_crop.dart';
import 'package:bugaoshan/utils/app_log.dart';

/// 课程页背景图渲染组件：按 [crop] 裁剪参数把原图缩放/平移进容器，超出部分裁掉。
///
/// [crop] 为 null（或等于默认值）时走 `fit: BoxFit.cover` 分支，与旧版渲染
/// 完全一致，保证旧用户没有裁剪参数时背景显示不发生变化。
///
/// 像素尺寸经`ui.instantiateImageCodec` 降采样解码取得（不整图解码进内存），
/// 再用 [BackgroundCropParams.resolveLayout] 计算布局 —— 课程页与裁剪编辑器
/// 共用同一套渲染数学，保证预览与实际一致。图片渲染由 ResizeImage 限宽解码。
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
  Size? _imageSize;

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
      _imageSize = null;
      _resolveImageSize();
    }
  }

  /// 读取图片的像素尺寸，用于自定义裁剪分支的布局换算。
  ///
  /// 刻意**不**走 `ImageProvider.resolve`：那会把整张图解码进内存，一张
  /// 4000x3000 的照片约 48MB，在 release（AOT + Impeller，内存策略更紧）
  /// 下极易解码失败；一旦失败，`onError` 只会静默移除监听，`_imageSize`
  /// 永远为 null，背景图就永久空白（且不报任何错）。
  ///
  /// 改为用 `instantiateImageCodec` 配合 `targetWidth` 做**降采样解码**：
  /// 引擎只解出缩小后的位图，峰值内存降到几 MB，尺寸信息依然准确。
  /// 解码失败同样只记录日志 —— build() 已保证尺寸未知时照常显示。
  Future<void> _resolveImageSize() async {
    try {
      final bytes = await File(widget.path).readAsBytes();
      if (!mounted) return;
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: _targetDecodeWidth(),
      );
      final frame = await codec.getNextFrame();
      // 拿到的是降采样后的尺寸，按比例还原原始像素尺寸，
      // 否则裁剪换算会基于缩小后的图算错。
      final scale = _targetDecodeWidth() ?? frame.image.width;
      final ratio = scale > 0 ? frame.image.width / scale : 1.0;
      final size = Size(
        (frame.image.width / ratio).toDouble(),
        (frame.image.height / ratio).toDouble(),
      );
      frame.image.dispose();
      codec.dispose();
      if (!mounted) return;
      if (size != _imageSize) {
        setState(() => _imageSize = size);
        widget.onImageSize?.call(size);
      }
    } catch (e) {
      AppLog.w('BackgroundImageView', 'Failed to read image size: $e');
    }
  }

  /// 降采样解码的目标宽度：屏幕物理宽度的 2 倍，旋转屏幕留余量。
  int? _targetDecodeWidth() {
    final size = MediaQuery.maybeSizeOf(context);
    if (size == null || !size.isFinite || size.isEmpty) return null;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final w = size.width * (dpr <= 0 ? 1.0 : dpr) * 2;
    return w > 0 ? w.round() : null;
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
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
