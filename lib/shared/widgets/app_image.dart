import 'dart:convert';
import 'package:flutter/material.dart';

import 'image_loaders/file_image_loader.dart';

/// A universal, web-safe image widget that seamlessly renders:
/// 1. Data URLs ([imageUrl] or [imagePath] starting with `data:image/`) via [Image.memory].
/// 2. Remote cloud URLs ([imageUrl]) via [Image.network].
/// 3. Local device file paths ([imagePath]) via platform-safe file loading on native platforms.
/// 4. A themed placeholder when no image exists or if the file/network fails.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    this.imageUrl,
    this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.inventory_2_outlined,
    this.placeholderIconSize = 28,
  });

  final String? imageUrl;
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;
  final double placeholderIconSize;

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        placeholderIcon,
        size: placeholderIconSize,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    final trimmedUrl = (imageUrl ?? '').trim();
    final trimmedPath = (imagePath ?? '').trim();
    final source = trimmedUrl.isNotEmpty ? trimmedUrl : trimmedPath;

    if (source.startsWith('data:')) {
      // 1. Data URL (Base64 transparent PNG / JPEG)
      try {
        final comma = source.indexOf(',');
        final b64 = comma != -1 ? source.substring(comma + 1) : source;
        final bytes = base64Decode(b64);
        content = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
        );
      } catch (_) {
        content = _buildPlaceholder(context);
      }
    } else if (trimmedUrl.isNotEmpty &&
        (trimmedUrl.startsWith('http://') ||
            trimmedUrl.startsWith('https://'))) {
      // 2. Remote Network Image
      content = Image.network(
        trimmedUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Fallback to local image path if network fails
          if (trimmedPath.isNotEmpty) {
            final localWidget = getPlatformFileImage(
              trimmedPath,
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (ctx) => _buildPlaceholder(ctx),
            );
            if (localWidget != null) return localWidget;
          }
          return _buildPlaceholder(context);
        },
      );
    } else if (trimmedPath.isNotEmpty) {
      // 2. Local File Image (safely handled on native, returns null on web)
      final localWidget = getPlatformFileImage(
        trimmedPath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (ctx) => _buildPlaceholder(ctx),
      );
      content = localWidget ?? _buildPlaceholder(context);
    } else {
      // 3. Fallback placeholder
      content = _buildPlaceholder(context);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }
}
