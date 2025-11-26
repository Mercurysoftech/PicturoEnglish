import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';

class PermanentCacheManager extends CacheManager {
  static const key = 'permanentCache';
  
  static PermanentCacheManager? _instance;
  
  factory PermanentCacheManager() {
    _instance ??= PermanentCacheManager._();
    return _instance!;
  }
  
  PermanentCacheManager._() : super(Config(
    key,
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 1000,
    repo: JsonCacheInfoRepository(databaseName: key),
    fileService: HttpFileService(),
  ));
}

class DebugCachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const DebugCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
  });

  @override
  State<DebugCachedImage> createState() => _DebugCachedImageState();
}

class _DebugCachedImageState extends State<DebugCachedImage> {
  @override
  Widget build(BuildContext context) {
    print('DebugCachedImage - URL: ${widget.imageUrl}');
    
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheManager: PermanentCacheManager(),
      progressIndicatorBuilder: (context, url, progress) {
        print('Image loading progress: $progress');
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            color: Colors.white,
            height: double.infinity,
            width: double.infinity,
          ),
        );
      },
      errorWidget: (context, url, error) {
        print('Image loading ERROR: $error');
        print('URL that failed: $url');
        print('Error type: ${error.runtimeType}');
        return Container(
          color: Colors.red[100],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 40),
              SizedBox(height: 8),
              Text('Failed to load', style: TextStyle(fontSize: 12)),
              Text('URL: ${widget.imageUrl}', style: TextStyle(fontSize: 10)),
            ],
          ),
        );
      },
    );
  }
}