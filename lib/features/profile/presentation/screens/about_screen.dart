import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../core/widgets/nepal_logo.dart';

/// About SafeBuy Nepal — academic + project info.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(title: const Text('About SafeBuy Nepal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          // Logo + version
          Center(
            child: Column(
              children: [
                const NepalLogo(size: 96),
                const SizedBox(height: 14),
                Text('SafeBuy Nepal',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                Text(
                  'Version ${AppConfig.appVersion} (Build ${AppConfig.buildNumber})',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          _section(
            'About This Project',
            'SafeBuy Nepal is a BSc (Hons) Ethical Hacking and '
                'Cybersecurity thesis project developed at Softwarica '
                'College of IT and E-Commerce, affiliated with Coventry '
                'University, United Kingdom.',
          ),
          _section(
            'Developer',
            'Sagesh Adhikari\n'
                'Student ID: 230298 (Softwarica)\n'
                'Student ID: 14806504 (Coventry)\n'
                'sageshadhikari@gmail.com',
          ),
          _section(
            'Supervisor',
            'Manoj Shrestha\n'
                'Academic Strategic Head\n'
                'Softwarica College of IT and E-Commerce',
          ),
          _section(
            'Technology',
            'Built with Flutter and Firebase\n'
                'Trust ratings: 5-factor weighted model\n'
                'Automated safety checks run around the clock\n'
                'Academic Year: 2025-2026',
          ),

          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/privacy'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46)),
                  child: const Text('Privacy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/terms'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46)),
                  child: const Text('Terms'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(
                        text: 'https://safebuy-nepal.vercel.app'));
                    if (context.mounted) {
                      PopupHelper.showInfo(
                          context, 'Website link copied to clipboard');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46)),
                  child: const Text('Website'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('© 2026 SafeBuy Nepal. BSc Thesis Project.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                )),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 6),
            Text(body,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.65,
                )),
          ],
        ),
      ),
    );
  }
}
