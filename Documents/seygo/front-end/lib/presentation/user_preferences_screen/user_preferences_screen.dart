import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/api_service.dart';
import '../../routes/app_routes.dart';

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  final Set<String> _selected = {};
  bool _isSaving = false;

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Beach & Coastal', 'icon': Icons.beach_access},
    {'label': 'Wildlife & Nature', 'icon': Icons.pets},
    {'label': 'Mountain Climbing', 'icon': Icons.landscape},
    {'label': 'Cultural Heritage', 'icon': Icons.account_balance},
    {'label': 'Adventure Sports', 'icon': Icons.sports_motorsports},
    {'label': 'Historical Sites', 'icon': Icons.fort},
    {'label': 'Local Cuisine', 'icon': Icons.restaurant},
    {'label': 'City Life', 'icon': Icons.location_city},
    {'label': 'Photography', 'icon': Icons.camera_alt},
    {'label': 'Waterfalls', 'icon': Icons.water_drop},
    {'label': 'Tea Plantations', 'icon': Icons.eco},
    {'label': 'Temples & Religion', 'icon': Icons.temple_hindu},
  ];

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      final prefs = _selected.join(', ');
      await ApiService.updateProfile(
        travelStyle: prefs.isEmpty ? null : prefs,
        accessToken: token,
      );
    } catch (_) {
      // Preferences are optional; ignore save errors
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.welcomeHomeScreen,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2B84B4);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What do you love?',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pick your travel interests to personalise your SeyGo experience.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF7B8794),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.4,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final item = _categories[index];
                    final label = item['label'] as String;
                    final icon = item['icon'] as IconData;
                    final isSelected = _selected.contains(label);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(label);
                          } else {
                            _selected.add(label);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSelected ? brandBlue : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? brandBlue
                                : const Color(0xFFE3E7ED),
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: brandBlue.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 20,
                              color: isSelected ? Colors.white : brandBlue,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                label,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF1F1F1F),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _selected.isEmpty ? 'Skip for now' : 'Get Started',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
