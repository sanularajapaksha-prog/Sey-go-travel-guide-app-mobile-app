// lib/widgets/help_support_popup.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart'; // for email/WhatsApp/phone taps

class HelpSupportPopup extends StatelessWidget {
  const HelpSupportPopup({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HelpSupportPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(6.w, 3.h, 6.w, 6.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    "Help & Support",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20.sp,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 26,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          SizedBox(height: 2.5.h),
          const Divider(height: 1),
          SizedBox(height: 3.h),

          // Contact Support Section
          Text(
            "CONTACT SUPPORT",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 2.h),

          _buildTile(
            context,
            icon: Icons.email_outlined,
            title: "Email Support",
            subtitle: "support@seygo.lk",
            onTap: () async {
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'support@seygo.lk',
                queryParameters: {'subject': 'SeyGo Support Request'},
              );
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              }
            },
          ),
          _buildTile(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            title: "WhatsApp Support",
            subtitle: "+94 XXX XXX XXXX",
            onTap: () async {
              final Uri waUri = Uri.parse(
                "https://wa.me/94XXXXXXXXXX?text=Hello%20SeyGo%20Support",
              );
              if (await canLaunchUrl(waUri)) {
                await launchUrl(waUri);
              }
            },
          ),
          _buildTile(
            context,
            icon: Icons.phone_outlined,
            title: "Phone Support",
            subtitle: "Mon-Sat 9AM - 6PM",
            onTap: () async {
              final Uri phoneUri = Uri(scheme: 'tel', path: '94XXXXXXXXXX');
              if (await canLaunchUrl(phoneUri)) {
                await launchUrl(phoneUri);
              }
            },
          ),

          SizedBox(height: 4.h),

          // Legal & Policies Section
          Text(
            "LEGAL & POLICIES",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 2.h),

          _buildTile(
            context,
            icon: Icons.group_outlined,
            title: "Community Guidelines",
            onTap: () {
              // TODO: Navigate to guidelines screen or open URL
              print("Open Community Guidelines");
            },
          ),
          _buildTile(
            context,
            icon: Icons.description_outlined,
            title: "Terms of Service",
            onTap: () {
              // TODO: Navigate or open URL
              print("Open Terms of Service");
            },
          ),
          _buildTile(
            context,
            icon: Icons.security_outlined,
            title: "Privacy Policy",
            onTap: () {
              // TODO: Navigate or open URL
              print("Open Privacy Policy");
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        child: Row(
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 0.3.h),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
