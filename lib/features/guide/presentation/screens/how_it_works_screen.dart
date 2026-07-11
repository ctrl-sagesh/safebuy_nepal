import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Guide screen: For Buyers | For Sellers | About SafeBuy.
class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bgSecondary,
        appBar: AppBar(
          title: const Text('How It Works'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 12.5),
            tabs: const [
              Tab(text: 'For Buyers'),
              Tab(text: 'For Sellers'),
              Tab(text: 'About'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_BuyersTab(), _SellersTab(), _AboutTab()],
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _NumStep extends StatelessWidget {
  const _NumStep(this.n, this.emoji, this.text);

  final int n;
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$n',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                )),
          ),
          const SizedBox(width: 10),
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.55,
                )),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.emoji, this.text);

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  height: 1.55,
                )),
          ),
        ],
      ),
    );
  }
}

// ── For Buyers ─────────────────────────────────────────────────────────────────

class _BuyersTab extends StatelessWidget {
  const _BuyersTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _Section(
          title: '🔍 How to Search',
          child: Column(children: [
            _NumStep(1, '📱', 'Open the Search tab from the bottom bar'),
            _NumStep(2, '⌨️',
                'Enter the seller\'s phone, eSewa ID, or @handle'),
            _NumStep(3, '🪪',
                'Their SafeBuy verification card appears with the trust score'),
            _NumStep(4, '✅',
                'Check reviews, reports, and the locked QR before paying'),
          ]),
        ),
        _Section(
          title: '📊 Understanding Trust Scores',
          child: Column(
            children: [
              // 0-100 meter
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 16,
                  child: Row(
                    children: [
                      Expanded(
                          flex: 50,
                          child: Container(color: AppColors.highRisk)),
                      Expanded(
                          flex: 30,
                          child:
                              Container(color: AppColors.unverified)),
                      Expanded(
                          flex: 20,
                          child: Container(color: AppColors.trusted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0-49 High Risk',
                      style: GoogleFonts.inter(
                          fontSize: 10.5, color: AppColors.highRisk)),
                  Text('50-79 Unverified',
                      style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: AppColors.unverified)),
                  Text('80-100 Trusted',
                      style: GoogleFonts.inter(
                          fontSize: 10.5, color: AppColors.trusted)),
                ],
              ),
              const SizedBox(height: 10),
              const _Bullet('⚖️',
                  'The score weighs fraud reports (40%), verification (25%), reviews (20%), dispute handling (10%), and account age (5%).'),
            ],
          ),
        ),
        const _Section(
          title: '🎖️ Badge Meanings',
          child: Column(children: [
            _Bullet('🏆',
                'PREMIUM — full KYC: identity, PAN, and business location verified'),
            _Bullet('🟢',
                'VERIFIED — identity verified with citizenship card, QR locked'),
            _Bullet('🔵', 'BASIC — phone and business details confirmed'),
            _Bullet('⚪',
                'UNVERIFIED — no identity verification yet; extra caution advised'),
          ]),
        ),
        const _Section(
          title: '🚩 How to Report',
          child: Column(children: [
            _NumStep(1, '📸', 'Screenshot the payment and chat evidence'),
            _NumStep(2, '📋',
                'Tap Report Fraud and fill in the seller identifiers'),
            _NumStep(
                3, '📝', 'Describe the incident with date and amount'),
            _NumStep(4, '⚡',
                'Submit — the seller\'s score updates within minutes'),
          ]),
        ),
        _Section(
          title: '💡 Pro Tips',
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(children: [
              _Bullet('🚚', 'Always prefer Cash on Delivery when offered'),
              _Bullet('💰',
                  'Never pay 100% advance to an unverified seller'),
              _Bullet('🔒',
                  'Only trust QR codes shown on a SafeBuy verification card'),
              _Bullet('🕐',
                  'Festival seasons (Dashain/Tihar) are peak scam periods'),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── For Sellers ────────────────────────────────────────────────────────────────

class _SellersTab extends StatelessWidget {
  const _SellersTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        _Section(
          title: '🏪 Why Register',
          child: Column(children: [
            _Bullet('🤝',
                'Buyers hesitate to pay unknown sellers — a SafeBuy record turns hesitation into sales'),
            _Bullet('🛡️',
                'Protects you from clone accounts impersonating your business'),
            _Bullet('🏆',
                'Leaderboard placement puts your shop in front of thousands of buyers'),
            _Bullet('💬',
                'You can respond publicly to any report filed against you'),
          ]),
        ),
        _Section(
          title: '🪪 Verification Process',
          child: Column(children: [
            _NumStep(1, '🔵',
                'BASIC — register your business with phone and email'),
            _NumStep(2, '🟢',
                'VERIFIED — selfie with citizenship card + locked eSewa QR + Gmail link'),
            _NumStep(3, '🏆',
                'PREMIUM — add PAN card and business location photos with GPS'),
          ]),
        ),
        _Section(
          title: '💳 The Verification Card',
          child: Column(children: [
            _Bullet('🎫',
                'Approved sellers receive a digital SafeBuy card with a unique ID (SBV-2026-XXXXX)'),
            _Bullet('📢',
                'Display the card ID in your TikTok/Instagram bio so buyers can verify you'),
            _Bullet('🗓️',
                'Cards are valid 6 months, then a quick re-verification keeps your badge'),
          ]),
        ),
        _Section(
          title: '🔒 QR Code Protection',
          child: Column(children: [
            _Bullet('🧷',
                'Your official payment QR is locked to your card — buyers can spot fake QRs instantly'),
            _Bullet('📋',
                'Changing the QR requires an admin-reviewed request with explanation'),
            _Bullet('🚫',
                'This defeats the QR-swap fraud documented by Nepal Police in 2023'),
          ]),
        ),
        _Section(
          title: '🔐 Data Privacy',
          child: Column(children: [
            _Bullet('👁️',
                'Buyers see: business name, category, district, tier, score, reviews, QR, card ID'),
            _Bullet('🙈',
                'Never shown: PAN number, citizenship number, selfie, GPS, Gmail, full address'),
            _Bullet('🗄️',
                'KYC documents are stored encrypted and reviewed only by the admin team'),
          ]),
        ),
      ],
    );
  }
}

// ── About ──────────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _Section(
          title: '🎯 Our Mission',
          child: Text(
            'Social commerce fraud is Nepal\'s fastest growing digital '
            'crime, with a 340% rise in complaints in 2023 alone. Most '
            'losses are individually too small for police action but '
            'collectively devastating. SafeBuy Nepal gives buyers a '
            '30-second verification habit and gives honest sellers a '
            'way to prove they are real — a community early-warning '
            'system the authorities themselves have called for.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.65,
            ),
          ),
        ),
        const _Section(
          title: '⚖️ Three Accountability Stages',
          child: Column(children: [
            _NumStep(1, '📉',
                'Community: reports and reviews adjust the public trust score'),
            _NumStep(2, '🪪',
                'Identity: KYC verification ties sellers to real, accountable people'),
            _NumStep(3, '🏛️',
                'Legal: severe cases (50,000+ NPR) are packaged as evidence for the Cyber Bureau'),
          ]),
        ),
        const _Section(
          title: '📜 Policy Recommendations',
          child: Column(children: [
            _Bullet('🧾',
                'Require PAN/business registration before social-commerce selling'),
            _Bullet('🏦',
                'Payment providers should verify recipient identity for merchant QRs'),
            _Bullet('🤝',
                'Platforms should integrate community verification systems like SafeBuy'),
          ]),
        ),
        _Section(
          title: '🎓 Academic Context',
          child: Text(
            'SafeBuy Nepal is a BSc (Hons) Ethical Hacking and '
            'Cybersecurity thesis project developed by Sagesh Adhikari '
            'at Softwarica College of IT and E-Commerce, affiliated '
            'with Coventry University UK (2026).\n\n'
            'Contact: sageshadhikari@gmail.com',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }
}
