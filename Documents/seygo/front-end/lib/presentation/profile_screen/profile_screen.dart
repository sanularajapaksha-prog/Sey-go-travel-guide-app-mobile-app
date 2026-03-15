import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'profile_modals.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _avatarPath = '';
  bool _isPrivatePlaylist = true;
  bool _isSideRailVisible = false;

  static const Color _ink = Color(0xFF272121);
  static const Color _accent = Color(0xFF2F86C9);

  final List<_ProfileChip> _chips = const [
    _ProfileChip('Camping'),
    _ProfileChip('Mountains', selected: true),
    _ProfileChip('Beachside'),
  ];

  final List<_PlaylistItem> _playlists = const [
    _PlaylistItem(
      title: 'Hill Country\nAdventures',
      imageUrl: 'https://images.unsplash.com/photo-1577717903315-1691ae25ab3f',
    ),
    _PlaylistItem(
      title: 'Beach Relax\nTrip',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
    ),
    _PlaylistItem(
      title: 'Weekend Short\nTrip',
      imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 8.w : 7.w,
                2.h,
                isCompact ? 6.w : 7.w,
                6.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isCompact ? 1.2.h : 1.8.h),
                  _buildProfileHero(isCompact),
                  SizedBox(height: isCompact ? 2.2.h : 3.h),
                  _buildBadgeCard(isCompact),
                  SizedBox(height: isCompact ? 2.2.h : 3.h),
                  _buildInterestChips(isCompact),
                  SizedBox(height: isCompact ? 2.4.h : 3.h),
                  _buildSummaryCard(isCompact),
                  SizedBox(height: isCompact ? 2.4.h : 3.h),
                  _buildPlaylistsCard(isCompact),
                  SizedBox(height: isCompact ? 2.4.h : 3.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildPrivacyToggle(isCompact),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: isCompact ? 36.h : 31.h,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: _isSideRailVisible
                    ? Offset.zero
                    : const Offset(-1.15, 0),
                child: _buildSideRail(isCompact),
              ),
            ),
            Positioned(
              left: isCompact ? 3.w : 3.5.w,
              bottom: isCompact ? 8.h : 7.h,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _isSideRailVisible ? 0 : 1,
                child: IgnorePointer(
                  ignoring: _isSideRailVisible,
                  child: _buildAssistiveTouch(isCompact),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHero(bool isCompact) {
    final ImageProvider? avatarImage = _avatarPath.isEmpty
        ? null
        : _avatarPath.startsWith('http')
            ? NetworkImage(_avatarPath)
            : FileImage(File(_avatarPath));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: isCompact ? 14.5.sp : 17.sp,
                  color: const Color(0xFF7C7B7A),
                ),
              ),
              SizedBox(height: isCompact ? 0.4.h : 0.8.h),
              Text(
                'Amanda Smith',
                style: TextStyle(
                  fontSize: isCompact ? 20.sp : 24.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6A6A6E),
                ),
              ),
              SizedBox(height: isCompact ? 0.7.h : 1.h),
              Text(
                'Australia | Age 23',
                style: TextStyle(
                  fontSize: isCompact ? 12.5.sp : 15.sp,
                  color: const Color(0xFF747D93),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => showAvatarPicker(context, (path) {
            setState(() => _avatarPath = path);
          }),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: isCompact ? 24.w : 27.w,
                height: isCompact ? 24.w : 27.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE7EAF0)),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: isCompact ? 9.7.w : 11.w,
                    backgroundColor: const Color(0xFFA9A6A8),
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? Text(
                            'Photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isCompact ? 11.sp : 14.sp,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                right: -1.w,
                bottom: 2.w,
                child: Container(
                  width: isCompact ? 7.2.w : 8.w,
                  height: isCompact ? 7.2.w : 8.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFAEAAAA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 5.w : 6.w,
        vertical: isCompact ? 2.2.h : 2.8.h,
      ),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mountain Explorer',
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 18.sp : 21.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: isCompact ? 0.8.h : 1.2.h),
          Text(
            'You mostly visit mountain and nature destinations.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: isCompact ? 12.6.sp : 15.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestChips(bool isCompact) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _chips.map((chip) {
        return Container(
          width: isCompact ? 22.5.w : 24.5.w,
          padding: EdgeInsets.symmetric(vertical: isCompact ? 1.05.h : 1.35.h),
          decoration: BoxDecoration(
            color: chip.selected ? const Color(0xFFCDDDF5) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD9E8FC)),
          ),
          child: Center(
            child: Text(
              chip.label,
              style: TextStyle(
                fontSize: isCompact ? 11.5.sp : 14.5.sp,
                color: const Color(0xFF1E2436),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard(bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 4.w : 5.w,
        isCompact ? 1.8.h : 2.2.h,
        isCompact ? 4.w : 5.w,
        isCompact ? 1.8.h : 2.2.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Activity Summary',
            style: TextStyle(
              fontSize: isCompact ? 15.5.sp : 17.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B2132),
            ),
          ),
          SizedBox(height: isCompact ? 1.6.h : 2.2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatTile(value: '42', label: 'Places', compact: isCompact),
              _StatTile(value: '12', label: 'Reviews', compact: isCompact),
              _StatTile(value: '89', label: 'Photos', compact: isCompact),
              _StatTile(value: '9', label: 'Journeys', compact: isCompact),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistsCard(bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 3.2.w : 4.w,
        isCompact ? 1.8.h : 2.2.h,
        isCompact ? 3.2.w : 4.w,
        isCompact ? 1.8.h : 2.2.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your Playlists',
            style: TextStyle(
              fontSize: isCompact ? 15.5.sp : 17.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B2132),
            ),
          ),
          SizedBox(height: isCompact ? 1.5.h : 2.1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _playlists.map((playlist) {
              return Container(
                width: isCompact ? 25.w : 25.5.w,
                padding: EdgeInsets.fromLTRB(
                  1.5.w,
                  isCompact ? 0.9.h : 1.1.h,
                  1.5.w,
                  isCompact ? 1.h : 1.3.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4E8EF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        playlist.imageUrl,
                        height: isCompact ? 7.4.h : 8.6.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: isCompact ? 0.9.h : 1.2.h),
                    Text(
                      playlist.title,
                      style: TextStyle(
                        fontSize: isCompact ? 11.5.sp : 13.7.sp,
                        height: 1.25,
                        color: const Color(0xFF23283A),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(0.5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD8DCE3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isPrivatePlaylist = false),
            child: _privacyPill('Public', !_isPrivatePlaylist, isCompact),
          ),
          GestureDetector(
            onTap: () => setState(() => _isPrivatePlaylist = true),
            child: _privacyPill('Private', _isPrivatePlaylist, isCompact),
          ),
        ],
      ),
    );
  }

  Widget _privacyPill(String label, bool selected, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4.w : 4.5.w,
        vertical: isCompact ? 0.65.h : 0.8.h,
      ),
      decoration: BoxDecoration(
        color: selected ? _accent : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isCompact ? 12.sp : 13.3.sp,
          color: selected ? Colors.white : const Color(0xFF272B39),
        ),
      ),
    );
  }

  Widget _buildSideRail(bool isCompact) {
    final items = <(String, VoidCallback)>[
      ('Saved', () => showSavedRoutesModal(context)),
      ('Achievement', () => showAchievementsModal(context)),
      ('Reviews', () => showMyReviewsModal(context)),
    ];

    return Container(
      width: isCompact ? 15.w : 16.w,
      padding: EdgeInsets.symmetric(vertical: isCompact ? 1.6.h : 2.h),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => setState(() => _isSideRailVisible = false),
              child: Padding(
                padding: EdgeInsets.only(
                  right: isCompact ? 1.8.w : 1.4.w,
                  bottom: isCompact ? 0.8.h : 0.9.h,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: const Color(0xFFF6CBAE),
                  size: isCompact ? 4.3.w : 3.6.w,
                ),
              ),
            ),
          ),
          ...items.map((item) {
            return GestureDetector(
              onTap: item.$2,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: isCompact ? 1.1.h : 1.4.h,
                ),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    '- ${item.$1}',
                    style: TextStyle(
                      color: const Color(0xFFF6CBAE),
                      fontSize: isCompact ? 10.3.sp : 12.4.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAssistiveTouch(bool isCompact) {
    return GestureDetector(
      onTap: () => setState(() => _isSideRailVisible = true),
      child: Container(
        width: isCompact ? 11.w : 9.w,
        height: isCompact ? 11.w : 9.w,
        decoration: BoxDecoration(
          color: _ink.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          color: const Color(0xFFF6CBAE),
          size: isCompact ? 5.w : 4.2.w,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final bool compact;

  const _StatTile({
    required this.value,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 14.5.w : 15.8.w,
      padding: EdgeInsets.symmetric(vertical: compact ? 1.5.h : 2.1.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E6FB)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 15.5.sp : 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2538),
            ),
          ),
          SizedBox(height: compact ? 0.8.h : 1.2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 9.2.sp : 11.5.sp,
              color: const Color(0xFF7A7E88),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileChip {
  final String label;
  final bool selected;

  const _ProfileChip(this.label, {this.selected = false});
}

class _PlaylistItem {
  final String title;
  final String imageUrl;

  const _PlaylistItem({required this.title, required this.imageUrl});
}
