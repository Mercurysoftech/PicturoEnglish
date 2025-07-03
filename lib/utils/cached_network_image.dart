import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedNetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? borderRadius;
  final BoxFit fit;
  final double? height;
  final double? width;
  final Widget Function(BuildContext, String)? placeHolder;
  final  Widget Function(BuildContext, String, Object)? errorWidget;

  const CachedNetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
    this.errorWidget,
    this.placeHolder

  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius??0),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        height: height,
        width: width,
        placeholder:placeHolder?? (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: errorWidget??(context, url, error) => const Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      ),
    );
  }
}
