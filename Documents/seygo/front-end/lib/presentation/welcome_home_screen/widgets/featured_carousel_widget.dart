import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

class FeaturedCarouselWidget extends StatefulWidget {
  final List<Map<String, dynamic>> destinations;
  final Function(Map<String, dynamic>) onDestinationTap;

  const FeaturedCarouselWidget({
    super.key,
    required this.destinations,
    required this.onDestinationTap,
  });

  @override
  State<FeaturedCarouselWidget> createState() => _FeaturedCarouselWidgetState();
}

class _FeaturedCarouselWidgetState extends State<FeaturedCarouselWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 25.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.destinations.length,
            itemBuilder: (context, index) {
              final destination = widget.destinations[index];
              return GestureDetector(
                onTap: () => widget.onDestinationTap(destination),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22.0),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow,
                        blurRadius: 16.0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22.0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomImageWidget(
                          imageUrl: destination['image'] as String,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          semanticLabel: destination['semanticLabel'] as String,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2.h,
                          left: 4.w,
                          right: 4.w,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destination['name'] as String,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                destination['category'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.destinations.length,
                (index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              width: _currentPage == index ? 3.4.w : 2.2.w,
              height: 0.9.h,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
