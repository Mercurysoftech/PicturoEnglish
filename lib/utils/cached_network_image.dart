import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedNetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? borderRadius;
  final BoxFit fit;
  final double? height;
  final double? width;
  final Widget Function(BuildContext, String)? placeHolder;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final Alignment alignment;

  const CachedNetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
    this.errorWidget,
    this.placeHolder,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 0),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    // Check if it's a local file path (starts with /)
    if (imageUrl.startsWith('/')) {
      final file = File(imageUrl);
      return Image.file(
        file,
        height: height,
        width: width,
        fit: fit,
        alignment: alignment,
        // INSTANT display - no loading indicator!
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          // If loaded synchronously (from cache), show immediately
          if (wasSynchronouslyLoaded) {
            return child;
          }
          // Otherwise show with fade
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget(context, imageUrl, error);
        },
      );
    }

    // Network image with caching
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      alignment: alignment,
      height: height,
      width: width,
      // Optimize memory cache
      memCacheHeight: height != null ? (height! * 2).toInt() : null,
      memCacheWidth: width != null ? (width! * 2).toInt() : null,
      // INSTANT display for cached images - no fade!
      fadeInDuration: const Duration(milliseconds: 0),
      fadeOutDuration: const Duration(milliseconds: 0),
      // Placeholder only shown when truly downloading
      placeholder: placeHolder ??
          (context, url) => _buildPlaceholder(context),
      // Error widget
      errorWidget: errorWidget ??
          (context, url, error) => _buildErrorWidget(context, url, error),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    // Shimmer effect for better UX
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius ?? 0),
      ),
      child: Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String url, Object error) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius ?? 0),
      ),
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}