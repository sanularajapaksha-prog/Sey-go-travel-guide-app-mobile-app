import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

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
    final destinationCount = playlist['destinationCount'] as int;
    final previewImages = playlist['previewImages'] as List<String>;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
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
    final theme = Theme.of(context);

    return Container(
      height: 20.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
      ),
      child: images.isEmpty
          ? Center(
        child: CustomIconWidget(
          iconName: 'photo_library',
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withValues(
            alpha: 0.3,
          ),
        ),
      )
          : ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12.0),
        ),
        child: images.length == 1
            ? CustomImageWidget(
          imageUrl: images[0],
          width: double.infinity,
          height: 20.h,
          fit: BoxFit.cover,
          semanticLabel: playlist['semanticLabels'][0] as String,
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
                semanticLabel:
                (playlist['semanticLabels']
                as List<String>)[index],
              ),
            ),
          ),
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
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dialogBackgroundColor,
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
