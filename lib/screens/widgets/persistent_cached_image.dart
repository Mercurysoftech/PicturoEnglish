import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:picturo_app/services/permanent_cache_manager.dart';
import 'package:shimmer/shimmer.dart';
import 'package:path/path.dart' as p;

class PersistentCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BaseCacheManager? cacheManager;

  const PersistentCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.cacheManager,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: cacheManager ?? PermanentCacheManager(),
      cacheKey: _getCacheKey(imageUrl),
      maxWidthDiskCache: 1080, 
      maxHeightDiskCache: 1080,
      memCacheWidth: 300,
      memCacheHeight: 300,
      placeholder: (context, url) => placeholder ?? _buildShimmer(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
    );
  }

  String _getCacheKey(String url) {
    final uri = Uri.parse(url);
    return p.basename(uri.path);
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
        height: double.infinity,
        width: double.infinity,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.error_outline, color: Colors.grey[400], size: 40),
    );
  }
}