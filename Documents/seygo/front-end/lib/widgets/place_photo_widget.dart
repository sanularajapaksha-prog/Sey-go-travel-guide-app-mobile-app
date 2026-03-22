import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/models/place.dart';
import '../data/services/api_service.dart';
import 'custom_image_widget.dart';

class PlacePhotoWidget extends StatefulWidget {
  const PlacePhotoWidget({
    super.key,
    this.place,
    this.googleUrl,
    this.fallbackImageUrl,
    this.width,
    this.height,
    this.fit,
    this.semanticLabel,
    this.useSadFaceFallback = false,
  });

  final Place? place;
  final String? googleUrl;
  /// Shown when Google photo resolution fails, before the sad-face/grey fallback.
  final String? fallbackImageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final String? semanticLabel;
  final bool useSadFaceFallback;

  @override
  State<PlacePhotoWidget> createState() => _PlacePhotoWidgetState();
}

class _PlacePhotoWidgetState extends State<PlacePhotoWidget> {
  Future<String?>? _resolvedFuture;
  bool _hasRetriedResolver = false;

  @override
  void initState() {
    super.initState();
    _resolvedFuture = _resolve();
  }

  @override
  void didUpdateWidget(covariant PlacePhotoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPlaceId = oldWidget.place?.id ?? '';
    final newPlaceId = widget.place?.id ?? '';
    if (oldPlaceId != newPlaceId || oldWidget.googleUrl != widget.googleUrl) {
      _hasRetriedResolver = false;
      _resolvedFuture = _resolve();
    }
  }

  Future<String?> _resolve() {
    final place = widget.place;
    if (place != null) {
      return ApiService.resolveBestPlaceImage(place);
    }
    final rawGoogleUrl = widget.googleUrl;
    return ApiService.resolvePhotoFromRawGoogleUrl(
      rawGoogleUrl ?? '',
      fallbackName: widget.place?.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolvedFuture,
      builder: (context, snapshot) {
        final resolvedUrl = snapshot.data;
        if (resolvedUrl == null || resolvedUrl.isEmpty) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              widget.place?.resolveBestAvailableImageUrl() == null) {
            return _loading();
          }
          return _fallback();
        }

        return CachedNetworkImage(
          imageUrl: resolvedUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit ?? BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (context, url) => _loading(),
          errorWidget: (context, url, error) {
            _retryWithGoogleResolver();
            return _hasRetriedResolver ? _loading() : _fallback();
          },
          imageBuilder: (context, imageProvider) => Image(
            image: imageProvider,
            width: widget.width,
            height: widget.height,
            fit: widget.fit ?? BoxFit.cover,
            semanticLabel: widget.semanticLabel,
          ),
        );
      },
    );
  }

  Widget _loading() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }

  void _retryWithGoogleResolver() {
    final place = widget.place;
    final googleUrl = place?.googleUrl ?? widget.googleUrl;
    if (_hasRetriedResolver || googleUrl == null || googleUrl.isEmpty) {
      return;
    }

    _hasRetriedResolver = true;
    _resolvedFuture = ApiService.resolvePhotoFromRawGoogleUrl(
      googleUrl,
      cacheKey: 'resolver:${place?.id ?? googleUrl}',
      placeId: place?.id,
      fallbackName: place?.name,
    );

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  Widget _fallback() {
    final fallbackUrl = widget.fallbackImageUrl;
    if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
      return CustomImageWidget(
        imageUrl: fallbackUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        semanticLabel: widget.semanticLabel,
      );
    }

    if (widget.useSadFaceFallback) {
      final fallbackSize = _safePlaceholderSize();
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: SvgPicture.asset(
            'assets/images/sad_face.svg',
            width: fallbackSize,
            height: fallbackSize,
            semanticsLabel: widget.semanticLabel,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey.shade400,
          size: _safePlaceholderSize(),
        ),
      ),
    );
  }

  double _safePlaceholderSize() {
    final widthValue = widget.width;
    final heightValue = widget.height;
    final base = (widthValue != null && widthValue.isFinite && widthValue > 0)
        ? widthValue
        : (heightValue != null && heightValue.isFinite && heightValue > 0)
            ? heightValue
            : 64.0;
    final size = base * 0.32;
    if (!size.isFinite || size <= 0) return 24.0;
    return size.clamp(24.0, 72.0);
  }
}
