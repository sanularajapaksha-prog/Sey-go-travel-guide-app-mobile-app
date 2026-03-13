import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Dialog for creating or editing a playlist
class CreatePlaylistDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final bool isEdit;

  const CreatePlaylistDialog({
    super.key,
    this.initialName,
    this.initialDescription,
    this.isEdit = false,
  });

  @override
  State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _selectedIcon = 'playlist_play';

  final List<Map<String, String>> _iconOptions = [
    {'icon': 'playlist_play', 'label': 'Default'},
    {'icon': 'favorite', 'label': 'Favorites'},
    {'icon': 'explore', 'label': 'Explore'},
    {'icon': 'beach_access', 'label': 'Beach'},
    {'icon': 'terrain', 'label': 'Mountains'},
    {'icon': 'location_city', 'label': 'Cities'},
    {'icon': 'nature_people', 'label': 'Nature'},
    {'icon': 'restaurant', 'label': 'Food'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 70.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.isEdit ? 'Edit Playlist' : 'Create Playlist',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      size: 24,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Playlist Name',
                        hintText: 'Enter playlist name',
                      ),
                      autofocus: !widget.isEdit,
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add a description',
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 3.h),
                    Text('Choose Icon', style: theme.textTheme.titleSmall),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: _iconOptions.map((option) {
                        final isSelected = _selectedIcon == option['icon'];
                        return InkWell(
                          onTap: () =>
                              setState(() => _selectedIcon = option['icon']!),
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            width: 20.w,
                            padding: EdgeInsets.symmetric(vertical: 1.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              )
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.dividerColor,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                CustomIconWidget(
                                  iconName: option['icon']!,
                                  size: 28,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  option['label']!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: 2.w),
                  ElevatedButton(
                    onPressed: _nameController.text.trim().isEmpty
                        ? null
                        : () {
                      Navigator.pop(context, {
                        'name': _nameController.text.trim(),
                        'description': _descriptionController.text.trim(),
                        'icon': _selectedIcon,
                      });
                    },
                    child: Text(widget.isEdit ? 'Save' : 'Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
