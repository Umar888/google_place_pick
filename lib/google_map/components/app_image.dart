import 'package:extended_image/extended_image.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';


class AppImage extends StatelessWidget {
  const AppImage({
    Key? key,
    this.link,
    this.height,
    this.width,
    this.loadingRadius,
    this.cache,
    this.placeholder,
    this.errorPlaceHolder,
    this.shape,
    this.fit,
  }) : super(key: key);
  final String? link;
  final double? width;
  final double? height;
  final double? loadingRadius;
  final Widget? placeholder;
  final BoxFit? fit;
  final bool? cache;
  final Widget? errorPlaceHolder;
  final BoxShape? shape;

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      link ?? '',
      width: width,
      height: height,
      cacheHeight: height?.round(),
      cacheWidth: width?.round(),
      shape: shape,
      enableMemoryCache: cache ?? false,
      fit: fit ?? BoxFit.cover,
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return placeholder??FadeShimmer(
              height: 300,
              width: double.infinity,
              radius: 5,

              highlightColor: Colors.red.withOpacity(0.5),
              baseColor: Colors.grey.shade100,
            );

          case LoadState.completed:
            return state.completedWidget;

          case LoadState.failed:
            return  Container(
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.all(5),
              decoration:  BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.red.withOpacity(0.4),
              ),
              child: const Center(child: Icon(Icons.error_outline_outlined)),
            );

          default:
            return Center(
                child:
                    // errorPlaceHolder ?? Icon(Icons.image, color: Colors.grey));
          Text("like re $link"));
        }
      },
    );
  }
}
