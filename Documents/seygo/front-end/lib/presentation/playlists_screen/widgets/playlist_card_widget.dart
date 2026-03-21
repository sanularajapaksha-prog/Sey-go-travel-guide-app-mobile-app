import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Deterministic gradient palettes for playlist banners.
/// Index is picked by hashing the playlist name so each playlist
/// always gets the same colours.
const List<List<Color>> _kBannerPalettes = [
  [Color(0xFF1A73E8), Color(0xFF0D47A1)], // blue
  [Color(0xFF00897B), Color(0xFF004D40)], // teal
  [Color(0xFFE53935), Color(0xFF880E4F)], // red→pink
  [Color(0xFF7B1FA2), Color(0xFF311B92)], // purple
  [Color(0xFFF57C00), Color(0xFFBF360C)], // orange→deep-orange
  [Color(0xFF388E3C), Color(0xFF1B5E20)], // green
  [Color(0xFF0288D1), Color(0xFF01579B)], // light-blue→blue
  [Color(0xFFC2185B), Color(0xFF880E4F)], // pink
];

List<Color> _paletteFor(String name) {
  final hash = name.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0x7FFFFFFF);
  return _kBannerPalettes[hash % _kBannerPalettes.length];
}

/// Individual playlist card widget displaying playlist information
/// with swipe actions and tap navigation
class PlaylistCardWidget extends StatelessWidget {
  final Map<String, dynamic> playlist;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PlaylistCardWidget({
    super.key,
    required this.playlist,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destinationCount =
        (playlist['destinationCount'] ?? playlist['destination_count'] ?? 0)
            as int;
    final previewImages = (playlist['previewImages'] as List? ?? const [])
        .map((item) => item.toString())
        .toList();
    final canManage = (playlist['is_editable'] as bool?) ?? true;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: canManage ? () => _showContextMenu(context) : null,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow,
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreviewSection(context, previewImages),
                _buildInfoSection(context, destinationCount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context, List<String> images) {
    final semanticLabels = (playlist['semanticLabels'] as List? ?? const [])
        .map((item) => item.toString())
        .toList();
    final fallbackLabel = (playlist['name'] as String?) ?? 'Playlist';

    if (images.isEmpty) {
      return _buildGradientBanner(context, fallbackLabel);
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
      child: images.length == 1
          ? CustomImageWidget(
              imageUrl: images[0],
              width: double.infinity,
              height: 20.h,
              fit: BoxFit.cover,
              semanticLabel:
                  semanticLabels.isNotEmpty ? semanticLabels.first : fallbackLabel,
            )
          : Row(
              children: List.generate(
                images.length > 3 ? 3 : images.length,
                (index) => Expanded(
                  child: CustomImageWidget(
                    imageUrl: images[index],
                    width: double.infinity,
                    height: 20.h,
                    fit: BoxFit.cover,
                    semanticLabel: semanticLabels.length > index
                        ? semanticLabels[index]
                        : fallbackLabel,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildGradientBanner(BuildContext context, String name) {
    final colors = _paletteFor(name);
    final iconName = (playlist['icon'] as String?) ?? 'playlist_play';
    final stopCount = playlist['stop_count'] ?? playlist['stops_count'] ?? '';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
      child: Container(
        height: 20.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles for depth
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -10,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Centre content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: iconName,
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (stopCount != '' && stopCount != 0) ...[
                    SizedBox(height: 0.4.h),
                    Text(
                      '$stopCount stops',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, int count) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: playlist['icon'] as String,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  playlist['name'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if ((playlist['is_editable'] as bool?) ?? true)
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'more_vert',
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => _showContextMenu(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            '$count ${count == 1 ? 'destination' : 'destinations'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (playlist['description'] != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              playlist['description'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if ((playlist['creator_name'] as String?)?.isNotEmpty ?? false) ...[
            SizedBox(height: 0.5.h),
            Text(
              'By ${playlist['creator_name']}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dialogTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'edit',
                size: 24,
                color: theme.colorScheme.onSurface,
              ),
              title: Text('Rename', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'content_copy',
                size: 24,
                color: theme.colorScheme.onSurface,
              ),
              title: Text('Duplicate', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _duplicatePlaylist(context);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                size: 24,
                color: theme.colorScheme.onSurface,
              ),
              title: Text('Share', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _sharePlaylist(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                size: 24,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _duplicatePlaylist(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playlist "${playlist['name']}" duplicated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sharePlaylist(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${playlist['name']}"...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
