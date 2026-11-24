import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';

class SmartProductImage extends StatelessWidget {
  const SmartProductImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.fallbackIcon,
    this.borderRadius = 12,
    this.customBorderRadius,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final IconData fallbackIcon;
  final double borderRadius;
  final BorderRadiusGeometry? customBorderRadius;
  final BoxFit fit;

  // In-memory cache to prevent decoding base64 on every state change / rebuild,
  // which causes image blinking or flickering.
  static final Map<String, Uint8List> _base64Cache = <String, Uint8List>{};

  BorderRadiusGeometry get _resolvedBorderRadius =>
      customBorderRadius ?? BorderRadius.circular(borderRadius);

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      final clean = imageUrl!.trim();
      if (clean.startsWith('data:image/') || clean.contains(';base64,')) {
        try {
          var bytes = _base64Cache[clean];
          if (bytes == null) {
            final commaIndex = clean.indexOf(',');
            final base64Str = commaIndex != -1 ? clean.substring(commaIndex + 1) : clean;
            bytes = base64Decode(base64Str);
            if (_base64Cache.length > 80) {
              _base64Cache.clear();
            }
            _base64Cache[clean] = bytes;
          }
          return _buildMemoryImage(bytes);
        } catch (_) {}
      } else if (clean.startsWith('http://') || clean.startsWith('https://')) {
        return _buildNetworkImage(clean);
      } else if (clean.startsWith('/')) {
        return _buildNetworkImage(ApiConstants.fullUrl(clean));
      } else if (clean.length > 80 && !clean.contains(' ')) {
        // Raw base64 string
        try {
          var bytes = _base64Cache[clean];
          if (bytes == null) {
            bytes = base64Decode(clean);
            if (_base64Cache.length > 80) {
              _base64Cache.clear();
            }
            _base64Cache[clean] = bytes;
          }
          return _buildMemoryImage(bytes);
        } catch (_) {}
      }
    }

    return _buildFallback();
  }

  Widget _buildMemoryImage(Uint8List bytes) {
    return ClipRRect(
      borderRadius: _resolvedBorderRadius,
      child: RepaintBoundary(
        child: Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => _buildFallback(),
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String url) {
    return ClipRRect(
      borderRadius: _resolvedBorderRadius,
      child: RepaintBoundary(
        child: CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: fit,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (_, __) => _buildFallback(),
          errorWidget: (_, __, ___) => _buildFallback(),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    final iconSize = (width.isFinite && width > 0)
        ? (width * 0.38).clamp(20.0, 38.0)
        : (height.isFinite && height > 0)
            ? (height * 0.45).clamp(20.0, 38.0)
            : 38.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withValues(alpha: 0.13),
        borderRadius: _resolvedBorderRadius,
      ),
      child: Icon(
        fallbackIcon,
        size: iconSize,
        color: AppColors.primaryGoldDark,
      ),
    );
  }
}
