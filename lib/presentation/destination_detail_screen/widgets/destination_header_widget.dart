import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Hero image section with swipeable photo gallery and dot indicators
class DestinationHeaderWidget extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final bool isFavorite;

  const DestinationHeaderWidget({
    super.key,
    required this.images,
    required this.onBack,
    required this.onShare,
    required this.onFavorite,
    this.isFavorite = false,
  });

  @override
  State<DestinationHeaderWidget> createState() =>
      _DestinationHeaderWidgetState();
}

class _DestinationHeaderWidgetState extends State<DestinationHeaderWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 50.h,
      child: Stack(
        children: [
          // Image carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onLongPress: () {
                  _showFullScreenGallery(context, index);
                },
                child: CustomImageWidget(
                  imageUrl: widget.images[index]["url"] as String,
                  width: double.infinity,
                  height: 50.h,
                  fit: BoxFit.cover,
                  semanticLabel:
                  widget.images[index]["semanticLabel"] as String,
                ),
              );
            },
          ),

          // Gradient overlay for better text visibility
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 20.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top action buttons
          Positioned(
            top: 6.h,
            left: 4.w,
            right: 4.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'arrow_back',
                        color: Colors.white,
                        size: 5.w,
                      ),
                    ),
                  ),
                ),

                // Share and favorite buttons
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onShare,
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: 'share',
                            color: Colors.white,
                            size: 5.w,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    GestureDetector(
                      onTap: widget.onFavorite,
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: widget.isFavorite
                                ? 'favorite'
                                : 'favorite_border',
                            color: widget.isFavorite
                                ? theme.colorScheme.secondary
                                : Colors.white,
                            size: 5.w,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Page indicators
          if (widget.images.length > 1)
            Positioned(
              bottom: 2.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                      (index) => Container(
                    width: _currentPage == index ? 8.w : 2.w,
                    height: 1.h,
                    margin: EdgeInsets.symmetric(horizontal: 1.w),
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? theme.colorScheme.secondary
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(1.h),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullScreenGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(
          images: widget.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Full-screen gallery with zoom and swipe capabilities
class _FullScreenGallery extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;

  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image viewer with zoom
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: CustomImageWidget(
                    imageUrl: widget.images[index]["url"] as String,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    semanticLabel:
                    widget.images[index]["semanticLabel"] as String,
                  ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: 6.h,
            right: 4.w,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: Colors.white,
                    size: 6.w,
                  ),
                ),
              ),
            ),
          ),

          // Image counter
          Positioned(
            bottom: 4.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4.w),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
