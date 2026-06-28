import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../utils/constants.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(AppColors.gradStart), Color(AppColors.gradEnd)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Colors.white, size: 64),
                ),
                const SizedBox(height: 24),
                const Text(
                  'SafeBuy Nepal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Buy Smart. Stay Safe.\nबुद्धिमानीले किन्नुहोस्। सुरक्षित रहनुहोस्।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 56),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Select Language / भाषा छान्नुहोस्',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(AppColors.textDark),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _LangOption(
                        flag: '🇬🇧',
                        title: 'English',
                        subtitle: 'Continue in English',
                        lang: 'en',
                        color: const Color(0xFF003087),
                      ),
                      const SizedBox(height: 12),
                      _LangOption(
                        flag: '🇳🇵',
                        title: 'नेपाली',
                        subtitle: 'नेपालीमा जारी राख्नुहोस्',
                        lang: 'ne',
                        color: const Color(0xFFDC143C),
                      ),
                    ],
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

class _LangOption extends ConsumerWidget {
  final String flag;
  final String title;
  final String subtitle;
  final String lang;
  final Color color;

  const _LangOption({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.lang,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await ref.read(languageProvider.notifier).setLanguage(lang);
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/onboarding');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
