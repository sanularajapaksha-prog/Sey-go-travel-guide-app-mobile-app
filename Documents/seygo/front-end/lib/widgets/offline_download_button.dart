import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../data/models/offline_cache_item.dart';
import '../providers/offline_provider.dart';
import '../theme/app_theme.dart';

/// A button that saves/removes an [OfflineCacheItem] using [OfflineProvider].
///
/// Shows four states: idle (not cached), downloading, cached, error.
class OfflineDownloadButton extends StatefulWidget {
  /// A unique stable id for the item (place id or trip id).
  final String itemId;

  /// Called when the user taps download — return the item to save.
  final Future<OfflineCacheItem?> Function() onBuild;

  /// Optional compact icon-only mode (used in list cards).
  final bool compact;

  const OfflineDownloadButton({
    super.key,
    required this.itemId,
    required this.onBuild,
    this.compact = false,
  });

  @override
  State<OfflineDownloadButton> createState() => _OfflineDownloadButtonState();
}

enum _BtnState { idle, downloading, cached, error }

class _OfflineDownloadButtonState extends State<OfflineDownloadButton> {
  _BtnState _state = _BtnState.idle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync with provider state without listening for rebuild here;
    // the Consumer below handles reactive updates.
  }

  Future<void> _toggle(OfflineProvider provider) async {
    if (_state == _BtnState.downloading) return;

    if (provider.isCached(widget.itemId)) {
      // Remove from cache
      await provider.deleteById(widget.itemId);
      if (mounted) setState(() => _state = _BtnState.idle);
      return;
    }

    setState(() => _state = _BtnState.downloading);
    try {
      final item = await widget.onBuild();
      if (item == null) {
        if (mounted) setState(() => _state = _BtnState.error);
        return;
      }
      await provider.save(item);
      if (mounted) setState(() => _state = _BtnState.cached);
    } catch (_) {
      if (mounted) setState(() => _state = _BtnState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, provider, _) {
        final isCached = provider.isCached(widget.itemId);
        final effectiveState = _state == _BtnState.downloading
            ? _BtnState.downloading
            : isCached
                ? _BtnState.cached
                : _state == _BtnState.error
                    ? _BtnState.error
                    : _BtnState.idle;

        if (widget.compact) {
          return _CompactButton(
            state: effectiveState,
            onTap: () => _toggle(provider),
          );
        }
        return _FullButton(
          state: effectiveState,
          onTap: () => _toggle(provider),
        );
      },
    );
  }
}

// ── Full-width button ─────────────────────────────────────────────────────────

class _FullButton extends StatelessWidget {
  final _BtnState state;
  final VoidCallback onTap;

  const _FullButton({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCached = state == _BtnState.cached;
    final isLoading = state == _BtnState.downloading;
    final isError = state == _BtnState.error;

    final color = isError
        ? theme.colorScheme.error
        : isCached
            ? AppTheme.secondaryLight
            : theme.colorScheme.outline;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.outline,
                ),
              )
            : Icon(
                isCached
                    ? Icons.offline_bolt_rounded
                    : isError
                        ? Icons.error_outline_rounded
                        : Icons.download_outlined,
                color: color,
                size: 20,
              ),
        label: Text(
          isLoading
              ? 'Saving…'
              : isCached
                  ? 'Saved Offline'
                  : isError
                      ? 'Retry Download'
                      : 'Save Offline',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 1.8.h),
          side: BorderSide(color: color),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Compact icon button ───────────────────────────────────────────────────────

class _CompactButton extends StatelessWidget {
  final _BtnState state;
  final VoidCallback onTap;

  const _CompactButton({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLoading = state == _BtnState.downloading;
    final isCached = state == _BtnState.cached;
    final isError = state == _BtnState.error;

    final color = isError
        ? Theme.of(context).colorScheme.error
        : isCached
            ? AppTheme.secondaryLight
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.55);

    return IconButton(
      onPressed: isLoading ? null : onTap,
      tooltip: isCached ? 'Remove offline copy' : 'Save offline',
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(
              isCached
                  ? Icons.offline_bolt_rounded
                  : isError
                      ? Icons.error_outline_rounded
                      : Icons.download_outlined,
              color: color,
              size: 22,
            ),
    );
  }
}
