import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const routeName = '/privacy-policy';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your privacy matters to us. This policy explains what data we collect, how we use it, '
              'and the choices you have.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            SizedBox(height: 3.h),
            _Section(
              icon: Icons.person_outline_rounded,
              title: 'Information We Collect',
              body:
                  '• Account information: name, email address, and profile photo when you register.\n'
                  '• Content you create: reviews, ratings, comments, and saved playlists.\n'
                  '• Usage data: pages visited, searches performed, and features used within the app.\n'
                  '• Device information: device type, OS version, and app version for crash reporting.',
            ),
            _Section(
              icon: Icons.settings_outlined,
              title: 'How We Use Your Information',
              body:
                  '• To provide and personalise the SeyGo experience.\n'
                  '• To show destination recommendations relevant to your interests.\n'
                  '• To send important service notifications (account, security).\n'
                  '• To improve the app through aggregated, anonymised analytics.\n'
                  '• We do not sell your personal data to third parties.',
            ),
            _Section(
              icon: Icons.share_outlined,
              title: 'Data Sharing',
              body:
                  'We only share your data with:\n'
                  '• Supabase — our database and authentication provider, governed by their own privacy policy.\n'
                  '• Service providers acting on our behalf under strict data-processing agreements.\n'
                  '• Authorities when required by law.',
            ),
            _Section(
              icon: Icons.lock_outline_rounded,
              title: 'Data Security',
              body:
                  'All data is encrypted in transit using TLS. Passwords are never stored in plain text. '
                  'Access to user data is restricted to authorised personnel only. '
                  'In the event of a data breach, we will notify affected users within 72 hours.',
            ),
            _Section(
              icon: Icons.storage_outlined,
              title: 'Data Retention',
              body:
                  'We retain your account data for as long as your account is active. '
                  'When you delete your account, all personally identifiable data is permanently removed within 30 days.',
            ),
            _Section(
              icon: Icons.tune_outlined,
              title: 'Your Rights',
              body:
                  'You have the right to:\n'
                  '• Access the personal data we hold about you.\n'
                  '• Correct inaccurate data.\n'
                  '• Request deletion of your account and data.\n'
                  '• Export your data in a portable format.\n\n'
                  'To exercise any of these rights, contact us at support@seygo.lk.',
            ),
            _Section(
              icon: Icons.child_care_outlined,
              title: "Children's Privacy",
              body:
                  'SeyGo is not directed at children under 13. We do not knowingly collect data from children. '
                  'If you believe a child has provided us with personal information, contact us immediately.',
            ),
            _Section(
              icon: Icons.update_outlined,
              title: 'Changes to This Policy',
              body:
                  'We may update this Privacy Policy periodically. We will notify you of significant changes '
                  'via in-app notification or email. Continued use of SeyGo after changes constitutes acceptance.',
            ),
            SizedBox(height: 2.h),
            Text(
              'Last updated: March 2026',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Section({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 5.w, color: theme.colorScheme.primary),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
