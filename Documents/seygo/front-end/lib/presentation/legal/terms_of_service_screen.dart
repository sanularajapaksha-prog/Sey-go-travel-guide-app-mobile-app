import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const routeName = '/terms-of-service';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By accessing or using the SeyGo app, you agree to be bound by these Terms of Service. '
              'Please read them carefully before using our services.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            SizedBox(height: 3.h),
            _Section(
              number: '1',
              title: 'Acceptance of Terms',
              body:
                  'By creating an account or using SeyGo, you confirm that you are at least 13 years of age and '
                  'have the legal capacity to agree to these terms. If you are using SeyGo on behalf of an '
                  'organisation, you represent that you have the authority to bind that organisation.',
            ),
            _Section(
              number: '2',
              title: 'Use of the Service',
              body:
                  'SeyGo grants you a limited, non-exclusive, non-transferable licence to use the app for personal, '
                  'non-commercial purposes. You may not reverse-engineer, copy, redistribute, or create derivative '
                  'works from any part of the service.',
            ),
            _Section(
              number: '3',
              title: 'User Content',
              body:
                  'You retain ownership of content you submit (reviews, photos, itineraries). By submitting content, '
                  'you grant SeyGo a worldwide, royalty-free licence to display, distribute, and promote that '
                  'content within the platform. We reserve the right to remove any content that violates our '
                  'Community Guidelines.',
            ),
            _Section(
              number: '4',
              title: 'Account Responsibility',
              body:
                  'You are responsible for maintaining the confidentiality of your account credentials and for all '
                  'activity that occurs under your account. Notify us immediately at support@seygo.lk if you '
                  'suspect unauthorised access.',
            ),
            _Section(
              number: '5',
              title: 'Limitation of Liability',
              body:
                  'SeyGo provides travel information on an "as-is" basis. We do not guarantee the accuracy, '
                  'completeness, or reliability of any destination information, opening hours, or prices. '
                  'SeyGo shall not be liable for any damages arising from reliance on information in the app.',
            ),
            _Section(
              number: '6',
              title: 'Termination',
              body:
                  'We may suspend or terminate your account at any time for violation of these terms. '
                  'You may delete your account at any time from the Profile settings.',
            ),
            _Section(
              number: '7',
              title: 'Changes to Terms',
              body:
                  'We may update these Terms from time to time. Continued use of SeyGo after changes are posted '
                  'constitutes your acceptance of the revised terms.',
            ),
            _Section(
              number: '8',
              title: 'Governing Law',
              body:
                  'These Terms are governed by the laws of Sri Lanka. Any disputes shall be resolved in the courts '
                  'of Sri Lanka.',
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
  final String number;
  final String title;
  final String body;

  const _Section({
    required this.number,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 7.w,
                height: 7.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
                  ),
                ),
              ),
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
            padding: EdgeInsets.only(left: 10.w),
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
