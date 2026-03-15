// lib/presentation/profile_screen/widgets/settings_section_widget.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SettingsItemData {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  SettingsItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}

class SettingsSectionWidget extends StatelessWidget {
  final String title;
  final List<SettingsItemData> items;

  const SettingsSectionWidget({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 1.5.h),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 5.w,
              endIndent: 5.w,
              color: theme.dividerColor.withOpacity(0.5),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Icon(
                  item.icon,
                  color: theme.colorScheme.primary,
                  size: 7.w,
                ),
                title: Text(
                  item.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: item.subtitle != null
                    ? Text(
                        item.subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing:
                    item.trailing ??
                    (item.onTap != null
                        ? Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        : null),
                onTap: item.onTap,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 5.w,
                  vertical: 1.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
