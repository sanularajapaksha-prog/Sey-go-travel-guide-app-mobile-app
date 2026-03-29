import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  static const routeName = '/community-guidelines';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Guidelines'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              icon: Icons.handshake_outlined,
              title: 'Our Community Values',
              body:
                  'SeyGo is a platform built on respect, authenticity, and a shared love of travel. '
                  'By using SeyGo, you agree to help us maintain a safe, welcoming, and positive community for everyone.',
            ),
            _Section(
              icon: Icons.rate_review_outlined,
              title: 'Honest Reviews',
              body:
                  'Share genuine, first-hand experiences. Do not post fake, misleading, or incentivised reviews. '
                  'Constructive criticism is welcome — harassment of businesses or fellow travellers is not.',
            ),
            _Section(
              icon: Icons.photo_outlined,
              title: 'Appropriate Content',
              body:
                  'Only share photos and content that you own or have the right to share. '
                  'Content that is offensive, sexually explicit, violent, or discriminatory will be removed '
                  'and may result in account suspension.',
            ),
            _Section(
              icon: Icons.privacy_tip_outlined,
              title: 'Respect Privacy',
              body:
                  'Do not share personal information about other users without their consent. '
                  'Avoid photographing or tagging identifiable individuals without permission.',
            ),
            _Section(
              icon: Icons.block_outlined,
              title: 'Zero Tolerance',
              body:
                  'Hate speech, bullying, spam, and illegal activity are strictly prohibited. '
                  'Accounts found violating these rules will be permanently banned without notice.',
            ),
            _Section(
              icon: Icons.flag_outlined,
              title: 'Reporting',
              body:
                  'If you see content that violates these guidelines, use the report button or contact us at '
                  'support@seygo.lk. We review all reports within 48 hours.',
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
