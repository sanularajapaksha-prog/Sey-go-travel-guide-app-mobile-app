import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/offline_provider.dart';

/// Deterministic gradient palettes for playlist banners.
const List<List<Color>> _kBannerPalettes = [
  [Color(0xFF1A73E8), Color(0xFF0D47A1)],
  [Color(0xFF00897B), Color(0xFF004D40)],
  [Color(0xFFE53935), Color(0xFF880E4F)],
  [Color(0xFF7B1FA2), Color(0xFF311B92)],
  [Color(0xFFF57C00), Color(0xFFBF360C)],
  [Color(0xFF388E3C), Color(0xFF1B5E20)],
  [Color(0xFF0288D1), Color(0xFF01579B)],
  [Color(0xFFC2185B), Color(0xFF880E4F)],
];

List<Color> _paletteFor(String name) {
  final hash = name.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0x7FFFFFFF);
  return _kBannerPalettes[hash % _kBannerPalettes.length];
}

/// Individual playlist card widget.
///
/// Key design: the camera icon is placed OUTSIDE the main [InkWell] using a
/// top-level [Stack], so it wins the Flutter gesture arena without fighting
/// the card's tap handler. This is the only reliable way to have a tappable
/// overlay button inside an InkWell card.
class PlaylistCardWidget extends StatefulWidget {
  final Map<String, dynamic> playlist;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSaveOffline;
  final VoidCallback? onRemoveOffline;

  /// Called when user taps the camera icon. Null → icon not shown.
  final VoidCallback? onBannerTap;

  /// True when rendered inside the "Downloaded" offline section.
  final bool isOfflineCopy;

  const PlaylistCardWidget({
    super.key,
    required this.playlist,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onSaveOffline,
    this.onRemoveOffline,
    this.onBannerTap,
    this.isOfflineCopy = false,
  });

  @override
  State<PlaylistCardWidget> createState() => _PlaylistCardWidgetState();
}

class _PlaylistCardWidgetState extends State<PlaylistCardWidget> {
  // Banner height in logical pixels (evaluated lazily after first layout)
  static const double _bannerHeightFactor = 0.20; // 20.h equivalent

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlist = widget.playlist;
    final destinationCount =
        (playlist['destinationCount'] ?? playlist['destination_count'] ?? 0)
            as int;
    final previewImages = (playlist['previewImages'] as List? ?? const [])
        .map((item) => item.toString())
        .toList();
    final canManage = (playlist['is_editable'] as bool?) ?? true;

    // Show camera only on editable, non-offline-copy cards that have a handler
    final showCamera =
        canManage && !widget.isOfflineCopy && widget.onBannerTap != null;

    // Banner height in screen-relative units
    final bannerH = MediaQuery.of(context).size.height * _bannerHeightFactor;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      // Top-level Stack: card below, camera button above — completely outside InkWell
      child: Stack(
        children: [
          // ── Main card (InkWell handles the card tap) ──────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
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
                    _buildBanner(context, previewImages),
                    _buildInfoSection(context, destinationCount),
                  ],
                ),
              ),
            ),
          ),

          // ── Offline "Downloaded" badge (top-left of banner, outside InkWell) ──
          if (widget.isOfflineCopy)
            Positioned(
              top: 8,
              left: 8,
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.download_done_rounded,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'Downloaded',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Camera icon (bottom-right of banner, OUTSIDE InkWell) ──────────
          // Placed here so it receives taps first — no gesture arena conflict.
          if (showCamera)
            Positioned(
              // Align to bottom-right corner of the banner area
              top: bannerH - 38, // banner height minus icon button size (~38px)
              right: 8,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onBannerTap,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Banner image area (pure display — no buttons here) ─────────────────────

  Widget _buildBanner(BuildContext context, List<String> images) {
    final playlist = widget.playlist;
    final semanticLabels = (playlist['semanticLabels'] as List? ?? const [])
        .map((item) => item.toString())
        .toList();
    final fallbackLabel = (playlist['name'] as String?) ?? 'Playlist';

    if (images.isEmpty) {
      final nameQuery = Uri.encodeComponent(
          fallbackLabel.toLowerCase().replaceAll(' ', ','));
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
        child: CustomImageWidget(
          imageUrl: 'https://loremflickr.com/600/400/travel,$nameQuery/all',
          width: double.infinity,
          height: 20.h,
          fit: BoxFit.cover,
          semanticLabel: fallbackLabel,
        ),
      );
    }

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
        child: CustomImageWidget(
          imageUrl: images[0],
          width: double.infinity,
          height: 20.h,
          fit: BoxFit.cover,
          semanticLabel:
              semanticLabels.isNotEmpty ? semanticLabels.first : fallbackLabel,
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
      child: Row(
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

  // ── Info row below the banner ───────────────────────────────────────────────

  Widget _buildInfoSection(BuildContext context, int count) {
    final theme = Theme.of(context);
    final playlist = widget.playlist;
    final playlistId = playlist['id'] as String? ?? '';

    return Padding(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: (playlist['icon'] as String?) ?? 'playlist_play',
                size: 20,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  (playlist['name'] as String?) ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Offline toggle (download ↔ remove) — only on non-offline cards
              if (!widget.isOfflineCopy &&
                  (widget.onSaveOffline != null ||
                      widget.onRemoveOffline != null))
                _OfflineToggleButton(
                  playlistId: playlistId,
                  onSave: widget.onSaveOffline,
                  onRemove: widget.onRemoveOffline,
                ),
              // Remove-from-offline trash — only on offline-copy cards
              if (widget.isOfflineCopy && widget.onRemoveOffline != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: widget.onRemoveOffline,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Remove from offline',
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
          if (playlist['description'] != null &&
              (playlist['description'] as String).isNotEmpty) ...[
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

  // ── Context menu ───────────────────────────────────────────────────────────

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
                  color: theme.colorScheme.onSurface),
              title: Text('Rename', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                widget.onEdit();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                  iconName: 'content_copy',
                  size: 24,
                  color: theme.colorScheme.onSurface),
              title: Text('Duplicate', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('Playlist "${widget.playlist['name']}" duplicated'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                  iconName: 'share',
                  size: 24,
                  color: theme.colorScheme.onSurface),
              title: Text('Share', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('Sharing "${widget.playlist['name']}"...'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
            const Divider(),
            ListTile(
              leading: CustomIconWidget(
                  iconName: 'delete',
                  size: 24,
                  color: theme.colorScheme.error),
              title: Text('Delete',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Offline toggle button ──────────────────────────────────────────────────────

class _OfflineToggleButton extends StatelessWidget {
  final String playlistId;
  final VoidCallback? onSave;
  final VoidCallback? onRemove;

  const _OfflineToggleButton({
    required this.playlistId,
    required this.onSave,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<OfflineProvider>(
      builder: (context, offline, _) {
        final isCached = offline.isCached(playlistId);
        return IconButton(
          icon: Icon(
            isCached
                ? Icons.cloud_done_rounded
                : Icons.cloud_download_outlined,
            size: 20,
            color: isCached
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: isCached ? onRemove : onSave,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: isCached ? 'Remove from offline' : 'Save for offline',
        );
      },
    );
  }
}
