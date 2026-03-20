import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Destination name, location, description plus rating, phone, website, hours
class DestinationInfoWidget extends StatelessWidget {
  final String name;
  final String location;
  final String description;
  final double rating;
  final int reviews;
  final String? phone;
  final String? website;
  final dynamic openingHours;

  const DestinationInfoWidget({
    super.key,
    required this.name,
    required this.location,
    required this.description,
    this.rating = 0.0,
    this.reviews = 0,
    this.phone,
    this.website,
    this.openingHours,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            name,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),

          // Location
          Row(
            children: [
              CustomIconWidget(
                iconName: 'location_on',
                color: theme.colorScheme.secondary,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  location,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          // Rating row
          if (rating > 0) ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                ...List.generate(5, (i) {
                  if (i < rating.floor()) {
                    return Icon(Icons.star, color: const Color(0xFFFFA500), size: 5.w);
                  } else if (i < rating && rating - i >= 0.5) {
                    return Icon(Icons.star_half, color: const Color(0xFFFFA500), size: 5.w);
                  } else {
                    return Icon(Icons.star_border, color: const Color(0xFFFFA500), size: 5.w);
                  }
                }),
                SizedBox(width: 2.w),
                Text(
                  rating.toStringAsFixed(1),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (reviews > 0) ...[
                  SizedBox(width: 1.w),
                  Text(
                    '($reviews reviews)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],

          SizedBox(height: 2.h),

          // Description
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),

          // Phone
          if (phone != null && phone!.isNotEmpty) ...[
            SizedBox(height: 2.h),
            _InfoRow(
              icon: 'phone',
              label: phone!,
              onTap: () => launchUrl(Uri.parse('tel:$phone')),
              theme: theme,
            ),
          ],

          // Website
          if (website != null && website!.isNotEmpty) ...[
            SizedBox(height: 1.h),
            _InfoRow(
              icon: 'language',
              label: website!,
              onTap: () => launchUrl(Uri.parse(website!), mode: LaunchMode.externalApplication),
              theme: theme,
            ),
          ],

          // Opening hours
          if (openingHours != null) ...[
            SizedBox(height: 1.h),
            _HoursSection(openingHours: openingHours, theme: theme),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onTap;
  final ThemeData theme;

  const _InfoRow({required this.icon, required this.label, this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          CustomIconWidget(
            iconName: icon,
            color: theme.colorScheme.secondary,
            size: 5.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onTap != null ? theme.colorScheme.primary : null,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursSection extends StatelessWidget {
  final dynamic openingHours;
  final ThemeData theme;

  const _HoursSection({required this.openingHours, required this.theme});

  @override
  Widget build(BuildContext context) {
    String hoursText = '';
    if (openingHours is String) {
      hoursText = openingHours as String;
    } else if (openingHours is List) {
      hoursText = (openingHours as List).join('\n');
    } else if (openingHours is Map) {
      hoursText = (openingHours as Map).entries.map((e) => '${e.key}: ${e.value}').join('\n');
    }

    if (hoursText.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIconWidget(
          iconName: 'schedule',
          color: theme.colorScheme.secondary,
          size: 5.w,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            hoursText,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
