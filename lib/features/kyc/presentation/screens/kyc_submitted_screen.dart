import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Post-submission confirmation for KYC.
class KycSubmittedScreen extends StatelessWidget {
  const KycSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Documents flying into shield
              SizedBox(
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: AppColors.primary, size: 52),
                    ).animate().scaleXY(
                        begin: 0.6,
                        end: 1,
                        duration: 500.ms,
                        curve: Curves.elasticOut),
                    ...List.generate(3, (i) {
                      return const Icon(Icons.description_rounded,
                              color: AppColors.primary200, size: 26)
                          .animate(delay: (200 + i * 220).ms)
                          .fadeIn(duration: 200.ms)
                          .slide(
                            begin: Offset(-1.6 + i * 0.4, -1.2),
                            end: Offset.zero,
                            duration: 600.ms,
                            curve: Curves.easeInCubic,
                          )
                          .then()
                          .fadeOut(duration: 150.ms);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              Text('KYC Submitted for Review',
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 8),
              Text('Our team will review within 24-48 hours',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  )).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 30),

              ...List.generate(3, (i) {
                final steps = [
                  ('1', 'Admin reviews documents (24-48 hrs)'),
                  ('2', 'Approval: badge added to profile'),
                  ('3', 'SafeBuy Verification Card generated'),
                ];
                final (n, label) = steps[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(n,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(label,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            )),
                      ),
                    ],
                  ),
                ).animate(delay: (500 + i * 120).ms).fadeIn().slideX(
                      begin: 0.06,
                    );
              }),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil('/home', (r) => false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text('Return to Dashboard'),
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
