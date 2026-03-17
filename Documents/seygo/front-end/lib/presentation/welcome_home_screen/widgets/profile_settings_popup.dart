import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/api_service.dart';

class ProfileSettingsPopup extends StatefulWidget {
  const ProfileSettingsPopup({super.key});

  @override
  State<ProfileSettingsPopup> createState() => _ProfileSettingsPopupState();
}

class _ProfileSettingsPopupState extends State<ProfileSettingsPopup> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  String _travelStyle = 'Beach & Culture';
  String? _avatarUrl;
  File? _pickedImage;

  bool _loading = true;
  bool _saving = false;

  static const _travelStyles = [
    'Beach & Culture',
    'Adventure & Hiking',
    'Urban Exploration',
    'Nature & Wildlife',
    'Relaxation & Spa',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final profile = await ApiService.fetchProfile(accessToken: token);
    if (!mounted) return;
    if (profile != null) {
      setState(() {
        _nameCtrl.text = profile['full_name'] as String? ?? '';
        _bioCtrl.text = profile['bio'] as String? ?? '';
        _cityCtrl.text = profile['home_city'] as String? ?? '';
        _travelStyle = (profile['travel_style'] as String?)?.isNotEmpty == true
            ? (profile['travel_style'] as String)
            : 'Beach & Culture';
        _avatarUrl = profile['avatar_url'] as String?;
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<String?> _uploadAvatar(File file) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final ext = file.path.split('.').last;
    final path = 'avatars/$userId.$ext';

    try {
      await supabase.storage.from('profiles').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return supabase.storage.from('profiles').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    String? uploadedUrl;
    if (_pickedImage != null) {
      uploadedUrl = await _uploadAvatar(_pickedImage!);
    }

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final ok = await ApiService.updateProfile(
      fullName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      homeCity: _cityCtrl.text.trim(),
      travelStyle: _travelStyle,
      avatarUrl: uploadedUrl ?? _avatarUrl,
      accessToken: token,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context, true); // signal caller to refresh
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save profile'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      backgroundColor: theme.scaffoldBackgroundColor,
      insetPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Padding(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        child: _loading
            ? SizedBox(
                height: 20.h,
                child: const Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
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
                              Icon(
                                Icons.person_outline,
                                size: 26,
                                color: theme.colorScheme.primary,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Profile Settings',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 28),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      SizedBox(height: 2.h),

                      // Avatar
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 20.w,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              backgroundImage: _pickedImage != null
                                  ? FileImage(_pickedImage!)
                                  : (_avatarUrl != null &&
                                          _avatarUrl!.isNotEmpty
                                      ? NetworkImage(_avatarUrl!)
                                      : null) as ImageProvider?,
                              child: (_pickedImage == null &&
                                      (_avatarUrl == null ||
                                          _avatarUrl!.isEmpty))
                                  ? Icon(
                                      Icons.person,
                                      size: 35.w,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickPhoto,
                                child: Container(
                                  padding: EdgeInsets.all(1.5.w),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    size: 18,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 3.h),

                      Text(
                        'BASIC INFORMATION',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                      SizedBox(height: 2.h),

                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),

                      SizedBox(height: 2.h),

                      TextFormField(
                        controller: _bioCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),

                      SizedBox(height: 2.h),

                      TextFormField(
                        controller: _cityCtrl,
                        decoration: InputDecoration(
                          labelText: 'Home City',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      SizedBox(height: 2.h),

                      DropdownButtonFormField<String>(
                        value: _travelStyles.contains(_travelStyle)
                            ? _travelStyle
                            : _travelStyles.first,
                        decoration: InputDecoration(
                          labelText: 'Preferred Travel Style',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _travelStyles
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _travelStyle = v);
                        },
                      ),

                      SizedBox(height: 4.h),

                      SizedBox(
                        width: double.infinity,
                        height: 6.h,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Apply',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
