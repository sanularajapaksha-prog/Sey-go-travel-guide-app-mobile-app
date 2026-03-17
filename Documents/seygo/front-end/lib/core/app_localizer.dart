import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';

class AppLocalizer {
  AppLocalizer(this.locale);

  final Locale locale;

  static const Map<String, Map<String, String>> _localized = {
    'en': {
      'general_settings': 'General Settings',
      'language': 'Language',
      'country_region': 'Country / Region',
      'time_zone': 'Time Zone',
      'notification_preferences': 'NOTIFICATION PREFERENCES',
      'unmute_notifications': 'Unmute (Receive all notifications)',
      'mute_notifications': 'Mute (Turn off all notifications)',
      'units': 'Units',
      'apply': 'Apply',
      'settings_saved': 'Settings saved',
      'select_language': 'Select Language',
      'select_country': 'Select Country',
      'select_time_zone': 'Select Time Zone',
      'select_units': 'Select Units',
      'main': 'MAIN',
      'profile_settings': 'Profile Settings',
      'account_details_identity': 'Account details and identity',
      'notifications_preferences': 'Notifications and preferences',
      'privacy': 'Privacy',
      'permissions_security': 'Permissions and security',
      'appearance': 'Appearance',
      'theme_visual_style': 'Theme and visual style',
      'help_support': 'Help & Support',
      'faqs_contact_support': 'FAQs and contact support',
      'ready_to_customize': 'Ready to customize?',
      'personalize_experience':
          'Use settings to personalize your app experience.',
      'logout': 'Logout',
      'welcome': 'Welcome',
    },
    'si': {
      'general_settings': 'සාමාන්‍ය සැකසුම්',
      'language': 'භාෂාව',
      'country_region': 'රට / කලාපය',
      'time_zone': 'වේලා කලාපය',
      'notification_preferences': 'දැනුම්දීම් අභිරුචි',
      'unmute_notifications': 'දැනුම්දීම් සියල්ල ලබාගන්න',
      'mute_notifications': 'සියලු දැනුම්දීම් නවත්වන්න',
      'units': 'මාපක ඒකක',
      'apply': 'යොදන්න',
      'settings_saved': 'සැකසුම් සුරකින ලදී',
      'select_language': 'භාෂාව තෝරන්න',
      'select_country': 'රට තෝරන්න',
      'select_time_zone': 'වේලා කලාපය තෝරන්න',
      'select_units': 'ඒකක තෝරන්න',
      'main': 'ප්‍රධාන',
      'profile_settings': 'පැතිකඩ සැකසුම්',
      'account_details_identity': 'ගිණුම් විස්තර සහ හැඳුනුම',
      'notifications_preferences': 'දැනුම්දීම් සහ අභිරුචි',
      'privacy': 'පෞද්ගලිකත්වය',
      'permissions_security': 'අවසර සහ ආරක්ෂාව',
      'appearance': 'පෙනුම',
      'theme_visual_style': 'තේමාව සහ දෘශ්‍ය රටාව',
      'help_support': 'උදව් සහ සහාය',
      'faqs_contact_support': 'නිතර අසන ප්‍රශ්න සහ සහාය',
      'ready_to_customize': 'අභිරුචිකරණයට සූදානම්ද?',
      'personalize_experience':
          'සැකසුම් භාවිතයෙන් ඔබේ යෙදුම් අත්දැකීම අභිරුචිකරණය කරන්න.',
      'logout': 'ඉවත් වන්න',
      'welcome': 'සාදරයෙන් පිළිගනිමු',
    },
    'ta': {
      'general_settings': 'பொது அமைப்புகள்',
      'language': 'மொழி',
      'country_region': 'நாடு / பகுதி',
      'time_zone': 'நேர மண்டலம்',
      'notification_preferences': 'அறிவிப்பு விருப்பங்கள்',
      'unmute_notifications': 'அனைத்து அறிவிப்புகளையும் பெறுக',
      'mute_notifications': 'அனைத்து அறிவிப்புகளையும் நிறுத்துக',
      'units': 'அளவீட்டு அலகுகள்',
      'apply': 'பயன்படுத்து',
      'settings_saved': 'அமைப்புகள் சேமிக்கப்பட்டன',
      'select_language': 'மொழியை தேர்ந்தெடுக்கவும்',
      'select_country': 'நாட்டை தேர்ந்தெடுக்கவும்',
      'select_time_zone': 'நேர மண்டலத்தை தேர்ந்தெடுக்கவும்',
      'select_units': 'அலகுகளை தேர்ந்தெடுக்கவும்',
      'main': 'முதன்மை',
      'profile_settings': 'சுயவிவர அமைப்புகள்',
      'account_details_identity': 'கணக்கு விவரங்கள் மற்றும் அடையாளம்',
      'notifications_preferences': 'அறிவிப்புகள் மற்றும் விருப்பங்கள்',
      'privacy': 'தனியுரிமை',
      'permissions_security': 'அனுமதிகள் மற்றும் பாதுகாப்பு',
      'appearance': 'தோற்றம்',
      'theme_visual_style': 'தீம் மற்றும் காட்சி அமைப்பு',
      'help_support': 'உதவி மற்றும் ஆதரவு',
      'faqs_contact_support': 'அடிக்கடி கேட்கப்படும் கேள்விகள் மற்றும் ஆதரவு',
      'ready_to_customize': 'தனிப்பயனாக்க தயாரா?',
      'personalize_experience':
          'அமைப்புகளை பயன்படுத்தி செயலி அனுபவத்தை தனிப்பயனாக்குங்கள்.',
      'logout': 'வெளியேறு',
      'welcome': 'வரவேற்கிறோம்',
    },
  };

  static AppLocalizer of(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    return AppLocalizer(locale);
  }

  String t(String key) {
    final code = locale.languageCode;
    return _localized[code]?[key] ?? _localized['en']![key] ?? key;
  }
}
