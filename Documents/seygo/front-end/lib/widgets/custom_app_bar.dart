import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom app bar for SeyGo travel discovery app
/// Implements clean, content-focused design with minimal elevation
/// following Contemporary Tropical Minimalism principles
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text to display in the app bar
  final String? title;

  /// Optional leading widget (typically back button or menu icon)
  final Widget? leading;

  /// Optional actions to display on the right side
  final List<Widget>? actions;

  /// Whether to show the back button automatically
  final bool automaticallyImplyLeading;

  /// Whether to center the title
  final bool centerTitle;

  /// Optional bottom widget (typically TabBar)
  final PreferredSizeWidget? bottom;

  /// Background color override
  final Color? backgroundColor;

  /// Foreground color override
  final Color? foregroundColor;

  /// Elevation override
  final double? elevation;

  /// Custom title widget (overrides title string)
  final Widget? titleWidget;

  const CustomAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.titleWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;

    // Determine colors based on theme
    final effectiveBackgroundColor =
        backgroundColor ??
            appBarTheme.backgroundColor ??
            theme.colorScheme.surface;

    final effectiveForegroundColor =
        foregroundColor ??
            appBarTheme.foregroundColor ??
            theme.colorScheme.onSurface;

    final effectiveElevation = elevation ?? appBarTheme.elevation ?? 0.0;

    // Set system UI overlay style based on background brightness
    final brightness = ThemeData.estimateBrightnessForColor(
      effectiveBackgroundColor,
    );
    final overlayStyle = brightness == Brightness.light
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;

    return AppBar(
      systemOverlayStyle: overlayStyle,
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: effectiveElevation,
      shadowColor: theme.colorScheme.shadow,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title:
      titleWidget ??
          (title != null
              ? Text(
            title!,
            style: appBarTheme.titleTextStyle?.copyWith(
              color: effectiveForegroundColor,
            ),
          )
              : null),
      centerTitle: centerTitle,
      actions: actions != null
          ? [
        ...actions!,
        const SizedBox(width: 8), // Padding on the right
      ]
          : null,
      bottom: bottom,
      iconTheme: IconThemeData(color: effectiveForegroundColor, size: 24),
      actionsIconTheme: IconThemeData(
        color: effectiveForegroundColor,
        size: 24,
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

/// Search-focused app bar variant for discovery screens
class CustomSearchAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// Hint text for search field
  final String hintText;

  /// Callback when search text changes
  final ValueChanged<String>? onSearchChanged;

  /// Callback when search is submitted
  final ValueChanged<String>? onSearchSubmitted;

  /// Optional leading widget
  final Widget? leading;

  /// Optional actions
  final List<Widget>? actions;

  /// Whether to autofocus the search field
  final bool autofocus;

  /// Text editing controller for search field
  final TextEditingController? controller;

  const CustomSearchAppBar({
    super.key,
    this.hintText = 'Search destinations...',
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.leading,
    this.actions,
    this.autofocus = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      leading: leading,
      title: Container(
        height: 50,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: theme.dividerColor, width: 1.0),
        ),
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          onChanged: onSearchChanged,
          onSubmitted: onSearchSubmitted,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: theme.inputDecorationTheme.hintStyle,
            prefixIcon: Icon(
              Icons.search,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            suffixIcon: controller?.text.isNotEmpty ?? false
                ? IconButton(
              icon: Icon(
                Icons.clear,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {
                controller?.clear();
                onSearchChanged?.call('');
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
          ),
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
